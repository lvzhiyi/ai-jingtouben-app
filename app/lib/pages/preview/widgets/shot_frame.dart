import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/shot_draft.dart';
import '../../../data/models/shot_duration.dart';
import '../figure_pose.dart';
import '../preview_motion.dart';
import '../sketch/sketch_figure.dart';
import '../sketch/sketch_pen.dart';
import '../sketch/sketch_scene.dart';
import 'framing_minimap.dart';

/// 一个镜头的示意画面（9:16），手绘分镜风格：场景、人物、运镜和天气，
/// 叠上取景参照、景别小图、镜头信息、画面描述、字幕，每镜开头淡入并显示「镜头 n」。
///
/// [progress] 是镜头内进度（0–1），每帧变化；文字用普通组件叠在画面上，跟随系统字号。
class ShotFrame extends StatelessWidget {
  const ShotFrame({
    super.key,
    required this.shot,
    required this.position,
    required this.total,
    required this.progress,
    this.showScene = true,
  });

  final ShotDraft shot;

  /// 当前是第几个镜头（从 1 开始）和总数，用于角标。
  final int position;
  final int total;
  final double progress;
  final bool showScene;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final look = sceneLook(shot.scene, ignore: shot.characters);
    final colors = SketchColors.of(theme, night: look.night);
    final durationMs = shot.effectiveDurationMs;
    final elapsedMs = (progress * durationMs).round();
    final dialogue = shot.dialogue.runes.toList();
    final visible = visibleSubtitleChars(
      elapsedMs: elapsedMs,
      durationMs: durationMs,
      length: dialogue.length,
    );
    final fade = shotFadeIn(elapsedMs);
    final title = titleCardOpacity(elapsedMs);
    const shadow = [Shadow(blurRadius: 6, color: Color(0x99000000))];
    final overlay = theme.textTheme.bodySmall?.copyWith(color: Colors.white, shadows: shadow);
    final moveLabel = '${shot.shotSize.label} · ${shot.cameraMove.label}';
    final camera = cameraTransform(shot.cameraMove, progress);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: ShotFramePainter(
              shot: shot,
              progress: progress,
              elapsedMs: elapsedMs,
              look: look,
              colors: colors,
            ),
          ),
          CustomPaint(
            painter: CameraGuidePainter(
              hint: cameraHint(shot.cameraMove),
              progress: progress,
              color: colors.accent,
              lines: colors.ink,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _Caption(child: Text('镜头 $position / $total · $moveLabel', style: overlay)),
          ),
          // 角色名标签：跟着人物和运镜走，人物出画就不显示
          for (final figure in placeFigures(shot.shotSize, shot.characters))
            if (nameLabelAnchor(figure, camera) case final anchor?)
              Align(
                alignment: Alignment(anchor.dx * 2 - 1, anchor.dy * 2 - 1),
                child: _Caption(
                  dense: true,
                  child: Text(
                    figure.name,
                    style: overlay?.copyWith(
                      color: Color.lerp(
                        Colors.white,
                        characterColor(figure.name, dark: true),
                        0.35,
                      ),
                    ),
                  ),
                ),
              ),
          Positioned(
            top: 52,
            right: 12,
            child: FramingMinimap(size: shot.shotSize, colors: colors),
          ),
          if (showScene)
            Positioned(
              top: 52,
              left: 12,
              right: 92,
              child: Align(
                alignment: Alignment.topLeft,
                child: _Caption(
                  child: Text(
                    shot.scene,
                    style: overlay,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          // 还没出字时不显示字幕底，避免一个空的黑条
          if (visible > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Center(
                child: _Caption(
                  child: Text(
                    String.fromCharCodes(dialogue.take(visible)),
                    key: const ValueKey('preview-subtitle'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      shadows: shadow,
                    ),
                  ),
                ),
              ),
            ),
          if (title > 0)
            Center(
              child: Opacity(
                opacity: title,
                child: _Caption(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '镜头 $position',
                        style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                      ),
                      Text(moveLabel, style: overlay),
                    ],
                  ),
                ),
              ),
            ),
          if (fade < 1)
            IgnorePointer(
              child: ColoredBox(color: Colors.black.withValues(alpha: 1 - fade)),
            ),
        ],
      ),
    );
  }
}

/// 叠在画面上的文字底：白字垫一层半透明深色，任何背景上都看得清。
class _Caption extends StatelessWidget {
  const _Caption({required this.child, this.dense = false});

  final Widget child;

  /// 角色名这类短标签用更小的内边距。
  final bool dense;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0x80000000),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: child),
  );
}

/// 画场景、人物和天气。构图和运镜的数值来自 `preview_motion.dart` 的纯函数。
class ShotFramePainter extends CustomPainter {
  const ShotFramePainter({
    required this.shot,
    required this.progress,
    required this.elapsedMs,
    required this.look,
    required this.colors,
  });

  final ShotDraft shot;
  final double progress;
  final int elapsedMs;
  final SceneLook look;
  final SketchColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final camera = cameraTransform(shot.cameraMove, progress);
    // 种子按镜头固定：同一镜每帧笔触一样，不同镜头各有各的手感
    final pen = SketchPen(
      canvas,
      seed: shot.index * 7919 + 13,
      ink: colors.ink,
      width: math.max(1.2, w * 0.006),
      jitter: w * 0.0035,
    );

    final args = SketchCameraArgs(
      size: size,
      look: look,
      colors: colors,
      camera: SceneCamera(canvas, size, camera, blur: (depth) => focusBlur(shot.shotSize, depth)),
      hasCharacters: shot.characters.isNotEmpty,
    );
    paintSketchScene(pen, args);
    final figures = placeFigures(shot.shotSize, shot.characters);
    final action = figureAction(shot.scene, ignore: shot.characters, count: figures.length);
    final skeleton = poseSkeleton(action, seconds: elapsedMs / 1000);
    args.camera.layer(SceneDepth.subject, subject: true, (shift) {
      for (final figure in figures) {
        final framing = figure.framing;
        final centerX = figure.centerX * w + shift;
        final height = framing.figureHeight * h;
        // 坐下时上身下沉；画框截在身上的景别（中景、近景）把人往上提，头还在原来的位置
        final lift = action.pose == FigurePose.sit && framing.visibleBodyRatio < 1
            ? sitDrop * height
            : 0.0;
        final headTop = (framing.headTop + camera.figureBob) * h - lift;
        if (framing.visibleBodyRatio >= 1) {
          paintSketchShadow(pen, centerX: centerX, feet: headTop + height, height: height);
        }
        paintSketchFigure(
          pen,
          centerX: centerX,
          headTop: headTop,
          height: height,
          tint: characterColor(figure.name, dark: colors.dark),
          colors: colors,
          longHair: characterLongHair(figure.name),
          action: action,
          skeleton: skeleton,
          turn: headTurn(action, centerX: figure.centerX),
        );
      }
    });
    paintSketchForeground(pen, args);

    paintWeather(canvas, size, look, colors, elapsedMs);
  }

  @override
  bool shouldRepaint(ShotFramePainter oldDelegate) =>
      oldDelegate.shot != shot ||
      oldDelegate.progress != progress ||
      oldDelegate.elapsedMs != elapsedMs ||
      oldDelegate.look != look ||
      oldDelegate.colors != colors;
}

/// 取景参照：三分线、四角取景标记，推拉时标记往里收 / 往外放，摇移跟升降时有箭头划过。
/// 画在画框坐标里，不跟着运镜走，所以镜头往哪动一眼就能看出来。
class CameraGuidePainter extends CustomPainter {
  const CameraGuidePainter({
    required this.hint,
    required this.progress,
    required this.color,
    required this.lines,
  });

  final CameraHint hint;
  final double progress;

  /// 取景标记和箭头的颜色。
  final Color color;

  /// 三分线的颜色。
  final Color lines;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final eased = cameraEase(progress);

    final thirds = Paint()
      ..color = lines.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (final f in const [1 / 3, 2 / 3]) {
      canvas.drawLine(Offset(w * f, 0), Offset(w * f, h), thirds);
      canvas.drawLine(Offset(0, h * f), Offset(w, h * f), thirds);
    }

    final zoom = switch (hint.zoom) {
      1 => eased,
      -1 => 1 - eased,
      _ => 0.0,
    };
    final inset = w * (0.04 + 0.1 * zoom);
    final arm = w * 0.07;
    final corner = Paint()
      ..color = color.withValues(alpha: hint.zoom == 0 ? 0.35 : 0.8)
      ..strokeWidth = math.max(2, w * 0.007)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final box = Rect.fromLTRB(inset, inset * 16 / 9, w - inset, h - inset * 16 / 9);
    for (final (point, dx, dy) in [
      (box.topLeft, 1.0, 1.0),
      (box.topRight, -1.0, 1.0),
      (box.bottomLeft, 1.0, -1.0),
      (box.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(point.dx + dx * arm, point.dy)
          ..lineTo(point.dx, point.dy)
          ..lineTo(point.dx, point.dy + dy * arm),
        corner,
      );
    }

    final direction = hint.direction;
    if (direction == null) return;
    final arrow = Paint()
      ..strokeWidth = math.max(2.5, w * 0.009)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final center = Offset(w / 2, h / 2);
    final spacing = w * 0.08;
    final chevron = w * 0.035;
    final normal = Offset(-direction.dy, direction.dx);
    final phase = (progress * 4) % 1;
    for (var k = -1; k <= 1; k++) {
      final step = k + phase;
      final tip = center + direction * (step * spacing);
      // 越靠两头越淡，看起来像在往前流
      arrow.color = color.withValues(alpha: 0.85 * (1 - (step.abs() / 2).clamp(0.0, 1.0)));
      canvas.drawPath(
        Path()
          ..moveTo(
            (tip - direction * chevron + normal * chevron).dx,
            (tip - direction * chevron + normal * chevron).dy,
          )
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(
            (tip - direction * chevron - normal * chevron).dx,
            (tip - direction * chevron - normal * chevron).dy,
          ),
        arrow,
      );
    }
  }

  @override
  bool shouldRepaint(CameraGuidePainter oldDelegate) =>
      oldDelegate.hint.direction != hint.direction ||
      oldDelegate.hint.zoom != hint.zoom ||
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.lines != lines;
}
