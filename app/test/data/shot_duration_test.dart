import 'package:flutter_test/flutter_test.dart';
import 'package:jingtouben/data/models/shot_draft.dart';
import 'package:jingtouben/data/models/shot_duration.dart';
import 'package:jingtouben/data/models/shot_size.dart';

void main() {
  ShotDraft shot({ShotSize size = ShotSize.medium, String dialogue = '', int? durationMs}) =>
      ShotDraft(index: 0, shotSize: size, scene: '街口', dialogue: dialogue, durationMs: durationMs);

  group('defaultShotDurationMs', () {
    test('无对白：大远景 / 远景 3 秒，其余 2 秒', () {
      expect(defaultShotDurationMs(shot(size: ShotSize.extremeLong)), 3000);
      expect(defaultShotDurationMs(shot(size: ShotSize.long)), 3000);
      expect(defaultShotDurationMs(shot(size: ShotSize.closeUp)), 2000);
      expect(defaultShotDurationMs(shot(dialogue: '   ')), 2000);
    });

    test('有对白：字数 × 250 毫秒 + 1 秒，下限 2 秒、上限 8 秒，空白不计字数', () {
      expect(defaultShotDurationMs(shot(dialogue: '是你？')), 2000);
      expect(defaultShotDurationMs(shot(dialogue: '我 等 了 你 很 久')), 2500);
      expect(defaultShotDurationMs(shot(dialogue: '一' * 40)), 8000);
    });
  });

  test('有存值时用存值，没有时用推导值并标为估算', () {
    expect(shot(durationMs: 4500).effectiveDurationMs, 4500);
    expect(shot(durationMs: 4500).isDurationEstimated, isFalse);
    expect(shot(size: ShotSize.long).effectiveDurationMs, 3000);
    expect(shot().isDurationEstimated, isTrue);
  });
}
