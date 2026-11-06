import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../data/models/camera_move.dart';
import '../../data/models/shot_size.dart';

/// 预演示意画面的镜头语言，全部是纯函数：单测直接断言数值，不依赖截图比对。
///
/// 坐标单位：长度按画框高度归一化（1.0 = 画框高），水平位移按画框宽度归一化。

/// 人物剪影的构图：人物从头顶到脚底的高度，以及头顶在画框中的位置。
class Framing {
  const Framing({required this.figureHeight, required this.headTop});

  /// 人物身高占画框高度的比例；大于 1 表示人物被画框截断。
  final double figureHeight;

  /// 头顶距画框上沿的距离，可以为负（头顶出画）。
  final double headTop;

  /// 头部直径占身高的比例，剪影和测试共用。
  static const headRatio = 0.12;

  double get headDiameter => figureHeight * headRatio;

  /// 画框下沿截在人物身上的位置：0 = 头顶，1 = 脚底；大于等于 1 表示全身可见。
  double get visibleBodyRatio => (1 - headTop) / figureHeight;
}

/// 景别 → 构图。数值是需求 4.3 的初始设定，实测后在这里调整。
Framing framingFor(ShotSize size) => switch (size) {
  ShotSize.extremeLong => const Framing(figureHeight: 0.08, headTop: 0.70),
  ShotSize.long => const Framing(figureHeight: 0.15, headTop: 0.65),
  ShotSize.full => const Framing(figureHeight: 0.55, headTop: 0.35),
  // 中景截到腰（约身高 55%），近景截到胸（约 30%）
  ShotSize.medium => const Framing(figureHeight: 1.3, headTop: 0.2),
  ShotSize.mediumCloseUp => const Framing(figureHeight: 2.2, headTop: 0.18),
  // 特写：脸宽约占画框宽度九成（画框宽 = 高 × 9/16）
  ShotSize.closeUp => const Framing(figureHeight: 4.2, headTop: 0.22),
  // 大特写：脸比画框还大，只看到眼睛一带
  ShotSize.extremeCloseUp => const Framing(figureHeight: 9, headTop: -0.04),
};

/// 特写和大特写只画一个人：脸已经占满画框。
bool showsSingleFigure(ShotSize size) =>
    size == ShotSize.closeUp || size == ShotSize.extremeCloseUp;

/// 某一时刻的镜头变换。
class CameraFrame {
  const CameraFrame({
    this.scale = 1,
    this.offset = Offset.zero,
    this.backgroundOffset = 0,
    this.figureBob = 0,
  });

  /// 以画框中心为原点缩放整个画面。
  final double scale;

  /// 整个画面（背景 + 人物）的平移：dx 按画框宽、dy 按画框高。
  final Offset offset;

  /// 只作用在背景上的水平平移（按画框宽），人物不动。
  final double backgroundOffset;

  /// 人物上下起伏（按画框高），表现跟拍时人物在走。
  final double figureBob;
}

/// 运镜 → [t]（0–1，镜头内进度）时刻的变换。先做缓动，开头和结尾不突兀。
CameraFrame cameraTransform(CameraMove move, double t) {
  final eased = Curves.easeInOut.transform(t.clamp(0.0, 1.0));
  double lerp(double a, double b) => a + (b - a) * eased;
  return switch (move) {
    CameraMove.fixed => const CameraFrame(),
    CameraMove.push => CameraFrame(scale: lerp(1, 1.25)),
    CameraMove.pull => CameraFrame(scale: lerp(1.25, 1)),
    // 摇：机位不动、镜头转向，整个画面横向扫过
    CameraMove.pan => CameraFrame(offset: Offset(lerp(0.15, -0.15), 0)),
    // 升降：整个画面竖直移动
    CameraMove.crane => CameraFrame(offset: Offset(0, lerp(-0.1, 0.1))),
    // 移：机位横移、人物保持在画框里，背景划过
    CameraMove.track => CameraFrame(backgroundOffset: lerp(0.2, -0.2)),
    // 跟：同样人物不动、背景反向划过，再加上走路的起伏
    CameraMove.follow => CameraFrame(
      backgroundOffset: lerp(0.25, -0.25),
      figureBob: math.sin(t * math.pi * 6).abs() * 0.01,
    ),
  };
}

/// 字幕在镜头结束前留出的完整显示时间。
const subtitleHoldMs = 500;

/// 已播 [elapsedMs] 时字幕应显示的字数：逐字出现，镜头结束前 [subtitleHoldMs] 已经完整。
int visibleSubtitleChars({required int elapsedMs, required int durationMs, required int length}) {
  if (length == 0) return 0;
  final revealMs = durationMs - subtitleHoldMs;
  if (revealMs <= 0) return length;
  final ratio = (elapsedMs / revealMs).clamp(0.0, 1.0);
  return (ratio * length).ceil().clamp(0, length);
}

/// 角色名 → 剪影颜色。用 FNV-1a 取稳定哈希：`String.hashCode` 不保证每次运行一致。
Color characterColor(String name, {required bool dark}) {
  var hash = 0x811c9dc5;
  for (final unit in name.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  // 落到 8 个相隔 45° 的色相档：直接取 0–360 时，两个名字常落在相近的颜色上，同框分不清
  final hue = (hash % 8) * 45.0;
  return HSLColor.fromAHSL(1, hue, 0.45, dark ? 0.62 : 0.5).toColor();
}

/// 毫秒 → 「m:ss」。
String formatPlaybackTime(int ms) {
  final seconds = (ms / 1000).floor();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
