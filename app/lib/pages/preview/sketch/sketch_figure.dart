import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../figure_pose.dart';
import 'sketch_pen.dart';
import 'sketch_scene.dart';

/// 头部在屏幕上大于这个直径（像素）时画五官：近景以上才看得清脸。
const faceDetailMinPx = 36.0;

/// 手绘木偶人：胸腔、骨盆两块躯干，手脚是两头粗细不同的体块，关节处是圆球。
/// 衣服用角色色淡彩，头发和五官区分角色；姿态、视线和道具来自 [action] 和 [skeleton]。
///
/// 坐标：[headTop] 站立时头顶的 y，[height] 身高（都是像素）；[turn] 脸往哪边转（-1–1）。
void paintSketchFigure(
  SketchPen pen, {
  required double centerX,
  required double headTop,
  required double height,
  required Color tint,
  required SketchColors colors,
  required bool longHair,
  required FigureAction action,
  required Skeleton skeleton,
  double turn = 0,
}) {
  Offset at(Offset body) => Offset(centerX + body.dx * height, headTop + body.dy * height);
  double size(double body) => body * height;

  final clothes = Color.lerp(colors.fill, tint, 0.55)!;
  final trousers = Color.lerp(colors.fill, tint, 0.3)!;
  final joint = colors.fill;
  final away = action.facingAway;
  final s = skeleton;

  // 两个关节之间的体块：两头半径不同的四边形，再在远端补一个关节球
  void limb(Offset from, Offset to, double r1, double r2, Color fill) {
    final a = at(from);
    final b = at(to);
    final d = b - a;
    final length = d.distance;
    final n = length == 0 ? Offset.zero : Offset(-d.dy / length, d.dx / length);
    pen.shape([a + n * size(r1), b + n * size(r2), b - n * size(r2), a - n * size(r1)], fill: fill);
  }

  if (s.seat case final seat?) {
    pen.rect(Rect.fromPoints(at(seat.topLeft), at(seat.bottomRight)), fill: colors.faint(0.12));
  }

  // 腿：大腿、膝盖球、小腿、脚
  for (final (hip, knee, foot) in [(s.hipL, s.kneeL, s.footL), (s.hipR, s.kneeR, s.footR)]) {
    limb(hip, knee, 0.04, 0.03, trousers);
    limb(knee, foot, 0.03, 0.022, trousers);
    pen.circle(at(knee), size(0.03), fill: joint, scale: 0.8);
    pen.shape(
      SketchPen.ellipse(
        Rect.fromCenter(center: at(foot), width: size(0.07), height: size(0.035)),
        points: 10,
      ),
      fill: Color.lerp(colors.ink, colors.fill, 0.4),
      scale: 0.8,
    );
  }

  // 骨盆、腰球、胸腔
  final hipY = (s.hipL.dy + s.hipR.dy) / 2;
  pen.shape([
    at(Offset(-0.085, hipY - 0.13)),
    at(Offset(0.085, hipY - 0.13)),
    at(Offset(0.075, hipY + 0.03)),
    at(Offset(-0.075, hipY + 0.03)),
  ], fill: trousers);
  pen.circle(at(Offset(0, s.waistY + 0.012)), size(0.032), fill: joint, scale: 0.8);
  pen.shape([
    at(s.shoulderL + const Offset(0.02, -0.012)),
    at(s.shoulderR + const Offset(-0.02, -0.012)),
    at(s.shoulderR + const Offset(0.012, 0.03)),
    at(Offset(0.075, s.waistY - 0.01)),
    at(Offset(-0.075, s.waistY - 0.01)),
    at(s.shoulderL + const Offset(-0.012, 0.03)),
  ], fill: clothes);
  if (!away) {
    // 领口
    pen.stroke([
      at(s.neck + const Offset(-0.035, 0.01)),
      at(s.neck + const Offset(0, 0.05)),
      at(s.neck + const Offset(0.035, 0.01)),
    ], scale: 0.7);
  }

  // 手臂：肩球、上臂、肘球、前臂、手
  for (final (shoulder, elbow, hand) in [
    (s.shoulderL, s.elbowL, s.handL),
    (s.shoulderR, s.elbowR, s.handR),
  ]) {
    pen.circle(at(shoulder), size(0.032), fill: clothes, scale: 0.8);
    limb(shoulder, elbow, 0.028, 0.022, clothes);
    limb(elbow, hand, 0.022, 0.017, clothes);
    pen.circle(at(elbow), size(0.022), fill: joint, scale: 0.7);
    pen.circle(at(hand), size(0.021), fill: joint, scale: 0.8);
  }

  if (action.props.phone) {
    final phone = Rect.fromCenter(
      center: at(s.handR + const Offset(-0.005, -0.03)),
      width: size(0.05),
      height: size(0.08),
    );
    pen.rect(phone, fill: Color.lerp(colors.ink, colors.fill, 0.2));
    // 屏幕的光
    pen.canvas.drawRect(
      phone.deflate(size(0.008)),
      Paint()..color = SketchColors.lamp.withValues(alpha: 0.7),
    );
  }

  final shape = action.props.umbrella ? umbrellaShape(s) : null;
  if (shape != null) {
    // 伞杆和伞柄弯钩，画在头之前：伞杆在脸外侧
    pen.line(at(Offset(shape.apex.dx, s.handL.dy + 0.05)), at(shape.apex), scale: 1.1);
    pen.stroke(
      SketchPen.arc(
        at(Offset(shape.apex.dx + 0.015, s.handL.dy + 0.05)),
        size(0.015),
        0,
        math.pi,
        points: 4,
      ),
      scale: 1.1,
    );
  }

  // 脖子和头
  limb(s.neck, s.head + const Offset(0, 0.04), 0.02, 0.02, joint);
  _paintHead(
    pen,
    center: at(s.head),
    r: size(Skeleton.headRadius),
    colors: colors,
    tint: tint,
    longHair: longHair,
    action: action,
    turn: turn,
  );

  if (shape != null) {
    final apex = at(shape.apex);
    final rimY = headTop + shape.rimY * height;
    final half = size(shape.halfWidth);
    final canopy = action.props.darkUmbrella
        ? Color.lerp(colors.ink, colors.fill, 0.15)!
        : Color.lerp(colors.fill, tint, 0.25)!;
    // 伞面：半个椭圆，下沿是几段小弧
    final dome = SketchPen.arc(Offset(apex.dx, rimY), 1, math.pi, 2 * math.pi, points: 10)
        .map(
          (p) => Offset(apex.dx + (p.dx - apex.dx) * half, rimY + (p.dy - rimY) * (rimY - apex.dy)),
        )
        .toList();
    pen.shape(dome, fill: canopy);
    for (var i = 0; i < 4; i++) {
      pen.line(apex, Offset(apex.dx - half + half * 2 * (i + 0.5) / 4, rimY), scale: 0.5);
    }
  }
}

/// 头、头发和五官。背影只画头发；回头时脸转到一侧，只露一只眼睛和鼻尖。
void _paintHead(
  SketchPen pen, {
  required Offset center,
  required double r,
  required SketchColors colors,
  required Color tint,
  required bool longHair,
  required FigureAction action,
  required double turn,
}) {
  final hidden = action.gaze == FigureGaze.hidden;
  final skin = hidden ? Color.lerp(colors.fill, colors.ink, 0.55)! : colors.fill;
  final hair = Color.lerp(colors.ink, tint, 0.15)!.withValues(alpha: 0.9);
  pen.circle(center, r, fill: skin);

  if (action.pose == FigurePose.back) {
    // 背影：头发盖住整个后脑，长发垂到肩
    pen.shape([
      if (longHair) center + Offset(-r * 1.05, r * 1.5),
      ...SketchPen.arc(center, r * 1.06, math.pi * 0.7, math.pi * 2.3, points: 14),
      if (longHair) center + Offset(r * 1.05, r * 1.5),
    ], fill: hair);
    return;
  }
  if (action.pose == FigurePose.turnBack) {
    // 回头：脸朝 turn 那侧，后脑和下巴后面都是头发；长发从后脑垂到肩
    final face = turn >= 0 ? 0.0 : math.pi;
    if (longHair) {
      pen.shape([
        center + Offset(-turn * r * 0.2, 0),
        center + Offset(-turn * r * 1.05, r * 0.2),
        center + Offset(-turn * r * 0.9, r * 1.5),
        center + Offset(turn * r * 0.2, r * 1.4),
      ], fill: hair);
    }
    pen.shape([
      ...SketchPen.arc(center, r * 1.06, face + math.pi * 0.35, face + math.pi * 1.65, points: 12),
      center + Offset(turn * r * 0.3, 0),
    ], fill: hair);
    if (r * 2 >= faceDetailMinPx) {
      final eye = center + Offset(turn * r * 0.62, r * 0.05);
      pen.canvas.drawOval(
        Rect.fromCenter(center: eye, width: r * 0.12, height: r * 0.2),
        Paint()..color = colors.ink,
      );
      pen.stroke([
        center + Offset(turn * r * 0.9, r * 0.15),
        center + Offset(turn * r * 1.04, r * 0.38),
        center + Offset(turn * r * 0.88, r * 0.42),
      ], scale: 0.6);
    }
    return;
  }

  // 正面的头发：盖住头顶，长发两侧垂到下巴以下
  final hairStart = longHair ? math.pi * 0.8 : math.pi * 0.95;
  final hairEnd = longHair ? math.pi * 2.2 : math.pi * 2.05;
  final fringe = [
    center + Offset(r * 0.9, -r * 0.05),
    center + Offset(r * 0.3, -r * 0.45),
    center + Offset(-r * 0.4, -r * 0.35),
    center + Offset(-r * 0.9, -r * 0.05),
  ];
  pen.shape([
    if (longHair) center + Offset(-r * 1.05, r * 1.3),
    ...SketchPen.arc(center, r * 1.06, hairStart, hairEnd, points: 14),
    if (longHair) center + Offset(r * 1.05, r * 1.3),
    if (longHair) center + Offset(r * 0.8, r * 0.1),
    ...fringe,
    if (longHair) center + Offset(-r * 0.8, r * 0.1),
  ], fill: hair);

  // 五官只在脸够大时画，看不清脸时不画。按人物本身的大小判断、不看推镜缩放，同一镜里不会中途变化。
  if (hidden || r * 2 < faceDetailMinPx) return;
  // 转头时五官整体往那侧挪；抬头往上、低头往下
  final tilt = switch (action.gaze) {
    FigureGaze.up => -0.16,
    FigureGaze.down => 0.2,
    _ => 0.0,
  };
  final shift = Offset(turn * r * 0.3, tilt * r);
  final eyePaint = Paint()..color = colors.ink;
  for (final side in [-1, 1]) {
    final eye = center + shift + Offset(side * r * 0.36 * (1 - turn.abs() * 0.25), r * 0.08);
    if (action.gaze == FigureGaze.down) {
      // 低头：眼睛垂下来，画成一道弧
      pen.stroke(
        SketchPen.arc(eye, r * 0.1, math.pi * 0.15, math.pi * 0.85, points: 4),
        scale: 0.7,
      );
    } else {
      final pupil = action.gaze == FigureGaze.up ? Offset(0, -r * 0.04) : Offset.zero;
      pen.canvas.drawOval(
        Rect.fromCenter(center: eye + pupil, width: r * 0.16, height: r * 0.2),
        eyePaint,
      );
    }
    pen.line(eye + Offset(-r * 0.16, -r * 0.24), eye + Offset(r * 0.16, -r * 0.27), scale: 0.7);
    // 耳朵：转头时只剩背向那侧的一只
    if (turn == 0 || side == -turn.sign) {
      final earStart = side > 0 ? -math.pi / 2 : math.pi / 2;
      pen.stroke(
        SketchPen.arc(
          center + Offset(side * r * 0.98, r * 0.12),
          r * 0.16,
          earStart,
          earStart + math.pi,
          points: 4,
        ),
        scale: 0.6,
      );
    }
  }
  pen.stroke([
    center + shift + Offset(r * 0.02 + turn * r * 0.12, r * 0.2),
    center + shift + Offset(-r * 0.06 + turn * r * 0.2, r * 0.42),
    center + shift + Offset(r * 0.06, r * 0.45),
  ], scale: 0.6);
  pen.stroke(
    SketchPen.arc(
      center + shift + Offset(0, r * 0.38),
      r * 0.26,
      math.pi * 0.25,
      math.pi * 0.75,
      points: 5,
    ),
    scale: 0.7,
  );
}

/// 远景、全景时脚下的影子，用几道斜线排出来。
void paintSketchShadow(
  SketchPen pen, {
  required double centerX,
  required double feet,
  required double height,
}) {
  final width = height * 0.4;
  for (var i = 0; i < 5; i++) {
    final x = centerX - width / 2 + width * i / 4;
    pen.line(
      Offset(x - height * 0.02, feet + height * 0.03),
      Offset(x + height * 0.03, feet),
      scale: 0.5,
    );
  }
}
