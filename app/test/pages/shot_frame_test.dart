import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/camera_move.dart';
import 'package:jingtouben/data/models/prop_drawing.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_prop.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/pages/preview/widgets/shot_frame.dart';
import 'package:jingtouben/resources/theme.dart';

void main() {
  Future<void> pumpFrame(
    WidgetTester tester,
    ShotDraft shot, {
    ThemeData? theme,
    double progress = 0.5,
    Map<String, PropDrawing> propDrawings = const {},
  }) => tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Center(
        child: SizedBox(
          width: 360,
          height: 640,
          child: ShotFrame(
            shot: shot,
            position: 1,
            total: 1,
            progress: progress,
            propDrawings: propDrawings,
          ),
        ),
      ),
    ),
  );

  // 每种场景模板、天气和运镜都画一遍，确认不抛异常、取景提示正常
  const scenes = {
    '雨夜的老街，霓虹灯在积水里晃动': CameraMove.track,
    '公交站台上，她在等车': CameraMove.follow,
    '客厅里灯还亮着': CameraMove.push,
    '深夜的卧室，窗外下着雪': CameraMove.pull,
    '海边的风很大，树被吹弯': CameraMove.pan,
    '她坐在车窗边发呆': CameraMove.crane,
    '深夜的地铁车厢': CameraMove.fixed,
    '手机屏幕上弹出一条消息': CameraMove.fixed,
    '两人对视': CameraMove.fixed,
  };

  for (final MapEntry(key: scene, value: move) in scenes.entries) {
    testWidgets('场景「$scene」可以绘制', (tester) async {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        await pumpFrame(
          tester,
          ShotDraft(
            index: 3,
            shotSize: ShotSize.full,
            scene: scene,
            characters: const ['林夏', '陈默'],
            cameraMove: move,
          ),
          theme: theme,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('完整全身'), findsOneWidget);
        expect(find.text('林夏'), findsOneWidget);
        expect(find.text('陈默'), findsOneWidget);
      }
    });
  }

  testWidgets('没有人物的屏幕镜头画手机；开头是黑场和「镜头 n」', (tester) async {
    await pumpFrame(
      tester,
      const ShotDraft(index: 0, shotSize: ShotSize.closeUp, scene: '手机屏幕上弹出一条消息'),
      progress: 0,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('镜头 1'), findsOneWidget);
    expect(find.text('面部'), findsOneWidget);
  });

  testWidgets('近景以上画五官，大特写只画一个人', (tester) async {
    for (final size in [ShotSize.mediumCloseUp, ShotSize.extremeCloseUp, ShotSize.extremeLong]) {
      await pumpFrame(
        tester,
        ShotDraft(index: 1, shotSize: size, scene: '两人对视', characters: const ['林夏', '陈默']),
      );
      expect(tester.takeException(), isNull, reason: size.label);
    }
  });

  testWidgets('各种姿态、道具和视线在远景到近景都能画', (tester) async {
    const scenes = [
      '林夏坐在长椅上',
      '林夏在雨里走',
      '林夏挥手',
      '林夏转身离开',
      '林夏回头',
      '林夏低头看手机',
      '林夏抬头，雨水顺着伞沿滴落',
      '撑黑伞的人站在街对面，看不清脸',
    ];
    for (final scene in scenes) {
      for (final size in [ShotSize.long, ShotSize.full, ShotSize.medium, ShotSize.closeUp]) {
        for (final name in ['林夏', '陈默']) {
          await pumpFrame(
            tester,
            ShotDraft(index: 2, shotSize: size, scene: scene, characters: [name]),
          );
          expect(tester.takeException(), isNull, reason: '$scene ${size.label} $name');
        }
      }
    }
  });

  testWidgets('生成道具：画好的按握持点和脚边摆放，没画好的画占位方块，各景别和主题都能画', (tester) async {
    final drawings = {
      '吉他': const PropDrawing(
        name: '吉他',
        anchor: PropAnchor.hand,
        size: 0.5,
        grip: Offset(0.5, 0.1),
        shapes: [
          PropEllipse(center: Offset(0.5, 0.75), width: 0.5, height: 0.4, fill: PropFill.light),
          PropPath(points: [Offset(0.5, 0.05), Offset(0.5, 0.6)]),
          PropPath(
            points: [Offset(0.4, 0.8), Offset(0.6, 0.8), Offset(0.5, 0.9)],
            closed: true,
            fill: PropFill.dark,
          ),
          PropArc(center: Offset(0.5, 0.3), radius: 0.1, start: 180, end: 360),
        ],
      ),
      '行李箱': const PropDrawing(
        name: '行李箱',
        anchor: PropAnchor.ground,
        size: 0.45,
        shapes: [
          PropPath(
            points: [Offset(0.1, 0.3), Offset(0.9, 0.3), Offset(0.9, 1), Offset(0.1, 1)],
            closed: true,
            fill: PropFill.accent,
          ),
          PropEllipse(center: Offset(0.3, 0.95), width: 0.1, height: 0.1, fill: PropFill.mid),
        ],
      ),
    };
    const props = [
      ShotProp(name: '黑伞', owner: '陈默'),
      ShotProp(name: '吉他', owner: '林夏'),
      ShotProp(name: '行李箱', owner: '林夏'),
      ShotProp(name: '猫'),
      ShotProp(name: '花束', owner: '陈默'),
    ];
    for (final size in [ShotSize.long, ShotSize.full, ShotSize.medium, ShotSize.closeUp]) {
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        await pumpFrame(
          tester,
          ShotDraft(
            index: 4,
            shotSize: size,
            scene: '雨夜的站台，林夏挥手',
            characters: const ['林夏', '陈默'],
            shotProps: props,
          ),
          theme: theme,
          propDrawings: drawings,
        );
        expect(tester.takeException(), isNull, reason: size.label);
      }
    }
    // 没有人物、道具都没画好时只画场景里的占位
    await pumpFrame(
      tester,
      const ShotDraft(
        index: 5,
        shotSize: ShotSize.full,
        scene: '空荡的站台',
        shotProps: [ShotProp(name: '猫')],
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
