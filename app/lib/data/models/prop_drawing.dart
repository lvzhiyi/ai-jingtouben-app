import 'dart:ui';

import 'package:equatable/equatable.dart';

import 'shot_prop.dart';

/// 内置画法的道具（和木偶人的手部姿态绑定），不请求生成。
const builtinPropNames = {'伞', '雨伞', '黑伞', '手机'};

bool isBuiltinProp(String name) => builtinPropNames.contains(name);

/// 道具放在哪。本期 [table]、[wall] 先按 [ground] 摆放（需求 Q4）。
enum PropAnchor {
  hand,
  ground,
  table,
  wall;

  static PropAnchor? tryParse(Object? value) {
    for (final anchor in values) {
      if (anchor.name == value) return anchor;
    }
    return null;
  }
}

/// 填充档位，渲染时映射到预演配色，保证风格统一、夜景和深色模式也能看。
enum PropFill {
  none,
  light,
  mid,
  dark,
  accent;

  static PropFill? tryParse(Object? value) {
    if (value == null) return none;
    for (final fill in values) {
      if (fill.name == value) return fill;
    }
    return null;
  }
}

/// 绘图里的一个图形。坐标都在道具的 0–1 方框里，x 向右、y 向下。
sealed class PropShape extends Equatable {
  const PropShape();

  Map<String, Object?> toJson();
}

/// 线段、折线或闭合的多边形。
final class PropPath extends PropShape {
  const PropPath({required this.points, this.closed = false, this.fill = PropFill.none});

  final List<Offset> points;
  final bool closed;

  /// 只有闭合的多边形会填充。
  final PropFill fill;

  @override
  Map<String, Object?> toJson() => {
    't': closed ? 'polygon' : (points.length == 2 ? 'line' : 'polyline'),
    'pts': [
      for (final p in points) [p.dx, p.dy],
    ],
    if (closed) 'fill': fill.name,
  };

  @override
  List<Object?> get props => [points, closed, fill];
}

/// 椭圆（圆是宽高相等的椭圆）。
final class PropEllipse extends PropShape {
  const PropEllipse({
    required this.center,
    required this.width,
    required this.height,
    this.fill = PropFill.none,
  });

  final Offset center;
  final double width;
  final double height;
  final PropFill fill;

  @override
  Map<String, Object?> toJson() => {
    't': 'ellipse',
    'x': center.dx,
    'y': center.dy,
    'w': width,
    'h': height,
    'fill': fill.name,
  };

  @override
  List<Object?> get props => [center, width, height, fill];
}

/// 圆弧，角度单位是度，0 度指向右、顺时针。
final class PropArc extends PropShape {
  const PropArc({
    required this.center,
    required this.radius,
    required this.start,
    required this.end,
  });

  final Offset center;
  final double radius;
  final double start;
  final double end;

  @override
  Map<String, Object?> toJson() => {
    't': 'arc',
    'x': center.dx,
    'y': center.dy,
    'r': radius,
    'start': start,
    'end': end,
  };

  @override
  List<Object?> get props => [center, radius, start, end];
}

/// 模型生成的道具绘图，已通过 [tryParse] 的校验。
class PropDrawing extends Equatable {
  const PropDrawing({
    required this.name,
    required this.anchor,
    required this.size,
    required this.shapes,
    this.grip,
  });

  final String name;
  final PropAnchor anchor;

  /// 道具高度相对人身高（人 = 1）。
  final double size;

  /// 手握的位置（方框坐标），只有拿在手里的道具有。
  final Offset? grip;

  /// 从后到前。
  final List<PropShape> shapes;

  static const maxShapes = 30;
  static const minSize = 0.03;
  static const maxSize = 1.5;

  /// 坐标允许略微超出方框（模型常把描边画到边上）。
  static const _minCoord = -0.05;
  static const _maxCoord = 1.05;

  Map<String, Object?> toJson() => {
    'name': name,
    'anchor': anchor.name,
    'size': size,
    if (grip case final grip?) 'grip': [grip.dx, grip.dy],
    'shapes': [for (final shape in shapes) shape.toJson()],
  };

  /// 按白名单校验模型输出：图形类型、点数、坐标范围、大小、摆放位置。任何一项不合格整个道具返回 null。
  /// 只读数据，不执行模型输出的任何东西。
  static PropDrawing? tryParse(Object? json) {
    if (json is! Map) return null;
    final name = normalizePropName(json['name']);
    final anchor = PropAnchor.tryParse(json['anchor']);
    final size = _number(json['size']);
    final rawShapes = json['shapes'];
    if (name == null || anchor == null || size == null) return null;
    if (size < minSize || size > maxSize) return null;
    if (rawShapes is! List || rawShapes.isEmpty || rawShapes.length > maxShapes) return null;

    Offset? grip;
    if (anchor == PropAnchor.hand) {
      grip = _point(json['grip']);
      if (grip == null) return null;
    }
    final shapes = <PropShape>[];
    for (final raw in rawShapes) {
      final shape = _shape(raw);
      if (shape == null) return null;
      shapes.add(shape);
    }
    return PropDrawing(name: name, anchor: anchor, size: size, grip: grip, shapes: shapes);
  }

  static PropShape? _shape(Object? json) {
    if (json is! Map) return null;
    final fill = PropFill.tryParse(json['fill']);
    if (fill == null) return null;
    switch (json['t']) {
      case 'line' || 'polyline' || 'polygon':
        final type = json['t'];
        final points = _points(json['pts']);
        if (points == null) return null;
        final (min, max) = switch (type) {
          'line' => (2, 2),
          'polyline' => (2, 16),
          _ => (3, 12),
        };
        if (points.length < min || points.length > max) return null;
        return PropPath(
          points: points,
          closed: type == 'polygon',
          fill: type == 'polygon' ? fill : PropFill.none,
        );
      case 'circle':
        final center = _point([json['x'], json['y']]);
        final r = _length(json['r']);
        if (center == null || r == null) return null;
        return PropEllipse(center: center, width: r * 2, height: r * 2, fill: fill);
      case 'ellipse':
        final center = _point([json['x'], json['y']]);
        final w = _length(json['w']);
        final h = _length(json['h']);
        if (center == null || w == null || h == null) return null;
        return PropEllipse(center: center, width: w, height: h, fill: fill);
      case 'arc':
        final center = _point([json['x'], json['y']]);
        final r = _length(json['r']);
        final start = _number(json['start']);
        final end = _number(json['end']);
        if (center == null || r == null || start == null || end == null) return null;
        if (start.abs() > 720 || end.abs() > 720) return null;
        return PropArc(center: center, radius: r, start: start, end: end);
      default:
        return null;
    }
  }

  static double? _number(Object? value) => value is num && value.isFinite ? value.toDouble() : null;

  static bool _inRange(double v) => v >= _minCoord && v <= _maxCoord;

  /// 半径、宽高：大于 0，不超过方框。
  static double? _length(Object? value) {
    final v = _number(value);
    return v != null && v > 0 && v <= _maxCoord ? v : null;
  }

  static Offset? _point(Object? value) {
    if (value is! List || value.length != 2) return null;
    final x = _number(value[0]);
    final y = _number(value[1]);
    if (x == null || y == null || !_inRange(x) || !_inRange(y)) return null;
    return Offset(x, y);
  }

  static List<Offset>? _points(Object? value) {
    if (value is! List) return null;
    final points = <Offset>[];
    for (final raw in value) {
      final point = _point(raw);
      if (point == null) return null;
      points.add(point);
    }
    return points;
  }

  @override
  List<Object?> get props => [name, anchor, size, grip, shapes];
}
