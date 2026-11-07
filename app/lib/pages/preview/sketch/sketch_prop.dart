import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/prop_drawing.dart';
import '../preview_motion.dart';
import 'sketch_pen.dart';
import 'sketch_scene.dart';

/// 生成道具的笔：每个道具单独一支，种子按道具名。
/// 占位方块换成画好的道具时，取随机数的次数变了，但只影响这支笔，画面上其他线条不跟着抖。
SketchPen propPen(
  Canvas canvas,
  String name, {
  required SketchColors colors,
  required double scale,
}) => SketchPen(
  canvas,
  seed: nameHash(name),
  ink: colors.ink,
  width: math.max(1.0, scale * 0.012),
  jitter: scale * 0.006,
);

/// 把模型生成的绘图画进 [rect]（道具的 0–1 方框）。填充五档映射到预演配色。
void paintPropDrawing(Canvas canvas, PropDrawing drawing, Rect rect, SketchColors colors) {
  final pen = propPen(canvas, drawing.name, colors: colors, scale: rect.height);
  Offset at(Offset p) => Offset(rect.left + p.dx * rect.width, rect.top + p.dy * rect.height);
  Color? fill(PropFill f) => switch (f) {
    PropFill.none => null,
    PropFill.light => colors.fill,
    PropFill.mid => Color.lerp(colors.fill, colors.ink, 0.25),
    PropFill.dark => Color.lerp(colors.fill, colors.ink, 0.7),
    PropFill.accent => colors.accent.withValues(alpha: 0.55),
  };
  for (final shape in drawing.shapes) {
    switch (shape) {
      case PropPath(:final points, :final closed, fill: final f):
        final mapped = [for (final p in points) at(p)];
        if (closed) {
          pen.shape(mapped, fill: fill(f));
        } else {
          pen.stroke(mapped);
        }
      case PropEllipse(:final center, :final width, :final height, fill: final f):
        pen.shape(
          SketchPen.ellipse(
            Rect.fromCenter(
              center: at(center),
              width: width * rect.width,
              height: height * rect.height,
            ),
          ),
          fill: fill(f),
        );
      case PropArc(:final center, :final radius, :final start, :final end):
        pen.stroke(
          SketchPen.arc(
            at(center),
            radius * rect.width,
            start * math.pi / 180,
            end * math.pi / 180,
          ),
        );
    }
  }
}

/// 还没画好或生成失败的道具：一个手绘方块，中间写道具名。
void paintPropPlaceholder(Canvas canvas, String name, Rect rect, SketchColors colors) {
  final pen = propPen(canvas, name, colors: colors, scale: rect.height);
  pen.rect(rect, fill: colors.fill.withValues(alpha: 0.85), scale: 0.8);
  pen.line(
    rect.topLeft + Offset(rect.width * 0.12, rect.height * 0.12),
    rect.topLeft + Offset(rect.width * 0.3, rect.height * 0.12),
    scale: 0.6,
  );
  final fontSize = (rect.height * 0.24).clamp(9.0, 22.0);
  final text = TextPainter(
    text: TextSpan(
      text: name,
      style: TextStyle(color: colors.ink, fontSize: fontSize, height: 1.1),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: rect.width * 0.9);
  text.paint(canvas, rect.center - Offset(text.width / 2, text.height / 2));
  text.dispose();
}
