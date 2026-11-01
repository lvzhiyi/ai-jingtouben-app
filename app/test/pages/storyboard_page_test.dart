import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/character_profile.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/storyboard/shot_line_parser.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';
import 'package:jingtouben/net/api_exception.dart';
import 'package:jingtouben/pages/storyboard/page.dart';
import 'package:jingtouben/resources/theme.dart';

import '../helpers/test_env.dart';

/// 每次生成都交出一个新的 StreamController，测试按步骤往里推更新。
class _ScriptedApi implements StoryboardApi {
  final calls = <StreamController<GenerationUpdate>>[];

  @override
  Stream<GenerationUpdate> generate({
    required String story,
    List<CharacterProfile> characters = const [],
  }) {
    final controller = StreamController<GenerationUpdate>();
    calls.add(controller);
    return controller.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _ScriptedApi api;
  late TestEnv env;
  late String projectId;

  // 数据库在 setUp 里（真实异步）打开并写好数据；在 testWidgets 的假时钟里首次打开会卡住。
  setUp(() async {
    api = _ScriptedApi();
    env = TestEnv(api: api);
    projectId = await env.projects.create('雨夜重逢');
  });

  tearDown(() => env.db.close());

  Future<void> pumpPage(WidgetTester tester, {String story = ''}) async {
    if (story.isNotEmpty) await tester.runAsync(() => env.projects.updateStory(projectId, story));
    // 高一点的画布，生成结果不用滚动就能看到
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      env.provide(
        MaterialApp(
          theme: AppTheme.light(),
          home: StoryboardPage(projectId: projectId),
        ),
      ),
    );
    await pumpUntilFound(tester, find.text('雨夜重逢'));
  }

  testWidgets('故事太短时不能生成，写够字数后可以生成', (tester) async {
    await pumpPage(tester);
    expect(find.text('故事至少 10 个字'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '雨夜，林夏在老街等一个不会来的人。');
    await tester.pump();
    expect(find.text('写好故事后点击生成'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('流式生成：半成品镜头边写边显示，坏行留在原位，完成后显示总数和首字延迟', (tester) async {
    await pumpPage(tester, story: '雨夜，林夏在老街等一个不会来的人。');
    await tester.tap(find.text('生成分镜'));
    await pumpUntilFound(tester, find.text('正在连接…'));
    final stream = api.calls.single;

    stream
      ..add(const FirstTokenArrived(Duration(milliseconds: 420)))
      ..add(const ShotDrafting(PartialShot(index: 0, shotSize: ShotSize.full, scene: '雨夜的老')));
    await pumpUntilFound(tester, find.text('正在写…'));
    expect(find.text('雨夜的老'), findsOneWidget);
    expect(find.text('停止'), findsOneWidget);

    stream
      ..add(
        const ShotLineArrived(
          ParsedShot(ShotDraft(index: 0, shotSize: ShotSize.full, scene: '雨夜的老街')),
        ),
      )
      ..add(const ShotLineArrived(BrokenShot(index: 1, raw: '{"scene":', reason: 'JSON 格式错误')))
      ..add(const GenerationCompleted());
    await pumpUntilFound(tester, find.text('共 2 个镜头 · 首字 420 ms'));

    expect(find.text('正在写…'), findsNothing);
    expect(find.text('雨夜的老街'), findsOneWidget);
    expect(find.text('#2 需要重新生成（JSON 格式错误）'), findsOneWidget);
    expect(find.text('重新生成'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('生成失败时提示错误原因', (tester) async {
    await pumpPage(tester, story: '雨夜，林夏在老街等一个不会来的人。');
    await tester.tap(find.text('生成分镜'));
    await pumpUntilFound(tester, find.text('正在连接…'));

    api.calls.single.addError(const ApiException(ApiErrorKind.rateLimited, statusCode: 429));
    await pumpUntilFound(tester, find.text('生成失败：请求太频繁，请稍等一分钟再试'));
    expect(find.widgetWithText(SnackBar, '请求太频繁，请稍等一分钟再试'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('生成中点停止，保留已收到的镜头数', (tester) async {
    await pumpPage(tester, story: '雨夜，林夏在老街等一个不会来的人。');
    await tester.tap(find.text('生成分镜'));
    await pumpUntilFound(tester, find.text('正在连接…'));
    api.calls.single
      ..add(const FirstTokenArrived(Duration(milliseconds: 300)))
      ..add(
        const ShotLineArrived(
          ParsedShot(ShotDraft(index: 0, shotSize: ShotSize.full, scene: '街口')),
        ),
      );
    await pumpUntilFound(tester, find.text('街口'));

    await tester.tap(find.text('停止'));
    await pumpUntilFound(tester, find.text('已停止，收到 1 个镜头'));

    await env.unmount(tester);
  });
}
