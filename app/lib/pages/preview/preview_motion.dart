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

/// 画面各层离摄影机的距离，以人物所在平面为 1。数越大越远，运镜时移动和缩放越少。
abstract final class SceneDepth {
  /// 天空、月亮、星星：几乎不动。
  static const sky = 20.0;

  /// 远楼、远山、地平线。
  static const far = 3.5;

  /// 人物身后的墙、立柱、树、路灯。
  static const mid = 1.6;

  /// 人物脚下的地面细节（路面虚线、地板缝、草）和人物本身。
  static const subject = 1.0;

  /// 镜头前的遮挡物（近处的柱子、枝叶），画在人物前面。
  static const foreground = 0.55;
}

/// 运镜的缓动：起步和停下都缓，停下前略冲过一点（约 1.5%）再回正，像真实的摄影机。
/// 0 → 0、1 → 1，中途最大约 1.015。
double cameraEase(double t) {
  const settleAt = 0.88;
  const overshoot = 1.015;
  final x = t.clamp(0.0, 1.0);
  if (x <= settleAt) return Curves.easeInOutCubic.transform(x / settleAt) * overshoot;
  return overshoot - (overshoot - 1) * Curves.easeOut.transform((x - settleAt) / (1 - settleAt));
}

/// 某一时刻的摄影机状态。画面按深度分层，每层的位移和缩放由 [layerView] 算出。
class CameraFrame {
  const CameraFrame({
    this.dolly = 0,
    this.pan = Offset.zero,
    this.truck = Offset.zero,
    this.subjectFollows = false,
    this.shake = Offset.zero,
    this.figureBob = 0,
  });

  /// 摄影机往前走了多远（以人物平面的距离为 1）：推是 0 → 0.375，人物放大到 1.6 倍，
  /// 近处的东西放大得更快、远处的几乎不变。
  final double dolly;

  /// 镜头转向（摇、俯仰）：所有层同样平移，没有视差。dx 按画框宽、dy 按画框高。
  final Offset pan;

  /// 机位平移（移、跟、升降）：每层平移 `-truck / 深度`，近处的划过得快、远处的慢。
  /// dx 为正表示机位往右，dy 为正表示机位往下。
  final Offset truck;

  /// 跟拍：人物和机位一起走，人物在画框里不动，只有场景按视差后退。
  final bool subjectFollows;

  /// 手持的轻微晃动，作用在所有层上。
  final Offset shake;

  /// 人物上下起伏（按画框高），表现跟拍时人物在走。
  final double figureBob;
}

/// 一层画面在当前镜头下的样子：先平移 [shift]（dx 按画框宽、dy 按画框高），
/// 再以画框中心缩放 [scale]。点 p（归一化坐标）落到 `0.5 + (p - 0.5 + shift) * scale`。
class LayerView {
  const LayerView({this.scale = 1, this.shift = Offset.zero});

  final double scale;
  final Offset shift;

  /// 归一化坐标下的点经过这一层变换后在画框里的位置。
  Offset project(Offset point) =>
      Offset(0.5 + (point.dx - 0.5 + shift.dx) * scale, 0.5 + (point.dy - 0.5 + shift.dy) * scale);
}

/// [depth] 深度的一层在 [camera] 下的变换。[subject] 为 true 表示人物层：跟拍时人物随机位一起走。
LayerView layerView(CameraFrame camera, double depth, {bool subject = false}) {
  // 摄影机往前走 dolly，这一层离镜头从 depth 变成 depth - dolly，放大 depth / (depth - dolly)
  final scale = depth / math.max(depth - camera.dolly, 0.05);
  final followed = subject && camera.subjectFollows;
  final parallax = followed ? Offset(0, -camera.truck.dy / depth) : -camera.truck / depth;
  return LayerView(scale: scale, shift: camera.pan + camera.shake + parallax);
}

/// 运镜 → [t]（0–1，镜头内进度）时刻的摄影机状态，缓动见 [cameraEase]。
CameraFrame cameraTransform(CameraMove move, double t) {
  final eased = cameraEase(t);
  double lerp(double a, double b) => a + (b - a) * eased;
  return switch (move) {
    CameraMove.fixed => const CameraFrame(),
    // 真推：机位往前走，人物放大到 1.6 倍；前景冲出画框，远景几乎不变
    CameraMove.push => CameraFrame(dolly: lerp(0, 0.375)),
    CameraMove.pull => CameraFrame(dolly: lerp(0.375, 0)),
    // 摇：机位不动、镜头转向，远近一起扫过，没有视差
    CameraMove.pan => CameraFrame(pan: Offset(lerp(0.35, -0.35), 0)),
    // 移：机位横移，人物从画框一侧移到另一侧，前景划得最快、远景最慢
    CameraMove.track => CameraFrame(truck: Offset(lerp(-0.3, 0.3), 0)),
    // 跟：人物在画框里不动，场景按远近不同速度后退，带手持晃动和走路起伏
    CameraMove.follow => CameraFrame(
      truck: Offset(lerp(-0.6, 0.6), 0),
      subjectFollows: true,
      shake: handheldShake(t),
      figureBob: math.sin(t * math.pi * 6).abs() * 0.015,
    ),
    // 升：机位升高同时稍往下俯，近处的往下沉得快，地平线上移，天空变少
    CameraMove.crane => CameraFrame(
      truck: Offset(0, lerp(0, -0.3)),
      pan: Offset(0, lerp(0, -0.15)),
    ),
  };
}

/// 手持晃动：两个低频正弦叠加，幅度约画框的 0.6%，同一时刻结果固定。
Offset handheldShake(double t) => Offset(
  0.004 * math.sin(t * math.pi * 2 * 2.3) + 0.002 * math.sin(t * math.pi * 2 * 5.1 + 1),
  0.003 * math.sin(t * math.pi * 2 * 1.7 + 2) + 0.0015 * math.sin(t * math.pi * 2 * 4.3),
);

/// 景深：景别越近，焦点外（离人物平面越远）的层越虚。返回模糊半径，按画框宽归一化。
///
/// 弥散圆大小按 |1/深度 − 1| 算：人物平面最清楚，远景和近处的遮挡物都虚。远景到全景不虚。
double focusBlur(ShotSize size, double depth) {
  final strength = switch (size) {
    ShotSize.extremeLong || ShotSize.long => 0.0,
    ShotSize.full => 0.003,
    ShotSize.medium => 0.007,
    ShotSize.mediumCloseUp => 0.011,
    ShotSize.closeUp => 0.015,
    ShotSize.extremeCloseUp => 0.018,
  };
  return strength * (1 / depth - 1).abs();
}

/// 运镜在画面上的提示：镜头往哪个方向走（画框坐标，y 向下），以及推（1）还是拉（-1）。
class CameraHint {
  const CameraHint({this.direction, this.zoom = 0});

  final Offset? direction;
  final int zoom;
}

/// 运镜 → 叠加在画面上的方向提示。和 [cameraTransform] 一致：画面往左走就是镜头往右。
CameraHint cameraHint(CameraMove move) => switch (move) {
  CameraMove.fixed => const CameraHint(),
  CameraMove.push => const CameraHint(zoom: 1),
  CameraMove.pull => const CameraHint(zoom: -1),
  CameraMove.pan ||
  CameraMove.track ||
  CameraMove.follow => const CameraHint(direction: Offset(1, 0)),
  CameraMove.crane => const CameraHint(direction: Offset(0, -1)),
};

/// 画框落在人身上的范围，用人体坐标表示：y 方向 0 = 头顶、1 = 脚底，x 以身体中线为 0、
/// 和 y 同一单位。景别小图用它在全身人形上画出取景框。
Rect framingWindow(Framing framing) {
  final height = 1 / framing.figureHeight;
  final width = 9 / 16 / framing.figureHeight;
  return Rect.fromLTWH(-width / 2, -framing.headTop / framing.figureHeight, width, height);
}

/// 景别小图下面的说明。
String framingHint(ShotSize size) => switch (size) {
  ShotSize.extremeLong => '人在环境里很小',
  ShotSize.long => '全身，环境为主',
  ShotSize.full => '完整全身',
  ShotSize.medium => '腰部以上',
  ShotSize.mediumCloseUp => '胸部以上',
  ShotSize.closeUp => '面部',
  ShotSize.extremeCloseUp => '局部细节',
};

/// 场景模板：按画面描述里的关键词选背景，本地匹配，不调用模型。
enum SceneKind { screen, vehicle, indoor, station, street, nature, open }

/// 画面描述 → 场景模板和天气、时间。
class SceneLook {
  const SceneLook({
    this.kind = SceneKind.open,
    this.rain = false,
    this.snow = false,
    this.night = false,
  });

  final SceneKind kind;
  final bool rain;
  final bool snow;
  final bool night;

  @override
  bool operator ==(Object other) =>
      other is SceneLook &&
      other.kind == kind &&
      other.rain == rain &&
      other.snow == snow &&
      other.night == night;

  @override
  int get hashCode => Object.hash(kind, rain, snow, night);
}

/// 关键词按优先级排：越具体的场景越靠前（「公交站台」先算车站，再算街道）。
const _sceneKeywords = <SceneKind, List<String>>{
  SceneKind.screen: ['手机', '屏幕', '消息', '电脑', '短信'],
  SceneKind.vehicle: ['车内', '车里', '车窗', '驾驶', '副驾', '地铁', '车厢'],
  SceneKind.indoor: ['房间', '屋里', '室内', '客厅', '卧室', '办公', '餐厅', '咖啡', '教室', '病房', '窗边', '门口'],
  SceneKind.station: ['站台', '车站', '月台', '公交站', '候车', '机场'],
  SceneKind.street: ['街', '马路', '路口', '巷', '城市', '霓虹'],
  SceneKind.nature: ['山', '海', '树', '林', '田', '河', '湖', '公园', '草地', '花'],
};

/// [ignore] 传出场角色名：先从描述里去掉，避免「林夏」里的「林」被当成树林。
SceneLook sceneLook(String scene, {List<String> ignore = const []}) {
  for (final name in ignore) {
    if (name.isNotEmpty) scene = scene.replaceAll(name, ' ');
  }
  var kind = SceneKind.open;
  for (final MapEntry(key: candidate, value: words) in _sceneKeywords.entries) {
    if (words.any(scene.contains)) {
      kind = candidate;
      break;
    }
  }
  return SceneLook(
    kind: kind,
    rain: scene.contains('雨'),
    snow: scene.contains('雪'),
    night: ['夜', '晚上', '深夜', '月光', '霓虹', '黑暗'].any(scene.contains),
  );
}

/// 多人同框时人物的缩放：按每人分到的宽度把人缩小，避免中景里叠成一团；单人不缩放。
///
/// 肩宽按身高的 24% 算，[slot] 是每人分到的画框宽度比例。最多缩到 0.85，
/// 再小景别就变了；剩下的少量重叠像前后站位，双人镜头里本来常见。
double crowdScale(Framing framing, int count, {double slot = 0.9}) {
  if (count <= 1) return 1;
  final bodyWidth = 0.24 * framing.figureHeight * 16 / 9;
  return (slot / count * 0.95 / bodyWidth).clamp(0.85, 1.0);
}

/// 按 [scale] 缩小人物后的构图：画框下沿仍截在身体同一处（中景还是到腰），
/// 人往下移、头顶多留空；能看到全身的景别只缩小，不移动。
Framing scaledFraming(Framing framing, double scale) {
  if (scale == 1 || framing.visibleBodyRatio >= 1) {
    return Framing(figureHeight: framing.figureHeight * scale, headTop: framing.headTop);
  }
  return Framing(
    figureHeight: framing.figureHeight * scale,
    headTop: 1 - scale * (1 - framing.headTop),
  );
}

/// 一个人物在画框里的位置：横向中心（按画框宽）和构图。画人物和标角色名共用。
class FigurePlacement {
  const FigurePlacement({required this.name, required this.centerX, required this.framing});

  final String name;
  final double centerX;
  final Framing framing;
}

/// 景别和出场角色 → 每个人物画在哪。特写和大特写只画第一个人；多人时横向排开并按人数缩小。
List<FigurePlacement> placeFigures(ShotSize size, List<String> characters) {
  final names = showsSingleFigure(size) ? characters.take(1).toList() : characters;
  final base = framingFor(size);
  final framing = scaledFraming(base, crowdScale(base, names.length));
  return [
    for (var i = 0; i < names.length; i++)
      FigurePlacement(
        name: names[i],
        centerX: 0.5 + (i - (names.length - 1) / 2) * (0.9 / names.length),
        framing: framing,
      ),
  ];
}

/// 角色名标签放在画框里的哪里（按画框宽高归一化），跟着运镜移动；人物移出画框时返回 null。
///
/// 能看到脚时标在脚下；脚在画外时（中景、近景等）贴着画框下方、字幕上面。
Offset? nameLabelAnchor(FigurePlacement figure, CameraFrame camera) {
  final feet = figure.framing.headTop + figure.framing.figureHeight;
  final y = math.min(feet + 0.03, 0.84);
  // 和人物层一样的变换
  final screen = layerView(
    camera,
    SceneDepth.subject,
    subject: true,
  ).project(Offset(figure.centerX, y));
  if (screen.dx < 0 || screen.dx > 1) return null;
  return Offset(screen.dx.clamp(0.1, 0.9), screen.dy.clamp(0.08, 0.84));
}

/// 每镜开头从黑场淡入的时长。
const shotFadeInMs = 250;

/// 镜头开头的淡入：0 = 全黑，1 = 完全显示。
double shotFadeIn(int elapsedMs) => (elapsedMs / shotFadeInMs).clamp(0.0, 1.0);

/// 每镜开头的「镜头 n」小标：先停 0.4 秒，再用 0.5 秒淡出。
double titleCardOpacity(int elapsedMs) {
  if (elapsedMs <= 400) return 1;
  return (1 - (elapsedMs - 400) / 500).clamp(0.0, 1.0);
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

/// 角色名的稳定哈希（FNV-1a）：`String.hashCode` 不保证每次运行一致。
int nameHash(String name) {
  var hash = 0x811c9dc5;
  for (final unit in name.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

/// 角色是否画长发，按名字固定，让同框的人更好区分。
bool characterLongHair(String name) => (nameHash(name) >> 8).isOdd;

/// 角色名 → 衣服的颜色。
Color characterColor(String name, {required bool dark}) {
  final hash = nameHash(name);
  // 落到 8 个相隔 45° 的色相档：直接取 0–360 时，两个名字常落在相近的颜色上，同框分不清
  final hue = (hash % 8) * 45.0;
  return HSLColor.fromAHSL(1, hue, 0.45, dark ? 0.62 : 0.5).toColor();
}

/// 毫秒 → 「m:ss」。
String formatPlaybackTime(int ms) {
  final seconds = (ms / 1000).floor();
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
