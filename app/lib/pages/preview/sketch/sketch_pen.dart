import 'dart:math' as math;
import 'dart:ui';

/// 手绘分镜的笔触：线条带轻微抖动，再叠一道淡的复描，像铅笔草图。
///
/// 抖动来自固定种子的随机数，每帧按同样的顺序取值，画面不会闪。
/// 所以调用次数不能随时间变化：同一镜里每帧画的元素数量要一致。
class SketchPen {
  SketchPen(
    this.canvas, {
    required int seed,
    required this.ink,
    required this.width,
    required this.jitter,
  }) : _random = math.Random(seed);

  final Canvas canvas;
  final Color ink;

  /// 主笔画粗细（像素）。
  final double width;

  /// 抖动幅度（像素）。
  final double jitter;
  final math.Random _random;

  double _wobble() => (_random.nextDouble() * 2 - 1) * jitter;

  /// 把折线每段拆成三小段，中间点沿垂直方向随机偏一点。
  Path _wobblyPath(List<Offset> points, {required bool closed}) {
    final path = Path()..moveTo(points.first.dx + _wobble(), points.first.dy + _wobble());
    final all = closed ? [...points, points.first] : points;
    for (var i = 1; i < all.length; i++) {
      final from = all[i - 1];
      final to = all[i];
      final delta = to - from;
      final length = delta.distance;
      final normal = length == 0 ? Offset.zero : Offset(-delta.dy / length, delta.dx / length);
      for (final f in const [1 / 3, 2 / 3]) {
        final point = from + delta * f + normal * _wobble();
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(to.dx + _wobble() * 0.5, to.dy + _wobble() * 0.5);
    }
    if (closed) path.close();
    return path;
  }

  /// 描一条折线：主笔画加一道淡的复描。
  void stroke(List<Offset> points, {bool closed = false, Color? color, double scale = 1}) {
    if (points.length < 2) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color ?? ink
      ..strokeWidth = width * scale;
    canvas.drawPath(_wobblyPath(points, closed: closed), paint);
    paint
      ..color = paint.color.withValues(alpha: paint.color.a * 0.35)
      ..strokeWidth = width * scale * 0.6;
    canvas.drawPath(_wobblyPath(points, closed: closed), paint);
  }

  /// 先平涂再描边；[fill] 为空时只描边。
  void shape(List<Offset> points, {Color? fill, Color? color, double scale = 1}) {
    if (fill != null) {
      canvas.drawPath(Path()..addPolygon(points, true), Paint()..color = fill);
    }
    stroke(points, closed: true, color: color, scale: scale);
  }

  void line(Offset from, Offset to, {Color? color, double scale = 1}) =>
      stroke([from, to], color: color, scale: scale);

  void rect(Rect rect, {Color? fill, Color? color, double scale = 1}) => shape(
    [rect.topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft],
    fill: fill,
    color: color,
    scale: scale,
  );

  void circle(Offset center, double radius, {Color? fill, Color? color, double scale = 1}) => shape(
    ellipse(Rect.fromCircle(center: center, radius: radius)),
    fill: fill,
    color: color,
    scale: scale,
  );

  /// 椭圆的折线近似，点数固定，保证每帧取随机数的次数一致。
  static List<Offset> ellipse(Rect rect, {int points = 20}) => [
    for (var i = 0; i < points; i++)
      rect.center +
          Offset(
            math.cos(i / points * 2 * math.pi) * rect.width / 2,
            math.sin(i / points * 2 * math.pi) * rect.height / 2,
          ),
  ];

  /// 圆弧上的点，角度为弧度，0 指向右侧、顺时针（y 向下）。
  static List<Offset> arc(
    Offset center,
    double radius,
    double start,
    double end, {
    int points = 12,
  }) => [
    for (var i = 0; i <= points; i++)
      center +
          Offset(
            math.cos(start + (end - start) * i / points) * radius,
            math.sin(start + (end - start) * i / points) * radius,
          ),
  ];
}
