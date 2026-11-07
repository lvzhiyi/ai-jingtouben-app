import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../preview_motion.dart';
import 'sketch_pen.dart';

/// 手绘分镜的配色：纸、墨、淡彩，夜景换成深底浅线。
class SketchColors {
  const SketchColors({
    required this.paper,
    required this.ink,
    required this.fill,
    required this.accent,
    required this.dark,
  });

  /// 按主题和场景取色。夜景不论深浅模式都用深色底，线条改成浅色。
  factory SketchColors.of(ThemeData theme, {required bool night}) {
    final dark = theme.brightness == Brightness.dark;
    if (night) {
      return SketchColors(
        paper: const Color(0xFF262B3A),
        ink: const Color(0xFFE6E0D6),
        fill: const Color(0xFF353B4D),
        accent: theme.colorScheme.primary,
        dark: true,
      );
    }
    return SketchColors(
      paper: dark ? const Color(0xFF2B2724) : const Color(0xFFF8F3EA),
      ink: dark ? const Color(0xFFE9E1D6) : const Color(0xFF3B3631),
      fill: dark ? const Color(0xFF38332E) : const Color(0xFFFFFCF6),
      accent: theme.colorScheme.primary,
      dark: dark,
    );
  }

  final Color paper;
  final Color ink;

  /// 物体的底色：比纸略亮（夜景略亮于夜空），让线稿里的物体从背景里浮出来。
  final Color fill;
  final Color accent;
  final bool dark;

  /// 亮着的窗户、路灯。
  static const lamp = Color(0xFFF2C66D);

  Color faint(double alpha) => ink.withValues(alpha: alpha);

  @override
  bool operator ==(Object other) =>
      other is SketchColors &&
      other.paper == paper &&
      other.ink == ink &&
      other.fill == fill &&
      other.accent == accent &&
      other.dark == dark;

  @override
  int get hashCode => Object.hash(paper, ink, fill, accent, dark);
}

/// 地平线高度（按画框高）。
const sceneHorizon = 0.62;

/// 按深度分层画画面：每层按自己的深度跟着摄影机缩放、平移，焦点外的层按景深虚化。
///
/// 横向平移不动画布，而是把像素位移交给绘制函数去平铺（见 [_tiles]），背景怎么移都不露边。
class SceneCamera {
  SceneCamera(this.canvas, this.size, this.frame, {required this.blur});

  final Canvas canvas;
  final Size size;
  final CameraFrame frame;

  /// 深度 → 模糊半径（按画框宽归一化），见 `focusBlur`。
  final double Function(double depth) blur;

  /// 这一层在当前镜头下的变换。[attached] 表示跟着机位走的东西（车里的内饰），只受推拉和摇影响；
  /// [scaleDepth] 让这一层按另一个深度缩放（车窗外的景物横向划得快，但推镜时不该放大那么多）。
  LayerView view(double depth, {bool subject = false, bool attached = false, double? scaleDepth}) {
    final camera = attached
        ? CameraFrame(dolly: frame.dolly, pan: frame.pan, shake: frame.shake)
        : frame;
    final base = layerView(camera, depth, subject: subject);
    if (scaleDepth == null) return base;
    return LayerView(scale: layerView(camera, scaleDepth).scale, shift: base.shift);
  }

  /// 画一层。[draw] 收到这一层的横向位移（像素），画布已经做好缩放和竖直位移。
  void layer(
    double depth,
    void Function(double shift) draw, {
    bool subject = false,
    bool attached = false,
    double? scaleDepth,
  }) {
    final w = size.width;
    final h = size.height;
    final v = view(depth, subject: subject, attached: attached, scaleDepth: scaleDepth);
    final sigma = blur(depth) * w;
    if (sigma > 0.3) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      );
    } else {
      canvas.save();
    }
    canvas.translate(w / 2, h / 2);
    canvas.scale(v.scale);
    canvas.translate(-w / 2, -h / 2 + v.shift.dy * h);
    draw(v.shift.dx * w);
    canvas.restore();
  }

  /// 某层里的矩形（像素，未平移）落在画框上的位置，用来在屏幕坐标里裁剪。
  Rect toScreen(Rect rect, LayerView v) {
    final w = size.width;
    final h = size.height;
    Offset map(Offset p) {
      final q = v.project(Offset(p.dx / w, p.dy / h));
      return Offset(q.dx * w, q.dy * h);
    }

    return Rect.fromPoints(map(rect.topLeft), map(rect.bottomRight));
  }
}

/// 画人物身后的场景：天空、远景、中景、脚下的地面细节。人物和前景另外画。
void paintSketchScene(SketchPen pen, SketchCameraArgs args) {
  final SketchCameraArgs(:size, :look, :colors, :camera, :hasCharacters) = args;
  final w = size.width;
  final h = size.height;
  final groundY = sceneHorizon * h;
  final outdoor = look.kind != SceneKind.indoor && look.kind != SceneKind.vehicle;

  // 纸底（夜景是夜空）铺满画框，不跟镜头走
  pen.canvas.drawRect(Offset.zero & size, Paint()..color = colors.paper);
  if (look.night && outdoor) {
    camera.layer(SceneDepth.sky, (shift) => _paintNightSky(pen, w, h, colors, shift));
  }
  if (outdoor) {
    // 地面画在远景层：地平线离得远，运镜时几乎不动
    camera.layer(SceneDepth.far, (_) {
      pen.canvas.drawRect(
        Rect.fromLTRB(-w, groundY, 2 * w, 3 * h),
        Paint()..color = colors.faint(0.06),
      );
    });
  }

  switch (look.kind) {
    case SceneKind.street:
      _paintStreet(pen, camera, w, h, groundY, colors, night: look.night);
    case SceneKind.station:
      _paintStation(pen, camera, w, h, groundY, colors, night: look.night);
    case SceneKind.indoor:
      _paintIndoor(pen, camera, w, h, colors, night: look.night);
    case SceneKind.nature:
      _paintNature(pen, camera, w, h, groundY, colors);
    case SceneKind.vehicle:
      _paintVehicle(pen, camera, w, h, colors, night: look.night);
    case SceneKind.screen || SceneKind.open:
      _paintOpen(pen, camera, w, h, groundY, colors);
  }
  // 没有人物的屏幕镜头：画一部手机占住画面中心，放在人物平面上
  if (look.kind == SceneKind.screen && !hasCharacters) {
    camera.layer(SceneDepth.subject, (_) => _paintPhone(pen, w, h, colors));
  }
}

/// 画在人物前面的遮挡物：近处的柱子、枝叶、盆栽，停在画框边上。
/// 推镜时它们先冲出画框，移镜时划过得最快，是远近感最明显的一层。
void paintSketchForeground(SketchPen pen, SketchCameraArgs args) {
  final SketchCameraArgs(:size, :look, :colors, :camera) = args;
  final w = size.width;
  final h = size.height;
  final fill = Color.lerp(colors.fill, colors.ink, 0.12)!;
  // 让平铺里正好有一件东西停在 [x0]：_tiles 的位置按间距取模，加上这个相位即可
  Iterable<double> at(double x0, double spacing, double shift) =>
      _tiles(w, spacing, shift + x0 + w).map((tile) => tile.$1);

  switch (look.kind) {
    case SceneKind.street:
      camera.layer(SceneDepth.foreground, (shift) {
        for (final x in at(-w * 0.05, w * 1.5, shift)) {
          pen.rect(Rect.fromLTWH(x, -h, w * 0.09, 3 * h), fill: fill, scale: 1.6);
          pen.rect(Rect.fromLTWH(x + w * 0.04, h * 0.06, w * 0.13, h * 0.07), fill: colors.fill);
        }
      });
    case SceneKind.station:
      camera.layer(SceneDepth.foreground, (shift) {
        for (final x in at(w * 0.92, w * 1.5, shift)) {
          pen.rect(Rect.fromLTWH(x, -h, w * 0.14, 3 * h), fill: fill, scale: 1.6);
          pen.line(Offset(x, h * 0.3), Offset(x + w * 0.14, h * 0.3), scale: 0.8);
        }
      });
    case SceneKind.indoor:
      camera.layer(SceneDepth.foreground, (shift) {
        for (final x in at(-w * 0.04, w * 1.4, shift)) {
          // 盆栽：花盆加几片叶子
          pen.shape([
            Offset(x, h * 0.86),
            Offset(x + w * 0.2, h * 0.86),
            Offset(x + w * 0.17, h * 1.1),
            Offset(x + w * 0.03, h * 1.1),
          ], fill: fill);
          for (final (dx, top) in const [(0.02, 0.62), (0.1, 0.56), (0.18, 0.64)]) {
            final base = Offset(x + w * 0.1, h * 0.86);
            final tip = Offset(x + w * dx * 1.6 - w * 0.04, h * top);
            final mid = (base + tip) / 2;
            final side = Offset(w * 0.035, 0);
            pen.shape([base, mid - side, tip, mid + side], fill: colors.fill, scale: 0.9);
          }
        }
      });
    case SceneKind.nature:
      camera.layer(SceneDepth.foreground, (shift) {
        for (final x in at(w * 0.78, w * 1.6, shift)) {
          // 右上角垂下来的树枝
          final from = Offset(x + w * 0.4, -h * 0.02);
          final to = Offset(x, h * 0.12);
          pen.line(from, to, scale: 1.8);
          for (var i = 0; i < 4; i++) {
            final p = Offset.lerp(from, to, 0.2 + i * 0.22)!;
            pen.circle(p + Offset(0, h * 0.03), w * 0.045, fill: fill, scale: 0.9);
          }
        }
        for (final x in at(-w * 0.03, w * 1.2, shift)) {
          _grassClump(pen, Offset(x, h * 1.0), w, h, height: 0.12);
        }
      });
    case SceneKind.open:
      camera.layer(SceneDepth.foreground, (shift) {
        for (final x in at(-w * 0.03, w * 1.3, shift)) {
          _grassClump(pen, Offset(x, h * 1.0), w, h, height: 0.09);
        }
      });
    case SceneKind.vehicle || SceneKind.screen:
      break;
  }
}

/// 绘制场景要用的参数，几个绘制函数共用。
class SketchCameraArgs {
  const SketchCameraArgs({
    required this.size,
    required this.look,
    required this.colors,
    required this.camera,
    required this.hasCharacters,
  });

  final Size size;
  final SceneLook look;
  final SketchColors colors;
  final SceneCamera camera;
  final bool hasCharacters;
}

void _grassClump(SketchPen pen, Offset base, double w, double h, {required double height}) {
  for (var i = 0; i < 5; i++) {
    final x = base.dx + w * 0.035 * i;
    pen.stroke([
      Offset(x, base.dy),
      Offset(x + w * (0.01 + 0.012 * (i % 2)), base.dy - h * height * (0.6 + 0.1 * (i % 3))),
      Offset(x + w * 0.03, base.dy),
    ], scale: 1.1);
  }
}

/// 平铺：从世界左边铺到右边，随 [shift] 平移。返回 x 坐标和一个不随平移变化的编号，
/// 元素的样子（楼高、墙上挂什么）按编号定，平移跨过一个间距时不会跳变。
/// 每次返回的个数固定，保证笔触取随机数的次数每帧一致。
Iterable<(double, int)> _tiles(double w, double spacing, double shift) sync* {
  final count = (3 * w / spacing).ceil() + 4;
  final base = (shift / spacing).floor();
  final start = -w - spacing * 2 + (shift - base * spacing);
  for (var i = 0; i < count; i++) {
    yield (start + i * spacing, i - base);
  }
}

void _paintNightSky(SketchPen pen, double w, double h, SketchColors colors, double shift) {
  final moon = Offset(w * 0.78 + shift, h * 0.13);
  pen.circle(moon, w * 0.07, fill: colors.fill, color: colors.ink);
  final starPaint = Paint()..color = colors.ink.withValues(alpha: 0.6);
  for (var i = 0; i < 14; i++) {
    final x = (i * 0.37 % 1) * w * 1.6 - w * 0.3 + shift;
    final y = (i * 0.53 % 1) * h * 0.35;
    pen.canvas.drawCircle(Offset(x, y), w * 0.004, starPaint);
  }
}

void _paintStreet(
  SketchPen pen,
  SceneCamera camera,
  double w,
  double h,
  double groundY,
  SketchColors colors, {
  required bool night,
}) {
  // 远处的楼：带窗格，夜里有几扇亮着
  camera.layer(SceneDepth.far, (shift) {
    for (final (x, k) in _tiles(w, w * 0.26, shift)) {
      final height = h * (0.2 + 0.12 * ((k * 37) % 5).abs() / 4);
      final building = Rect.fromLTWH(x, groundY - height, w * 0.2, height);
      pen.rect(building, fill: colors.fill);
      for (var row = 0; row < 3; row++) {
        for (var col = 0; col < 2; col++) {
          final window = Rect.fromLTWH(
            building.left + w * (0.03 + col * 0.08),
            building.top + h * (0.03 + row * 0.055),
            w * 0.05,
            h * 0.03,
          );
          final lit = night && (k + row + col) % 3 != 0;
          pen.rect(
            window,
            fill: lit ? SketchColors.lamp.withValues(alpha: 0.85) : null,
            scale: 0.6,
          );
        }
      }
    }
  });
  // 人行道边线和路灯
  camera.layer(SceneDepth.mid, (shift) {
    pen.line(Offset(-w, groundY + h * 0.05), Offset(2 * w, groundY + h * 0.05));
    for (final (x, _) in _tiles(w, w * 0.7, shift)) {
      final top = Offset(x, groundY - h * 0.28);
      pen.line(Offset(x, groundY + h * 0.06), top, scale: 1.2);
      pen.stroke(
        SketchPen.arc(top + Offset(w * 0.05, 0), w * 0.05, math.pi, math.pi * 1.5, points: 6),
      );
      if (night) {
        pen.canvas.drawCircle(
          top + Offset(w * 0.1, h * 0.01),
          w * 0.12,
          Paint()..color = SketchColors.lamp.withValues(alpha: 0.18),
        );
      }
    }
  });
  // 脚下的路面虚线
  camera.layer(SceneDepth.subject, (shift) {
    for (final (x, _) in _tiles(w, w * 0.3, shift)) {
      pen.line(Offset(x, groundY + h * 0.2), Offset(x + w * 0.14, groundY + h * 0.2), scale: 1.3);
    }
  });
}

void _paintStation(
  SketchPen pen,
  SceneCamera camera,
  double w,
  double h,
  double groundY,
  SketchColors colors, {
  required bool night,
}) {
  final roofY = groundY - h * 0.34;
  // 雨棚：顶棚一条长线、立柱、悬挂的站牌
  camera.layer(SceneDepth.mid, (shift) {
    pen.rect(Rect.fromLTRB(-w, roofY - h * 0.025, 2 * w, roofY), fill: colors.fill);
    for (final (x, _) in _tiles(w, w * 0.55, shift)) {
      pen.line(Offset(x, roofY), Offset(x, groundY + h * 0.04), scale: 1.2);
      final sign = Rect.fromLTWH(x + w * 0.12, roofY + h * 0.03, w * 0.22, h * 0.05);
      pen.rect(
        sign,
        fill: night ? SketchColors.lamp.withValues(alpha: 0.6) : colors.fill,
        scale: 0.8,
      );
      pen.line(
        sign.centerLeft + Offset(w * 0.03, 0),
        sign.centerRight - Offset(w * 0.03, 0),
        scale: 0.6,
      );
    }
  });
  // 长椅，比立柱近一点
  camera.layer(1.3, (shift) {
    for (final (x, _) in _tiles(w, w * 1.1, shift)) {
      final seat = Rect.fromLTWH(x + w * 0.3, groundY - h * 0.05, w * 0.3, h * 0.02);
      pen.rect(seat, fill: colors.fill);
      pen.line(seat.bottomLeft + Offset(w * 0.03, 0), seat.bottomLeft + Offset(w * 0.03, h * 0.05));
      pen.line(
        seat.bottomRight - Offset(w * 0.03, 0),
        seat.bottomRight + Offset(-w * 0.03, h * 0.05),
      );
    }
  });
  // 站台边缘和警示线
  camera.layer(SceneDepth.subject, (shift) {
    pen.line(Offset(-w, groundY + h * 0.08), Offset(2 * w, groundY + h * 0.08), scale: 1.3);
    for (final (x, _) in _tiles(w, w * 0.12, shift)) {
      pen.line(
        Offset(x, groundY + h * 0.065),
        Offset(x + w * 0.06, groundY + h * 0.065),
        color: SketchColors.lamp,
        scale: 1.4,
      );
    }
  });
}

void _paintIndoor(
  SketchPen pen,
  SceneCamera camera,
  double w,
  double h,
  SketchColors colors, {
  required bool night,
}) {
  final floorY = h * 0.68;
  // 墙和墙脚线：窗户（夜里是深色）、门、挂画交替出现
  camera.layer(SceneDepth.mid, (shift) {
    pen.canvas.drawRect(
      Rect.fromLTRB(-w, floorY, 2 * w, 3 * h),
      Paint()..color = colors.faint(0.07),
    );
    pen.line(Offset(-w, floorY), Offset(2 * w, floorY), scale: 1.2);
    for (final (x, k) in _tiles(w, w * 0.55, shift)) {
      switch (k % 3) {
        case 0:
          final window = Rect.fromLTWH(x, h * 0.2, w * 0.3, h * 0.2);
          pen.rect(window, fill: night ? const Color(0xFF262B3A) : colors.fill);
          pen.line(window.topCenter, window.bottomCenter, scale: 0.8);
          pen.line(window.centerLeft, window.centerRight, scale: 0.8);
        case 1:
          final door = Rect.fromLTWH(x, floorY - h * 0.36, w * 0.24, h * 0.36);
          pen.rect(door, fill: colors.fill);
          pen.circle(door.centerRight - Offset(w * 0.04, 0), w * 0.012);
        default:
          final frame = Rect.fromLTWH(x + w * 0.04, h * 0.24, w * 0.18, h * 0.12);
          pen.rect(frame, fill: colors.fill, scale: 0.9);
          pen.stroke([
            frame.bottomLeft + Offset(w * 0.02, -h * 0.02),
            frame.center,
            frame.bottomRight - Offset(w * 0.02, h * 0.02),
          ], scale: 0.6);
      }
    }
  });
  // 地板缝，从墙脚往镜头这边斜出来
  camera.layer(SceneDepth.subject, (shift) {
    for (final (x, _) in _tiles(w, w * 0.25, shift)) {
      pen.line(Offset(x, floorY + h * 0.04), Offset(x - w * 0.12, h * 1.2), scale: 0.6);
    }
  });
}

void _paintNature(
  SketchPen pen,
  SceneCamera camera,
  double w,
  double h,
  double groundY,
  SketchColors colors,
) {
  // 远山：一条起伏的线
  camera.layer(SceneDepth.far, (shift) {
    pen.stroke([
      for (var i = 0; i <= 24; i++)
        Offset(-w + i * w / 8 + shift, groundY - h * (0.08 + 0.06 * math.sin(i * 1.3).abs())),
    ]);
  });
  // 树：树干加一团树冠
  camera.layer(SceneDepth.mid, (shift) {
    for (final (x, _) in _tiles(w, w * 0.4, shift)) {
      pen.line(Offset(x, groundY + h * 0.02), Offset(x, groundY - h * 0.14), scale: 1.3);
      pen.circle(Offset(x, groundY - h * 0.19), w * 0.09, fill: colors.fill);
    }
  });
  // 脚下的草
  camera.layer(SceneDepth.subject, (shift) {
    for (final (x, _) in _tiles(w, w * 0.09, shift)) {
      pen.stroke([
        Offset(x, groundY + h * 0.14),
        Offset(x + w * 0.01, groundY + h * 0.11),
        Offset(x + w * 0.02, groundY + h * 0.14),
      ], scale: 0.7);
    }
  });
}

void _paintVehicle(
  SketchPen pen,
  SceneCamera camera,
  double w,
  double h,
  SketchColors colors, {
  required bool night,
}) {
  // 摄影机在车里：内饰跟着机位走，只有窗外的景物在动
  const interior = 0.9;
  final window = Rect.fromLTWH(w * 0.08, h * 0.14, w * 0.84, h * 0.34);
  camera.layer(interior, attached: true, (_) {
    pen.canvas.drawRect(window, Paint()..color = night ? const Color(0xFF262B3A) : colors.fill);
  });
  final canvas = pen.canvas;
  canvas.save();
  canvas.clipRect(camera.toScreen(window, camera.view(interior, attached: true)));
  // 窗外：横向按很近的深度划得快，推镜时按远景缩放
  camera.layer(0.4, scaleDepth: SceneDepth.far, (shift) {
    for (final (x, _) in _tiles(w, w * 0.22, shift)) {
      pen.line(Offset(x, window.top + h * 0.22), Offset(x, window.top + h * 0.08), scale: 0.8);
      pen.line(
        Offset(x - w * 0.05, window.top + h * 0.16),
        Offset(x + w * 0.1, window.top + h * 0.16),
        scale: 0.5,
      );
    }
  });
  canvas.restore();
  camera.layer(interior, attached: true, (_) {
    pen.rect(window, scale: 1.4);
    // 车顶、仪表台
    pen.line(Offset(-w, h * 0.1), Offset(2 * w, h * 0.1), scale: 1.2);
    pen.shape([
      Offset(-w, h * 0.62),
      Offset(w * 0.2, h * 0.56),
      Offset(w * 0.8, h * 0.56),
      Offset(2 * w, h * 0.62),
      Offset(2 * w, 2 * h),
      Offset(-w, 2 * h),
    ], fill: colors.faint(0.08));
  });
}

void _paintOpen(
  SketchPen pen,
  SceneCamera camera,
  double w,
  double h,
  double groundY,
  SketchColors colors,
) {
  camera.layer(SceneDepth.far, (shift) {
    pen.line(Offset(-w, groundY), Offset(2 * w, groundY));
    for (final (x, k) in _tiles(w, w * 0.24, shift)) {
      final height = h * (0.06 + 0.06 * ((k * 7) % 5).abs() / 4);
      pen.rect(Rect.fromLTWH(x, groundY - height, w * 0.14, height), fill: colors.fill, scale: 0.8);
    }
  });
  camera.layer(SceneDepth.subject, (shift) {
    for (final (x, _) in _tiles(w, w * 0.2, shift)) {
      pen.line(Offset(x, groundY + h * 0.09), Offset(x + w * 0.07, groundY + h * 0.09), scale: 0.8);
    }
  });
}

void _paintPhone(SketchPen pen, double w, double h, SketchColors colors) {
  final phone = Rect.fromCenter(center: Offset(w / 2, h * 0.47), width: w * 0.56, height: h * 0.52);
  pen.canvas.drawRRect(
    RRect.fromRectAndRadius(phone, Radius.circular(w * 0.06)),
    Paint()..color = colors.fill,
  );
  pen.rect(phone, scale: 1.6);
  pen.line(
    phone.topCenter + Offset(-w * 0.06, h * 0.02),
    phone.topCenter + Offset(w * 0.06, h * 0.02),
  );
  // 两个消息气泡
  final left = Rect.fromLTWH(phone.left + w * 0.05, phone.top + h * 0.12, w * 0.3, h * 0.07);
  final right = Rect.fromLTWH(phone.right - w * 0.35, phone.top + h * 0.24, w * 0.3, h * 0.07);
  pen.rect(left, fill: colors.faint(0.08));
  pen.rect(right, fill: colors.accent.withValues(alpha: 0.25));
  for (final bubble in [left, right]) {
    pen.line(
      bubble.centerLeft + Offset(w * 0.03, -h * 0.01),
      bubble.centerRight - Offset(w * 0.05, h * 0.01),
      scale: 0.6,
    );
    pen.line(
      bubble.centerLeft + Offset(w * 0.03, h * 0.015),
      bubble.center + Offset(0, h * 0.015),
      scale: 0.6,
    );
  }
}

/// 雨丝和雪花，画在画框坐标里（不跟运镜走），随时间落下。数量固定。
void paintWeather(Canvas canvas, Size size, SceneLook look, SketchColors colors, int elapsedMs) {
  final w = size.width;
  final h = size.height;
  final seconds = elapsedMs / 1000;
  if (look.rain) {
    final paint = Paint()
      ..color = colors.ink.withValues(alpha: 0.35)
      ..strokeWidth = math.max(1, w * 0.004)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final x = (i * 0.618 % 1) * w * 1.2 - w * 0.1;
      final y = ((i * 0.37 % 1) + seconds * 1.4) % 1 * (h * 1.1) - h * 0.05;
      canvas.drawLine(Offset(x, y), Offset(x - w * 0.02, y + h * 0.045), paint);
    }
  }
  if (look.snow) {
    final paint = Paint()..color = colors.ink.withValues(alpha: 0.45);
    for (var i = 0; i < 40; i++) {
      final x = (i * 0.618 % 1) * w + math.sin(seconds * 2 + i) * w * 0.02;
      final y = ((i * 0.37 % 1) + seconds * 0.25) % 1 * h;
      canvas.drawCircle(Offset(x, y), w * 0.008, paint);
    }
  }
}
