import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/camera_move.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/data/models/video_platform.dart';
import 'package:jingtouben/pages/storyboard/widgets/shot_card.dart';
import 'package:jingtouben/resources/theme.dart';

void main() {
  testWidgets('镜头卡片展示景别、画面、台词和拍摄理由', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ShotCard(
            shot: ShotDraft(
              index: 0,
              shotSize: ShotSize.closeUp,
              scene: '林夏回头',
              dialogue: '是你？',
              reason: '放大情绪',
            ),
          ),
        ),
      ),
    );

    expect(find.text('#1'), findsOneWidget);
    expect(find.text('特写'), findsOneWidget);
    expect(find.text('林夏回头'), findsOneWidget);
    expect(find.text('「是你？」'), findsOneWidget);
    expect(find.text('放大情绪'), findsOneWidget);
    expect(find.text('固定 · 约 2.0 秒'), findsOneWidget);
  });

  testWidgets('有存储时长时显示运镜和准确时长', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: ShotCard(
            shot: ShotDraft(
              index: 0,
              shotSize: ShotSize.long,
              scene: '街口',
              cameraMove: CameraMove.crane,
              durationMs: 3500,
            ),
          ),
        ),
      ),
    );

    expect(find.text('升降 · 3.5 秒'), findsOneWidget);
  });
  testWidgets('切换平台查看提示词，点击复制后写入剪贴板', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      }
      return null;
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: ShotCard(
              shot: ShotDraft(index: 0, shotSize: ShotSize.closeUp, scene: '林夏回头'),
              prompts: {VideoPlatform.jimeng: '即梦写法', VideoPlatform.kling: '可灵写法'},
            ),
          ),
        ),
      ),
    );

    expect(find.text('即梦写法'), findsOneWidget);
    await tester.tap(find.text('可灵'));
    await tester.pump();
    expect(find.text('可灵写法'), findsOneWidget);

    await tester.tap(find.byTooltip('复制可灵提示词'));
    await tester.pump();
    expect(copied, '可灵写法');
    expect(find.text('已复制可灵提示词'), findsOneWidget);
  });
}
