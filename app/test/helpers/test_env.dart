import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jingtouben/data/db/app_database.dart';
import 'package:jingtouben/data/prompt/template_repository.dart';
import 'package:jingtouben/data/repositories/character_repository.dart';
import 'package:jingtouben/data/repositories/progress_repository.dart';
import 'package:jingtouben/data/repositories/project_repository.dart';
import 'package:jingtouben/data/repositories/shot_repository.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';

/// 测试用的最小模板，两个平台写法不同，便于断言。
const testTemplates = '''
{"version": 1, "templates": [
  {"platform": "jimeng", "version": 1, "shot": "{shotSize}，{scene}[。人物：{characters}]", "character": "{name}[，穿{outfit}]"},
  {"platform": "kling", "version": 1, "shot": "{scene}，{shotSize}", "character": "{name}"}
]}
''';

/// 内存数据库 + 各仓库，组件测试和控制器测试共用。
class TestEnv {
  TestEnv._(this.db, this.api)
    : projects = ProjectRepository(db),
      shots = ShotRepository(db),
      progress = ProgressRepository(db),
      characters = CharacterRepository(db),
      templates = TemplateRepository(
        // 服务端不可用，走内置模板
        client: MockClient((_) async => http.Response('', 503)),
        baseUrl: Uri.parse('http://localhost:3000/'),
        database: db,
        loadBundled: () async => testTemplates,
      );

  factory TestEnv({required StoryboardApi api}) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    return TestEnv._(AppDatabase(NativeDatabase.memory()), api);
  }

  final AppDatabase db;
  final StoryboardApi api;
  final ProjectRepository projects;
  final ShotRepository shots;
  final ProgressRepository progress;
  final CharacterRepository characters;
  final TemplateRepository templates;

  /// 和 JingtoubenApp 注入的仓库一致。
  Widget provide(Widget child) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: projects),
      RepositoryProvider.value(value: shots),
      RepositoryProvider.value(value: progress),
      RepositoryProvider.value(value: characters),
      RepositoryProvider.value(value: api),
      RepositoryProvider.value(value: templates),
    ],
    child: child,
  );

  /// 测试结束前卸载组件树、取消 drift 订阅；否则 drift 的流查询会留下未完成的计时器。
  /// 数据库在 tearDown 里关闭。
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // 走完故事自动保存的等待计时器
    await tester.pump(const Duration(seconds: 1));
  }
}

/// drift 的查询走真实异步，测试的假时钟推不动它：交替让出真实时间和推进帧，直到 [finder] 出现。
///
/// 找到后再推进一段时间，让页面转场动画播完，否则按钮可能还在屏幕外，点击不中。
Future<void> pumpUntilFound(WidgetTester tester, Finder finder, {int maxTries = 100}) async {
  for (var i = 0; i < maxTries; i++) {
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  throw TestFailure('等待超时，没有找到：$finder');
}
