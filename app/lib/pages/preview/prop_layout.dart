import 'dart:math' as math;
import 'dart:ui';

import '../../data/models/prop_drawing.dart';
import '../../data/models/shot_prop.dart';
import 'figure_pose.dart';

/// 生成道具画在哪：分给谁、拿在哪只手还是放在脚边。纯函数，单测直接断言。
///
/// 内置道具（伞、黑伞、手机）转成木偶人的 [FigureProps]，和手部姿态绑定：伞占左手、手机占右手。
/// 生成道具里拿在手里的找空着的手（先右后左），两只手都占用、或还没画好（画占位方块）时放到脚边；
/// 放地上 / 桌上 / 墙上的本期都放脚边（需求 Q4）；没有归属的放在场景里。
/// 画框截在身上的景别（中景以上）看不到脚边，属于某人的桌上道具改为举在胸前（每人一个），
/// 用空着的手托着，免得近景里的关键道具（生日蛋糕、信）画不出来。
class ShotPropPlan {
  const ShotPropPlan({
    this.builtin = const {},
    this.held = const {},
    this.beside = const {},
    this.scene = const [],
    this.raised = const {},
  });

  /// 每个人的内置道具。
  final Map<String, FigureProps> builtin;

  /// 每个人手里的生成道具。
  final Map<String, ({String? left, String? right})> held;

  /// 每个人脚边的生成道具（按摆放顺序）。
  final Map<String, List<String>> beside;

  /// 没有归属的生成道具。
  final List<String> scene;

  /// 每个人举在胸前的生成道具（近景以上的桌上道具）。
  final Map<String, String> raised;
}

/// [figures] 是画面里画出来的人（特写只画第一个人）；[drawings] 是已经画好的生成道具；
/// [rightHandBusy] 为 true 时右手在挥手。
ShotPropPlan planProps(
  List<ShotProp> props, {
  required List<String> figures,
  required Map<String, PropDrawing> drawings,
  bool rightHandBusy = false,
  bool bodyCut = false,
}) {
  final builtin = <String, FigureProps>{};
  final held = <String, ({String? left, String? right})>{};
  final beside = <String, List<String>>{};
  final scene = <String>[];
  final raised = <String, String>{};

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
    if (bodyCut && drawing?.anchor == PropAnchor.table && !raised.containsKey(owner)) {
      final hands = held[owner] ?? (left: null, right: null);
      final taken = builtin[owner] ?? const FigureProps();
      final right = hands.right == null && !taken.phone && !rightHandBusy;
      final left = hands.left == null && !taken.umbrella;
      if (right || left) {
        raised[owner] = prop.name;
        builtin[owner] = taken.copyWith(raiseRight: right, raiseLeft: !right);
        continue;
      }
    }
    if (drawing?.anchor == PropAnchor.hand) {
      final hands = held[owner] ?? (left: null, right: null);
      final taken = builtin[owner] ?? const FigureProps();
      if (hands.right == null && !taken.phone && !taken.raiseRight && !rightHandBusy) {
        held[owner] = (left: hands.left, right: prop.name);
        continue;
      }
      if (hands.left == null && !taken.umbrella && !taken.raiseLeft) {
        held[owner] = (left: prop.name, right: hands.right);
        continue;
      }
    }
    (beside[owner] ??= []).add(prop.name);
  }
  return ShotPropPlan(builtin: builtin, held: held, beside: beside, scene: scene, raised: raised);
}

/// 还没画好的道具画成占位方块，边长占人身高的比例。
const propPlaceholderSize = 0.22;

/// 手里的道具：边长 = `size × 身高` 的方框，握持点对准手。
Rect heldPropRect(PropDrawing drawing, {required Offset hand, required double figureHeight}) {
  final side = drawing.size * figureHeight;
  final grip = drawing.grip ?? const Offset(0.5, 0.1);
  return Rect.fromLTWH(hand.dx - grip.dx * side, hand.dy - grip.dy * side, side, side);
}

/// 脚边的道具：底边贴着脚底。第 [slot] 个，偶数放外侧、奇数放内侧，越往后离人越远。
/// [outward] 是外侧的方向：人在画面左半边时为 -1（往左放），否则为 1；双人镜头里道具不会堆到两人中间。
Rect besidePropRect(
  double size, {
  required double centerX,
  required double feetY,
  required double figureHeight,
  required int slot,
  double outward = 1,
}) {
  final side = size * figureHeight;
  final offset = figureHeight * 0.16 + side / 2 + (slot ~/ 2) * (side + figureHeight * 0.04);
  final x = centerX + (slot.isEven ? offset : -offset) * outward.sign;
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

/// 举在胸前的道具：从领口往下放，挨着托住它的手（[side] 为 1 是右手、-1 是左手）。
/// 特写里人被放得很大，道具最多占画框宽度的六成；胸口在画框外时往上挪到露出七成，但不高过下巴。
Rect raisedPropRect(
  double size, {
  required double centerX,
  required double headTop,
  required double figureHeight,
  required double frameWidth,
  required double frameHeight,
  double side = 1,
}) {
  final edge = math.min(size * figureHeight, 0.6 * frameWidth);
  final chin = headTop + 0.13 * figureHeight;
  final chest = headTop + 0.2 * figureHeight;
  final top = math.max(chin, math.min(chest, frameHeight - 0.7 * edge));
  final x = centerX + side * math.min(0.04 * figureHeight, 0.1 * frameWidth);
  return Rect.fromLTWH(x - edge / 2, top, edge, edge);
}
