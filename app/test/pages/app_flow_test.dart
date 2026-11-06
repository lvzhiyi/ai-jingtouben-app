import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';
import 'package:jingtouben/resources/theme.dart';
import 'package:jingtouben/router/app_router.dart';

import '../helpers/test_env.dart';

class _UnusedApi implements StoryboardApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv(api: _UnusedApi()));

  tearDown(() => env.db.close());

  testWidgets('新建短剧 → 进入分镜页 → 新建角色卡 → 返回后列表展示故事', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      env.provide(MaterialApp.router(theme: AppTheme.light(), routerConfig: router)),
    );
    await pumpUntilFound(tester, find.text('第一幕，等你落笔'));

    // 新建短剧，标题留空时用默认名
    await tester.tap(find.text('新建短剧'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('创建'));
    await pumpUntilFound(tester, find.text('故事的起点'));
    expect(find.widgetWithText(AppBar, '未命名短剧'), findsOneWidget);

    // 进入角色卡，新建一个角色
    await tester.tap(find.byTooltip('角色卡'));
    await pumpUntilFound(tester, find.text('还没有角色'));
    await tester.tap(find.text('新建角色'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '角色名'), '初恋');
    await tester.enterText(find.widgetWithText(TextField, '服装'), '米色风衣');
    await tester.tap(find.text('保存'));
    await pumpUntilFound(tester, find.text('穿着：米色风衣'));
    expect(find.text('外貌未填写'), findsOneWidget);

    // 删除需要确认
    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除「初恋」？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('初恋'), findsOneWidget);

    // 进度板：还没生成分镜时提示先去生成
    await tester.pageBack();
    await pumpUntilFound(tester, find.text('故事的起点'));
    await tester.tap(find.byTooltip('镜头进度板'));
    await pumpUntilFound(tester, find.text('还没有分镜'));

    // 回到分镜页写故事，不生成直接返回首页：离开页面时故事已保存，列表里能看到摘要
    await tester.pageBack();
    await pumpUntilFound(tester, find.text('故事的起点'));
    await tester.enterText(find.byType(TextField), '雨夜，林夏在老街等一个不会来的人。');
    await tester.pump();
    await tester.pageBack();
    await pumpUntilFound(tester, find.text('雨夜，林夏在老街等一个不会来的人。'));
    expect(find.text('继续创作 →'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('分镜页点「从这里预演」进入预演页并从该镜头开始，顶栏入口从第一镜开始', (tester) async {
    late String projectId;
    await tester.runAsync(() async {
      projectId = await env.projects.create('雨夜重逢');
      await env.projects.updateStory(projectId, '雨夜，林夏在老街等一个不会来的人。');
      await env.shots.replaceAll(projectId, const [
        ShotDraft(index: 0, shotSize: ShotSize.full, scene: '老街'),
        ShotDraft(index: 1, shotSize: ShotSize.closeUp, scene: '回头'),
      ]);
    });
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = createRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      env.provide(MaterialApp.router(theme: AppTheme.light(), routerConfig: router)),
    );
    await pumpUntilFound(tester, find.text('继续创作 →'));
    unawaited(router.push('/projects/$projectId'));
    await pumpUntilFound(tester, find.text('从这里预演'));

    await tester.tap(find.text('从这里预演').last);
    await pumpUntilFound(tester, find.text('镜头 2 / 2 · 特写 · 固定'));

    await tester.pageBack();
    await pumpUntilFound(tester, find.byTooltip('镜头预演'));
    await tester.tap(find.byTooltip('镜头预演'));
    await pumpUntilFound(tester, find.textContaining('镜头 1 / 2'));

    await env.unmount(tester);
  });
}
