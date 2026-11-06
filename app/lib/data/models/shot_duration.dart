import 'shot_draft.dart';
import 'shot_size.dart';

/// 镜头时长的取值范围，与服务端提示词里 `durationSec` 的 1–10 一致。
const minShotDurationMs = 1000;
const maxShotDurationMs = 10000;

/// 没有时长（模型没给、旧数据）时按规则推导，结果不回写数据库：规则以后要调，改这里即可。
///
/// - 有对白：`max(2 秒, 字数 × 250 毫秒 + 1 秒)`，上限 8 秒；字数不含空白，含标点。
/// - 无对白：大远景 / 远景 3 秒，其余 2 秒。
int defaultShotDurationMs(ShotDraft shot) {
  final chars = shot.dialogue.replaceAll(RegExp(r'\s'), '').runes.length;
  if (chars > 0) return (chars * 250 + 1000).clamp(2000, 8000);
  return switch (shot.shotSize) {
    ShotSize.extremeLong || ShotSize.long => 3000,
    _ => 2000,
  };
}

extension ShotDuration on ShotDraft {
  /// 预演和展示用的时长：有存值用存值，否则按 [defaultShotDurationMs] 推导。
  int get effectiveDurationMs => durationMs ?? defaultShotDurationMs(this);

  /// 时长是否为推导值，展示时标「约」。
  bool get isDurationEstimated => durationMs == null;
}
