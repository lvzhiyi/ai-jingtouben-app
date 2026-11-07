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

  group('分层摄影机', () {
    LayerView at(CameraMove move, double t, double depth, {bool subject = false}) =>
        layerView(cameraTransform(move, t), depth, subject: subject);

    test('固定不动：每层都不缩放不平移', () {
      for (final depth in [
        SceneDepth.sky,
        SceneDepth.far,
        SceneDepth.subject,
        SceneDepth.foreground,
      ]) {
        final view = at(CameraMove.fixed, 0.5, depth);
        expect(view.scale, 1);
        expect(view.shift, Offset.zero);
      }
    });

    test('推是机位前进：人物放大到 1.6 倍，前景放大得更多，远景几乎不变；拉反过来', () {
      expect(at(CameraMove.push, 0, SceneDepth.subject).scale, 1);
      expect(at(CameraMove.push, 1, SceneDepth.subject).scale, closeTo(1.6, 1e-9));
      expect(at(CameraMove.push, 1, SceneDepth.foreground).scale, greaterThan(3));
      expect(at(CameraMove.push, 1, SceneDepth.far).scale, lessThan(1.15));
      expect(at(CameraMove.push, 1, SceneDepth.sky).scale, lessThan(1.02));
      expect(at(CameraMove.pull, 0, SceneDepth.subject).scale, closeTo(1.6, 1e-9));
      expect(at(CameraMove.pull, 1, SceneDepth.subject).scale, 1);
    });

    test('摇是镜头转向：远近各层平移一样，没有视差', () {
      for (final depth in [
        SceneDepth.sky,
        SceneDepth.far,
        SceneDepth.subject,
        SceneDepth.foreground,
      ]) {
        expect(at(CameraMove.pan, 0, depth).shift.dx, closeTo(0.35, 1e-9));
        expect(at(CameraMove.pan, 1, depth).shift.dx, closeTo(-0.35, 1e-9));
      }
    });

    test('移是机位平移：越近划过得越多，人物从一侧移到另一侧', () {
      double travel(double depth) =>
          at(CameraMove.track, 0, depth).shift.dx - at(CameraMove.track, 1, depth).shift.dx;
      expect(travel(SceneDepth.subject), closeTo(0.6, 1e-9));
      expect(travel(SceneDepth.foreground), greaterThan(travel(SceneDepth.mid)));
      expect(travel(SceneDepth.mid), greaterThan(travel(SceneDepth.far)));
      expect(travel(SceneDepth.far), greaterThan(travel(SceneDepth.sky)));
      expect(at(CameraMove.track, 0, SceneDepth.subject, subject: true).shift.dx, 0.3);
    });

    test('跟：人物在画框里不动，场景按视差后退，带手持晃动和走路起伏', () {
      final start = at(CameraMove.follow, 0, SceneDepth.subject, subject: true);
      final end = at(CameraMove.follow, 1, SceneDepth.subject, subject: true);
      expect((start.shift - end.shift).dx.abs(), lessThan(0.02));
      expect(at(CameraMove.follow, 0, SceneDepth.subject).shift.dx, closeTo(0.6, 0.01));
      expect(at(CameraMove.follow, 1, SceneDepth.far).shift.dx, closeTo(-0.6 / 3.5, 0.01));
      expect(cameraTransform(CameraMove.follow, 0.3).shake, isNot(Offset.zero));
      expect(cameraTransform(CameraMove.follow, 0.25).figureBob, greaterThan(0));
      expect(cameraTransform(CameraMove.track, 0.25).figureBob, 0);
    });

    test('升：近处往下沉得多，地平线和天空往上走', () {
      final ground = at(CameraMove.crane, 1, SceneDepth.foreground).shift.dy;
      final subject = at(CameraMove.crane, 1, SceneDepth.subject).shift.dy;
      final far = at(CameraMove.crane, 1, SceneDepth.far).shift.dy;
      expect(ground, greaterThan(subject));
      expect(subject, closeTo(0.15, 1e-9));
      expect(far, lessThan(0));
      expect(at(CameraMove.crane, 0, SceneDepth.subject).shift, Offset.zero);
    });

    test('LayerView.project：先平移再以中心缩放', () {
      const view = LayerView(scale: 2, shift: Offset(0.1, 0));
      expect(view.project(const Offset(0.5, 0.5)), const Offset(0.7, 0.5));
      expect(view.project(const Offset(0.75, 0.25)), const Offset(1.2, 0));
    });
  });

  group('cameraEase', () {
    test('端点固定，起步慢，停下前略冲过再回正', () {
      expect(cameraEase(0), 0);
      expect(cameraEase(1), closeTo(1, 1e-9));
      expect(cameraEase(-1), 0);
      expect(cameraEase(2), closeTo(1, 1e-9));
      expect(cameraEase(0.1), lessThan(0.05));
      expect(cameraEase(0.88), closeTo(1.015, 1e-9));
      for (var t = 0.0; t < 0.88; t += 0.04) {
        expect(cameraEase(t + 0.04), greaterThanOrEqualTo(cameraEase(t)));
      }
    });
  });

  test('景深：远景不虚；景别越近背景越虚，人物平面始终清楚', () {
    expect(focusBlur(ShotSize.long, SceneDepth.far), 0);
    expect(focusBlur(ShotSize.closeUp, SceneDepth.subject), 0);
    expect(
      focusBlur(ShotSize.closeUp, SceneDepth.far),
      greaterThan(focusBlur(ShotSize.medium, SceneDepth.far)),
    );
    expect(
      focusBlur(ShotSize.medium, SceneDepth.far),
      greaterThan(focusBlur(ShotSize.medium, SceneDepth.mid)),
    );
    expect(focusBlur(ShotSize.medium, SceneDepth.foreground), greaterThan(0));
  });

  test('运镜提示：推拉看取景标记，摇移跟往右，升降往上，固定没有', () {
    expect(cameraHint(CameraMove.fixed).direction, isNull);
    expect(cameraHint(CameraMove.fixed).zoom, 0);
    expect(cameraHint(CameraMove.push).zoom, 1);
    expect(cameraHint(CameraMove.pull).zoom, -1);
    for (final move in [CameraMove.pan, CameraMove.track, CameraMove.follow]) {
      expect(cameraHint(move).direction, const Offset(1, 0), reason: move.label);
    }
    expect(cameraHint(CameraMove.crane).direction, const Offset(0, -1));
  });

  group('framingWindow', () {
    test('中景的取景框下沿在腰（身高约 60%），近景在胸', () {
      expect(framingWindow(framingFor(ShotSize.medium)).bottom, closeTo(0.62, 0.05));
      expect(framingWindow(framingFor(ShotSize.mediumCloseUp)).bottom, closeTo(0.37, 0.05));
    });

    test('全景及更远的取景框包住全身；框的宽高比是 9:16', () {
      for (final size in [ShotSize.extremeLong, ShotSize.long, ShotSize.full]) {
        final window = framingWindow(framingFor(size));
        expect(window.top, lessThanOrEqualTo(0), reason: size.label);
        expect(window.bottom, greaterThanOrEqualTo(1), reason: size.label);
        expect(window.width / window.height, closeTo(9 / 16, 1e-9));
      }
    });

    test('每个景别都有说明', () {
      expect(framingHint(ShotSize.medium), '腰部以上');
      expect({for (final size in ShotSize.values) framingHint(size)}, hasLength(7));
    });
  });

  group('sceneLook', () {
    test('按关键词选场景，越具体的越优先', () {
      expect(sceneLook('雨夜的老街，林夏撑着伞站在公交站台').kind, SceneKind.station);
      expect(sceneLook('街对面，一个撑黑伞的男人停下脚步').kind, SceneKind.street);
      expect(sceneLook('手机屏幕上弹出一条消息').kind, SceneKind.screen);
      expect(sceneLook('她坐在车窗边发呆').kind, SceneKind.vehicle);
      expect(sceneLook('客厅里灯还亮着').kind, SceneKind.indoor);
      expect(sceneLook('海边的风很大').kind, SceneKind.nature);
      expect(sceneLook('两人对视').kind, SceneKind.open);
    });

    test('先去掉角色名再匹配：「林夏」不算树林', () {
      const scene = '林夏抬头，雨水顺着伞沿滴落';
      expect(sceneLook(scene).kind, SceneKind.nature);
      expect(sceneLook(scene, ignore: ['林夏']).kind, SceneKind.open);
      expect(sceneLook(scene, ignore: ['林夏']).rain, isTrue);
    });

    test('识别雨、雪和夜晚', () {
      final rainyNight = sceneLook('雨夜的老街');
      expect(rainyNight.rain, isTrue);
      expect(rainyNight.night, isTrue);
      expect(rainyNight.snow, isFalse);
      expect(sceneLook('雪落在肩上').snow, isTrue);
      expect(sceneLook('阳光照进来').night, isFalse);
      expect(sceneLook('雨夜的老街'), sceneLook('雨夜的老街'));
    });
  });

  test('转场：开头 0.25 秒从黑场淡入，「镜头 n」停 0.4 秒后 0.5 秒淡出', () {
    expect(shotFadeIn(0), 0);
    expect(shotFadeIn(125), 0.5);
    expect(shotFadeIn(1000), 1);
    expect(titleCardOpacity(0), 1);
    expect(titleCardOpacity(400), 1);
    expect(titleCardOpacity(650), closeTo(0.5, 1e-9));
    expect(titleCardOpacity(900), 0);
    expect(titleCardOpacity(3000), 0);
  });

  test('多人同框按人数缩小，单人和远景不缩', () {
    final medium = framingFor(ShotSize.medium);
    expect(crowdScale(medium, 1), 1);
    expect(crowdScale(medium, 2), lessThan(1));
    expect(crowdScale(medium, 3), greaterThanOrEqualTo(0.85));
    expect(crowdScale(framingFor(ShotSize.long), 3), 1);
  });

  test('缩小后中景仍截到腰，远景只缩小不移动', () {
    final medium = framingFor(ShotSize.medium);
    final scaled = scaledFraming(medium, 0.85);
    expect(scaled.visibleBodyRatio, closeTo(medium.visibleBodyRatio, 1e-9));
    expect(scaled.headTop, greaterThan(medium.headTop));
    final long = framingFor(ShotSize.long);
    expect(scaledFraming(long, 0.9).headTop, long.headTop);
    expect(scaledFraming(medium, 1).headTop, medium.headTop);
  });

  group('人物摆位和角色名', () {
    test('多人横向排开居中；特写只留第一个人', () {
      final two = placeFigures(ShotSize.medium, ['林夏', '陈默']);
      expect(two.map((f) => f.name), ['林夏', '陈默']);
      expect(two.first.centerX, closeTo(0.275, 1e-9));
      expect(two.last.centerX, closeTo(0.725, 1e-9));
      expect(placeFigures(ShotSize.closeUp, ['林夏', '陈默']).map((f) => f.name), ['林夏']);
      expect(placeFigures(ShotSize.full, []), isEmpty);
    });

    test('能看到脚时标在脚下，脚在画外时贴着下方、字幕上面', () {
      const still = CameraFrame();
      final full = placeFigures(ShotSize.full, ['林夏']).single;
      // 全景脚底在 0.9，标签在其下 0.03，超过下限 0.84 时贴住下限
      expect(nameLabelAnchor(full, still)!.dy, 0.84);
      final long = placeFigures(ShotSize.long, ['林夏']).single;
      expect(nameLabelAnchor(long, still)!.dy, closeTo(0.83, 1e-9));
      final medium = placeFigures(ShotSize.medium, ['林夏']).single;
      expect(nameLabelAnchor(medium, still), const Offset(0.5, 0.84));
    });

    test('标签跟着运镜移动，人物出画时不显示', () {
      final long = placeFigures(ShotSize.long, ['林夏']).single;
      final panned = nameLabelAnchor(long, cameraTransform(CameraMove.pan, 0))!;
      expect(panned.dx, closeTo(0.85, 1e-9));
      final pushed = nameLabelAnchor(long, cameraTransform(CameraMove.push, 1))!;
      expect(pushed.dy, greaterThan(nameLabelAnchor(long, const CameraFrame())!.dy - 1e-9));
      // 跟拍时人物不动，标签也不动
      final followed = nameLabelAnchor(long, cameraTransform(CameraMove.follow, 0.5))!;
      expect(followed.dx, closeTo(0.5, 0.02));
      // 移镜开头人物在右侧
      expect(nameLabelAnchor(long, cameraTransform(CameraMove.track, 0))!.dx, closeTo(0.8, 1e-9));
      final edge = FigurePlacement(name: '陈默', centerX: 0.8, framing: long.framing);
      expect(nameLabelAnchor(edge, cameraTransform(CameraMove.pan, 0)), isNull);
    });
  });

  test('长发按名字固定', () {
    expect(characterLongHair('林夏'), characterLongHair('林夏'));
    expect(nameHash('林夏'), isNot(nameHash('陈默')));
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
