import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';
import 'package:jingtouben/pages/progress/page.dart';
import 'package:jingtouben/pages/progress/widgets/generation_time.dart';
import 'package:jingtouben/resources/theme.dart';

import '../helpers/test_env.dart';

class _UnusedApi implements StoryboardApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 对话框退场动画的时长，走完后页面上不再有对话框里的文字。
const dialogClosed = Duration(milliseconds: 500);

void main() {
  late TestEnv env;
  late String projectId;
  String? clipboard;

  setUp(() async {
    env = TestEnv(api: _UnusedApi());
    projectId = await env.projects.create('雨夜重逢');
  });

  tearDown(() => env.db.close());

  Future<void> pumpPage(WidgetTester tester, {List<ShotDraft> shots = const []}) async {
    if (shots.isNotEmpty) await tester.runAsync(() => env.shots.replaceAll(projectId, shots));
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    clipboard = null;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        clipboard = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      env.provide(
        MaterialApp(
          theme: AppTheme.light(),
          home: ProgressPage(projectId: projectId),
        ),
      ),
    );
  }

  testWidgets('没有分镜时提示先去生成', (tester) async {
    await pumpPage(tester);
    await pumpUntilFound(tester, find.text('还没有分镜'));
    await env.unmount(tester);
  });

  testWidgets('记一次生成、选定、改备注、删除，状态和统计随之变化', (tester) async {
    await pumpPage(
      tester,
      shots: const [
        ShotDraft(index: 0, shotSize: ShotSize.full, scene: '雨夜的老街'),
        ShotDraft(index: 1, shotSize: ShotSize.closeUp, scene: '她的眼睛'),
      ],
    );
    await pumpUntilFound(tester, find.text('0 / 2'));
    expect(find.text('待生成 2'), findsOneWidget);

    // 记录：切到可灵，复制提示词，写备注
    await tester.tap(find.text('记一次生成').first);
    await pumpUntilFound(tester, find.text('镜头 #1 · 记一次生成'));
    expect(find.text('全景，雨夜的老街'), findsOneWidget);
    await tester.tap(find.text('可灵'));
    await tester.pump();
    expect(find.text('雨夜的老街，全景'), findsOneWidget);
    await tester.tap(find.text('复制可灵提示词'));
    await tester.pump();
    expect(clipboard, '雨夜的老街，全景');
    expect(find.text('已复制'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '雨丝太粗');
    await tester.tap(find.text('记下'));
    await tester.pump(dialogClosed);
    await pumpUntilFound(tester, find.text('雨丝太粗'));
    expect(find.text('生成中 1'), findsOneWidget);
    expect(find.text('再抽一次'), findsOneWidget);

    // 选定
    await tester.tap(find.byTooltip('选定第 1 次'));
    await pumpUntilFound(tester, find.text('1 / 2'));
    expect(find.text('已选定 1'), findsOneWidget);
    expect(find.byTooltip('取消选定第 1 次'), findsOneWidget);

    // 筛选只看待生成
    await tester.tap(find.text('待生成 1'));
    await tester.pump();
    expect(find.text('她的眼睛'), findsOneWidget);
    expect(find.text('雨夜的老街'), findsNothing);
    await tester.tap(find.text('全部 2'));
    await tester.pump();

    // 打开详情：看快照、改备注
    await tester.tap(find.text('雨丝太粗'));
    await pumpUntilFound(tester, find.text('当时的提示词'));
    expect(find.text('雨夜的老街，全景'), findsOneWidget);
    await tester.tap(find.text('复制提示词'));
    await tester.pump();
    expect(clipboard, '雨夜的老街，全景');
    await tester.enterText(find.byType(TextField), '就用这条');
    await tester.tap(find.text('保存'));
    await tester.pump(dialogClosed);
    await pumpUntilFound(tester, find.text('就用这条'));

    // 删除后回到待生成
    await tester.tap(find.text('就用这条'));
    await pumpUntilFound(tester, find.text('删除记录'));
    await tester.tap(find.text('删除记录'));
    await tester.pump(dialogClosed);
    await pumpUntilFound(tester, find.text('0 / 2'));
    expect(find.text('待生成 2'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('筛选结果为空时提示', (tester) async {
    await pumpPage(
      tester,
      shots: const [ShotDraft(index: 0, shotSize: ShotSize.full, scene: '雨夜的老街')],
    );
    await pumpUntilFound(tester, find.text('已选定 0'));
    await tester.tap(find.text('已选定 0'));
    await tester.pump();
    expect(find.text('没有「已选定」的镜头'), findsOneWidget);
    // 再点一次回到全部
    await tester.tap(find.text('已选定 0'));
    await tester.pump();
    expect(find.text('雨夜的老街'), findsOneWidget);

    await env.unmount(tester);
  });

  test('生成时间按本地时区显示成月/日 时:分', () {
    expect(formatGenerationTime(DateTime(2026, 11, 6, 9, 5)), '11/6 09:05');
  });
}
