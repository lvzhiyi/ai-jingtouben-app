import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jingtouben/app.dart';
import 'package:jingtouben/bootstrap/app_dependencies.dart';
import 'package:jingtouben/data/db/app_database.dart';

/// 性能基线：在真实页面上回放一次固定的流式生成，记录帧耗时。
///
/// 输入固定（20 个镜头、固定随机种子切块、每 25 ms 一个增量，和 server 的模拟数据节奏一致），
/// 不依赖网络和模型，优化前后可以直接对比。必须在真机或模拟器上用 profile 模式跑：
///
/// ```bash
/// flutter drive --profile --driver=test_driver/perf_driver.dart \
///   --target=integration_test/storyboard_perf_test.dart
/// ```
///
/// 结果写到 `build/storyboard_perf.json`。内存用进程 RSS（`ProcessInfo.currentRss`）：
/// 生成前、生成中每 100 ms 采样取峰值、生成后、滑动后各记一次，单位 MB。
const _shotCount = 20;
const _deltaInterval = Duration(milliseconds: 25);
const _projectTitle = '性能基线';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // 由引擎按 vsync 出帧，和用户实际看到的一致，而不是测试手动 pump。
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('流式生成 $_shotCount 个镜头并滚动列表', (tester) async {
    final dependencies = await AppDependencies.initialize(
      database: AppDatabase(NativeDatabase.memory()),
      httpClient: _ReplayClient.create(),
    );
    final projectId = await dependencies.projects.create(_projectTitle);
    await dependencies.projects.updateStory(projectId, '雨夜，林夏在老街等一个不会来的人。');

    await tester.pumpWidget(JingtoubenApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_projectTitle));
    await tester.pumpAndSettle();

    final memory = _MemorySampler()..sample('before_generate');
    await binding.watchPerformance(() async {
      await tester.tap(find.text('生成分镜'));
      final deadline = DateTime.now().add(const Duration(minutes: 1));
      while (find.textContaining('共 $_shotCount 个镜头').evaluate().isEmpty) {
        if (DateTime.now().isAfter(deadline)) fail('生成没有在 1 分钟内完成');
        memory.samplePeak();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }, reportKey: 'storyboard_streaming');
    memory.sample('after_generate');

    final scrollable = find.byType(CustomScrollView);
    await binding.watchPerformance(() async {
      for (var i = 0; i < 2; i++) {
        await tester.fling(scrollable, const Offset(0, -2000), 3000);
        await tester.pumpAndSettle();
        await tester.fling(scrollable, const Offset(0, 2000), 3000);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'shot_list_scroll');
    memory.sample('after_scroll');
    binding.reportData = {...?binding.reportData, 'memory_rss_mb': memory.toJson()};

    // 先卸载组件树，JingtoubenApp 在 dispose 里关闭数据库和网络客户端。
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// 进程常驻内存（RSS）采样。RSS 包含引擎、图片缓存和 Dart 堆，和系统看到的占用一致；
/// 只看生成前后的差值和峰值，绝对值随设备不同。
class _MemorySampler {
  final _points = <String, double>{};
  var _peak = 0;

  static double _mb(int bytes) => (bytes / 1024 / 1024 * 10).roundToDouble() / 10;

  void sample(String name) => _points[name] = _mb(ProcessInfo.currentRss);

  void samplePeak() => _peak = max(_peak, ProcessInfo.currentRss);

  Map<String, double> toJson() => {
    ..._points,
    'peak_during_generate': _mb(_peak),
    'max_rss_since_start': _mb(ProcessInfo.maxRss),
  };
}

/// 只响应流式分镜接口，按固定节奏回放 SSE；其他请求（如模板下发）返回 404，走内置模板。
class _ReplayClient {
  static http.Client create() => MockClient.streaming((request, _) async {
    if (!request.url.path.endsWith('storyboard/stream')) {
      return http.StreamedResponse(const Stream.empty(), 404);
    }
    return http.StreamedResponse(_events().map(utf8.encode), 200);
  });

  static Stream<String> _events() async* {
    final random = Random(42);
    final text = _modelOutput();
    for (var i = 0; i < text.length;) {
      final size = 2 + random.nextInt(6);
      final end = min(i + size, text.length);
      yield 'event: delta\ndata: ${jsonEncode({'text': text.substring(i, end)})}\n\n';
      i = end;
      await Future<void>.delayed(_deltaInterval);
    }
    yield 'event: done\ndata: {}\n\n';
  }

  static String _modelOutput() {
    const sizes = ['全景', '中景', '特写', '近景', '远景'];
    return [
      for (var i = 0; i < _shotCount; i++)
        jsonEncode({
          'shotSize': sizes[i % sizes.length],
          'scene': '第${i + 1}幕：雨夜的老街，霓虹灯在积水里晃动，林夏撑着伞站在公交站台，望向街对面',
          'dialogue': i.isEven ? '' : '……是你吗？',
          'reason': '用${sizes[i % sizes.length]}交代人物处境，把注意力收到她的动作和情绪上',
          'characters': ['林夏'],
        }),
    ].join('\n');
  }
}
