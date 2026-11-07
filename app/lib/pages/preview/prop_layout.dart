import 'dart:ui';

import '../../data/models/prop_drawing.dart';
import '../../data/models/shot_prop.dart';
import 'figure_pose.dart';

/// 生成道具画在哪：分给谁、拿在哪只手还是放在脚边。纯函数，单测直接断言。
///
/// 内置道具（伞、黑伞、手机）转成木偶人的 [FigureProps]，和手部姿态绑定：伞占左手、手机占右手。
/// 生成道具里拿在手里的找空着的手（先右后左），两只手都占用、或还没画好（画占位方块）时放到脚边；
/// 放地上 / 桌上 / 墙上的本期都放脚边（需求 Q4）；没有归属的放在场景里。
class ShotPropPlan {
  const ShotPropPlan({
    this.builtin = const {},
    this.held = const {},
    this.beside = const {},
    this.scene = const [],
  });

  /// 每个人的内置道具。
  final Map<String, FigureProps> builtin;

  /// 每个人手里的生成道具。
  final Map<String, ({String? left, String? right})> held;

  /// 每个人脚边的生成道具（按摆放顺序）。
  final Map<String, List<String>> beside;

  /// 没有归属的生成道具。
  final List<String> scene;
}

/// [figures] 是画面里画出来的人（特写只画第一个人）；[drawings] 是已经画好的生成道具；
/// [rightHandBusy] 为 true 时右手在挥手。
ShotPropPlan planProps(
  List<ShotProp> props, {
  required List<String> figures,
  required Map<String, PropDrawing> drawings,
  bool rightHandBusy = false,
}) {
  final builtin = <String, FigureProps>{};
  final held = <String, ({String? left, String? right})>{};
  final beside = <String, List<String>>{};
  final scene = <String>[];

  for (final prop in props.where((p) => isBuiltinProp(p.name))) {
    // 内置道具没有归属时给第一个人（通常是主角）；归属的人不在画面里就不画
    final owner = prop.owner ?? (figures.isEmpty ? null : figures.first);
    if (owner == null || !figures.contains(owner)) continue;
    final current = builtin[owner] ?? const FigureProps();
    builtin[owner] = switch (prop.name) {
      '手机' => FigureProps(
        umbrella: current.umbrella,
        darkUmbrella: current.darkUmbrella,
        phone: true,
      ),
      _ => FigureProps(
        umbrella: true,
        darkUmbrella: current.darkUmbrella || prop.name == '黑伞',
        phone: current.phone,
      ),
    };
  }

  for (final prop in props.where((p) => !isBuiltinProp(p.name))) {
    if (prop.owner != null && !figures.contains(prop.owner)) continue; // 归属的人不在画面里
    final owner = prop.owner;
    if (owner == null) {
      scene.add(prop.name);
      continue;
    }
    final drawing = drawings[prop.name];
    if (drawing?.anchor == PropAnchor.hand) {
      final hands = held[owner] ?? (left: null, right: null);
      final taken = builtin[owner] ?? const FigureProps();
      if (hands.right == null && !taken.phone && !rightHandBusy) {
        held[owner] = (left: hands.left, right: prop.name);
        continue;
      }
      if (hands.left == null && !taken.umbrella) {
        held[owner] = (left: prop.name, right: hands.right);
        continue;
      }
    }
    (beside[owner] ??= []).add(prop.name);
  }
  return ShotPropPlan(builtin: builtin, held: held, beside: beside, scene: scene);
}

/// 还没画好的道具画成占位方块，边长占人身高的比例。
const propPlaceholderSize = 0.22;

/// 手里的道具：边长 = `size × 身高` 的方框，握持点对准手。
Rect heldPropRect(PropDrawing drawing, {required Offset hand, required double figureHeight}) {
  final side = drawing.size * figureHeight;
  final grip = drawing.grip ?? const Offset(0.5, 0.1);
  return Rect.fromLTWH(hand.dx - grip.dx * side, hand.dy - grip.dy * side, side, side);
}

/// 脚边的道具：底边贴着脚底。第 [slot] 个，偶数放右边、奇数放左边，越往后离人越远。
Rect besidePropRect(
  double size, {
  required double centerX,
  required double feetY,
  required double figureHeight,
  required int slot,
}) {
  final side = size * figureHeight;
  final offset = figureHeight * 0.16 + side / 2 + (slot ~/ 2) * (side + figureHeight * 0.04);
  final x = centerX + (slot.isEven ? offset : -offset);
  return Rect.fromLTWH(x - side / 2, feetY - side, side, side);
}

/// 场景里没有归属的道具：按画框宽度的几个固定位置排开（两侧优先，不挡画面中间的人）。
Rect scenePropRect(
  double size, {
  required double frameWidth,
  required double feetY,
  required double figureHeight,
  required int slot,
}) {
  const slots = [0.14, 0.86, 0.3, 0.7, 0.5];
  final side = size * figureHeight;
  final x = slots[slot % slots.length] * frameWidth;
  return Rect.fromLTWH(x - side / 2, feetY - side, side, side);
}
