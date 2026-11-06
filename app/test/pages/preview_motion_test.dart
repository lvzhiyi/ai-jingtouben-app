import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/camera_move.dart';
import 'package:jingtouben/data/models/shot_size.dart';
import 'package:jingtouben/pages/preview/preview_motion.dart';

void main() {
  group('framingFor', () {
    test('景别越近，人物在画框里越大', () {
      final heights = [for (final size in ShotSize.values) framingFor(size).figureHeight];
      for (var i = 1; i < heights.length; i++) {
        expect(heights[i], greaterThan(heights[i - 1]), reason: ShotSize.values[i].label);
      }
    });

    test('远景到全景能看到全身，中景截到腰，近景截到胸', () {
      for (final size in [ShotSize.extremeLong, ShotSize.long, ShotSize.full]) {
        expect(framingFor(size).visibleBodyRatio, greaterThanOrEqualTo(1), reason: size.label);
      }
      expect(framingFor(ShotSize.medium).visibleBodyRatio, closeTo(0.6, 0.1));
      expect(framingFor(ShotSize.mediumCloseUp).visibleBodyRatio, closeTo(0.37, 0.1));
    });

    test('特写脸宽接近画框宽，大特写脸比画框还大', () {
      const frameWidth = 9 / 16;
      expect(framingFor(ShotSize.closeUp).headDiameter / frameWidth, closeTo(0.9, 0.05));
      expect(framingFor(ShotSize.extremeCloseUp).headDiameter, greaterThan(1));
      expect(showsSingleFigure(ShotSize.closeUp), isTrue);
      expect(showsSingleFigure(ShotSize.medium), isFalse);
    });
  });

  group('cameraTransform', () {
    test('固定不动；推从 1 放大到 1.25，拉反过来', () {
      expect(cameraTransform(CameraMove.fixed, 0.5).scale, 1);
      expect(cameraTransform(CameraMove.push, 0).scale, 1);
      expect(cameraTransform(CameraMove.push, 1).scale, 1.25);
      expect(cameraTransform(CameraMove.pull, 0).scale, 1.25);
      expect(cameraTransform(CameraMove.pull, 1).scale, 1);
    });

    test('摇整体横移，升降整体竖移，人物和背景一起动', () {
      final panStart = cameraTransform(CameraMove.pan, 0);
      final panEnd = cameraTransform(CameraMove.pan, 1);
      expect(panStart.offset.dx, 0.15);
      expect(panEnd.offset.dx, -0.15);
      expect(panEnd.backgroundOffset, 0);
      expect(cameraTransform(CameraMove.crane, 0).offset, const Offset(0, -0.1));
      expect(cameraTransform(CameraMove.crane, 1).offset, const Offset(0, 0.1));
    });

    test('移和跟：人物不动，只有背景反向平移；跟还有走路起伏', () {
      for (final move in [CameraMove.track, CameraMove.follow]) {
        final start = cameraTransform(move, 0);
        final end = cameraTransform(move, 1);
        expect(start.offset, Offset.zero, reason: move.label);
        expect(start.backgroundOffset, greaterThan(0), reason: move.label);
        expect(end.backgroundOffset, lessThan(0), reason: move.label);
      }
      expect(cameraTransform(CameraMove.track, 0.25).figureBob, 0);
      expect(cameraTransform(CameraMove.follow, 0.25).figureBob, greaterThan(0));
    });

    test('进度超出 0–1 时按端点处理，中途有缓动', () {
      expect(cameraTransform(CameraMove.push, 2).scale, 1.25);
      expect(cameraTransform(CameraMove.push, -1).scale, 1);
      // easeInOut 在 0.25 处落后于线性
      expect(cameraTransform(CameraMove.push, 0.25).scale, lessThan(1.0625));
    });
  });

  group('visibleSubtitleChars', () {
    test('逐字出现，镜头结束前 0.5 秒已完整', () {
      expect(visibleSubtitleChars(elapsedMs: 0, durationMs: 3000, length: 5), 0);
      expect(visibleSubtitleChars(elapsedMs: 1250, durationMs: 3000, length: 5), 3);
      expect(visibleSubtitleChars(elapsedMs: 2500, durationMs: 3000, length: 5), 5);
      expect(visibleSubtitleChars(elapsedMs: 2999, durationMs: 3000, length: 5), 5);
    });

    test('没有对白或镜头短于 0.5 秒时直接完整', () {
      expect(visibleSubtitleChars(elapsedMs: 100, durationMs: 3000, length: 0), 0);
      expect(visibleSubtitleChars(elapsedMs: 0, durationMs: 400, length: 4), 4);
    });
  });

  test('角色颜色落在 8 个色相档上，mock 里同框的两个人颜色不同', () {
    final hues = {
      for (final name in ['林夏', '陈默']) HSLColor.fromColor(characterColor(name, dark: false)).hue,
    };
    expect(hues, hasLength(2));
    // 颜色经过 RGB 取整，色相会有零点几度的误差，按到最近档位的距离判断
    for (final hue in hues) {
      final offset = hue % 45;
      expect(offset < 1 || offset > 44, isTrue, reason: '$hue');
    }
  });

  test('角色颜色按名字稳定，不同名字通常不同', () {
    expect(characterColor('林夏', dark: false), characterColor('林夏', dark: false));
    expect(characterColor('林夏', dark: false), isNot(characterColor('陈默', dark: false)));
    expect(characterColor('林夏', dark: true), isNot(characterColor('林夏', dark: false)));
  });

  test('播放时间格式为 m:ss', () {
    expect(formatPlaybackTime(0), '0:00');
    expect(formatPlaybackTime(8999), '0:08');
    expect(formatPlaybackTime(75000), '1:15');
  });
}
