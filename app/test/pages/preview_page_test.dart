import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/camera_move.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_prop.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/storyboard/storyboard_api.dart';
import 'package:jingtouben/pages/preview/page.dart';
import 'package:jingtouben/pages/preview/widgets/shot_frame.dart';
import 'package:jingtouben/resources/theme.dart';

import '../helpers/test_env.dart';

class _UnusedApi implements StoryboardApi {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TestEnv env;
  late String projectId;

  setUp(() async {
    env = TestEnv(api: _UnusedApi());
    projectId = await env.projects.create('雨夜重逢');
  });

  tearDown(() => env.db.close());

  Future<void> seed() => env.shots.replaceAll(projectId, const [
    ShotDraft(
      index: 0,
      shotSize: ShotSize.full,
      scene: '雨夜的老街',
      characters: ['林夏'],
      cameraMove: CameraMove.push,
      durationMs: 2000,
    ),
    ShotDraft(
      index: 1,
      shotSize: ShotSize.closeUp,
      scene: '林夏回头',
      dialogue: '是你吗',
      characters: ['林夏'],
      durationMs: 3000,
    ),
    ShotDraft(index: 2, shotSize: ShotSize.long, scene: '街对面的男人', cameraMove: CameraMove.follow),
  ]);

  Future<void> pumpPreview(WidgetTester tester, {int? startShot, ThemeData? theme}) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      env.provide(
        MaterialApp(
          theme: theme ?? AppTheme.light(),
          home: PreviewPage(projectId: projectId, startShot: startShot),
        ),
      ),
    );
  }

  Finder subtitle() => find.byKey(const ValueKey('preview-subtitle'));

  testWidgets('按时长自动播放：换镜、字幕在结束前完整、播完停在最后一帧可重播', (tester) async {
    await tester.runAsync(seed);
    await pumpPreview(tester);
    // pumpUntilFound 找到后会再推进 0.5 秒
    await pumpUntilFound(tester, find.text('镜头 1 / 3 · 全景 · 推'));
    expect(find.text('雨夜的老街'), findsOneWidget);
    expect(subtitle(), findsNothing);
    // 景别小图的说明；开头的「镜头 1」小标在 0.9 秒后消失
    expect(find.text('完整全身'), findsOneWidget);
    // 人物下方标角色名
    expect(find.text('林夏'), findsOneWidget);
    expect(find.text('镜头 1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('镜头 1'), findsNothing);
    expect(find.byTooltip('暂停'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();
    expect(find.text('镜头 2 / 3 · 特写 · 固定'), findsOneWidget);
    expect(find.text('面部'), findsOneWidget);
    // 还没出字时不显示字幕
    expect(subtitle(), findsNothing);

    await tester.pump(const Duration(milliseconds: 1000));
    final partial = tester.widget<Text>(subtitle()).data!;
    expect(partial.length, lessThan(3));

    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.widget<Text>(subtitle()).data, '是你吗');
    expect(find.text('镜头 2 / 3 · 特写 · 固定'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('镜头 3 / 3 · 远景 · 跟'), findsOneWidget);

    // 远景无对白默认 3 秒
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump();
    expect(find.byTooltip('重播'), findsOneWidget);
    expect(find.text('0:08 / 0:08'), findsOneWidget);
    expect(find.text('镜头 3 / 3 · 远景 · 跟'), findsOneWidget);

    await tester.tap(find.byTooltip('重播'));
    await tester.pump();
    expect(find.text('镜头 1 / 3 · 全景 · 推'), findsOneWidget);
    expect(find.byTooltip('暂停'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('点进度条跳镜；暂停后不再前进；上一镜 / 下一镜', (tester) async {
    await tester.runAsync(seed);
    await pumpPreview(tester);
    await pumpUntilFound(tester, find.text('镜头 1 / 3 · 全景 · 推'));

    await tester.tap(find.byKey(const ValueKey('preview-segment-2')));
    await tester.pump();
    expect(find.text('镜头 3 / 3 · 远景 · 跟'), findsOneWidget);

    await tester.tap(find.byTooltip('暂停'));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('镜头 3 / 3 · 远景 · 跟'), findsOneWidget);
    expect(find.byTooltip('播放'), findsOneWidget);

    await tester.tap(find.byTooltip('上一镜'));
    await tester.pump();
    expect(find.text('镜头 2 / 3 · 特写 · 固定'), findsOneWidget);
    await tester.tap(find.byTooltip('下一镜'));
    await tester.pump();
    expect(find.text('镜头 3 / 3 · 远景 · 跟'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('从指定镜头开始；可隐藏画面描述；深色主题也能画', (tester) async {
    await tester.runAsync(seed);
    await pumpPreview(tester, startShot: 1, theme: AppTheme.dark());
    await pumpUntilFound(tester, find.text('镜头 2 / 3 · 特写 · 固定'));
    expect(find.text('林夏回头'), findsOneWidget);

    await tester.tap(find.byTooltip('隐藏画面描述'));
    await tester.pump();
    expect(find.text('林夏回头'), findsNothing);
    expect(find.byTooltip('显示画面描述'), findsOneWidget);

    await env.unmount(tester);
  });

  testWidgets('没有镜头时提示先去生成', (tester) async {
    await pumpPreview(tester);
    await pumpUntilFound(tester, find.text('还没有镜头，先回分镜页生成'));
    await env.unmount(tester);
  });

  testWidgets('长按画面列出本镜道具和状态，可以重画；没有生成道具时提示', (tester) async {
    await tester.runAsync(
      () => env.shots.replaceAll(projectId, const [
        ShotDraft(
          index: 0,
          shotSize: ShotSize.full,
          scene: '站台',
          characters: ['林夏'],
          durationMs: 10000,
          shotProps: [
            ShotProp(name: '伞', owner: '林夏'),
            ShotProp(name: '行李箱', owner: '林夏'),
          ],
        ),
        ShotDraft(index: 1, shotSize: ShotSize.full, scene: '街口', durationMs: 2000, shotProps: []),
      ]),
    );
    await pumpPreview(tester);
    await pumpUntilFound(tester, find.text('镜头 1 / 2 · 全景 · 固定'));

    // 测试环境的绘图服务不可用：生成失败后状态变成「生成失败」
    await tester.longPress(find.byType(ShotFrame));
    await pumpUntilFound(tester, find.text('本镜道具'));
    expect(find.text('行李箱'), findsOneWidget);
    expect(find.text('伞'), findsNothing, reason: '内置道具不列出');
    await tester.tap(find.text('重画'));
    await pumpUntilFound(tester, find.text('正在重画「行李箱」'));

    // 提示条盖住了底部的播放控制，等它收起
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('下一镜'));
    await pumpUntilFound(tester, find.text('镜头 2 / 2 · 全景 · 固定'));
    await tester.longPress(find.byType(ShotFrame));
    await pumpUntilFound(tester, find.text('这个镜头没有可重画的道具'));
    await env.unmount(tester);
  });
}
