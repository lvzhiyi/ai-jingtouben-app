import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/shot_draft.dart';
import '../../../data/models/shot_duration.dart';
import '../preview_motion.dart';

/// 一个镜头的示意画面（9:16）：背景、人物剪影、运镜，叠上画面描述、镜头信息和字幕。
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
    final durationMs = shot.effectiveDurationMs;
    final dialogue = shot.dialogue.runes.toList();
    final visible = visibleSubtitleChars(
      elapsedMs: (progress * durationMs).round(),
      durationMs: durationMs,
      length: dialogue.length,
    );
    const shadow = [Shadow(blurRadius: 6, color: Color(0x99000000))];
    final overlay = theme.textTheme.bodySmall?.copyWith(color: Colors.white, shadows: shadow);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: ShotFramePainter(
              shot: shot,
              progress: progress,
              palette: FramePalette.of(theme),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0x66000000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  '镜头 $position / $total · ${shot.shotSize.label} · ${shot.cameraMove.label}',
                  style: overlay,
                ),
              ),
            ),
          ),
          if (showScene)
            Positioned(
              top: 48,
              left: 16,
              right: 16,
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
        ],
      ),
    );
  }
}

/// 叠在画面上的文字底：示意画面是浅色渐变，白字要垫一层半透明深色才看得清。
class _Caption extends StatelessWidget {
  const _Caption({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0x80000000),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: child),
  );
}

/// 示意画面用到的颜色，取自主题，深色模式自动跟随。
class FramePalette {
  const FramePalette({
    required this.skyTop,
    required this.skyBottom,
    required this.ground,
    required this.far,
    required this.dark,
  });

  factory FramePalette.of(ThemeData theme) {
    final scheme = theme.colorScheme;
    return FramePalette(
      skyTop: scheme.primaryContainer,
      skyBottom: scheme.surface,
      ground: scheme.surfaceContainerHighest,
      far: scheme.outlineVariant,
      dark: theme.brightness == Brightness.dark,
    );
  }

  final Color skyTop;
  final Color skyBottom;
  final Color ground;
  final Color far;
  final bool dark;

  @override
  bool operator ==(Object other) =>
      other is FramePalette &&
      other.skyTop == skyTop &&
      other.skyBottom == skyBottom &&
      other.ground == ground &&
      other.far == far &&
      other.dark == dark;

  @override
  int get hashCode => Object.hash(skyTop, skyBottom, ground, far, dark);
}

/// 画背景和人物剪影。构图和运镜的数值来自 `preview_motion.dart` 的纯函数。
class ShotFramePainter extends CustomPainter {
  const ShotFramePainter({required this.shot, required this.progress, required this.palette});

  final ShotDraft shot;
  final double progress;
  final FramePalette palette;

  /// 地平线高度（按画框高）。
  static const horizon = 0.62;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final camera = cameraTransform(shot.cameraMove, progress);

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.scale(camera.scale);
    canvas.translate(-w / 2 + camera.offset.dx * w, -h / 2 + camera.offset.dy * h);

    _paintBackground(canvas, w, h, camera.backgroundOffset * w);

    final framing = framingFor(shot.shotSize);
    final names = showsSingleFigure(shot.shotSize)
        ? shot.characters.take(1).toList()
        : shot.characters;
    for (var i = 0; i < names.length; i++) {
      final centerX = w * (i + 1) / (names.length + 1);
      _paintFigure(
        canvas,
        centerX: centerX,
        headTop: (framing.headTop + camera.figureBob) * h,
        height: framing.figureHeight * h,
        color: characterColor(names[i], dark: palette.dark),
        withFace: showsSingleFigure(shot.shotSize),
      );
    }
    canvas.restore();
  }

  /// 背景画得比画框大，运镜平移时不露边。
  void _paintBackground(Canvas canvas, double w, double h, double shift) {
    final bounds = Rect.fromLTRB(-w, -h, 2 * w, 2 * h);
    final groundY = horizon * h;
    canvas.drawRect(
      Rect.fromLTRB(bounds.left, bounds.top, bounds.right, groundY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.skyTop, palette.skyBottom],
        ).createShader(Rect.fromLTRB(0, 0, w, groundY)),
    );
    canvas.drawRect(
      Rect.fromLTRB(bounds.left, groundY, bounds.right, bounds.bottom),
      Paint()..color = palette.ground,
    );

    // 远景色块：楼和树的示意，背景平移时一起移动，让摇、移、跟看得出来
    final farPaint = Paint()..color = palette.far.withValues(alpha: 0.55);
    for (var i = -6; i <= 12; i++) {
      final x = i * w * 0.22 + shift * 0.6;
      final blockHeight = h * (0.08 + 0.06 * ((i * 7) % 5) / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, groundY - blockHeight, w * 0.14, blockHeight),
          Radius.circular(w * 0.02),
        ),
        farPaint,
      );
    }
    // 地面上的线：近处移动得更快，形成视差
    final linePaint = Paint()
      ..color = palette.far.withValues(alpha: 0.6)
      ..strokeWidth = math.max(1, w * 0.006);
    for (var i = -10; i <= 20; i++) {
      final x = i * w * 0.18 + shift;
      canvas.drawLine(
        Offset(x, groundY + h * 0.08),
        Offset(x + w * 0.06, groundY + h * 0.08),
        linePaint,
      );
    }
  }

  void _paintFigure(
    Canvas canvas, {
    required double centerX,
    required double headTop,
    required double height,
    required Color color,
    required bool withFace,
  }) {
    final paint = Paint()..color = color;
    final head = height * Framing.headRatio;
    final headCenter = Offset(centerX, headTop + head / 2);
    canvas.drawCircle(headCenter, head / 2, paint);

    final shoulders = height * 0.3;
    final torsoTop = headTop + head * 1.05;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - shoulders / 2, torsoTop, shoulders, height * 0.44),
        Radius.circular(shoulders * 0.3),
      ),
      paint,
    );
    final legWidth = height * 0.09;
    for (final side in [-1, 1]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX + side * legWidth * 0.7 - legWidth / 2,
            headTop + height * 0.55,
            legWidth,
            height * 0.45,
          ),
          Radius.circular(legWidth * 0.4),
        ),
        paint,
      );
    }

    if (withFace) {
      // 特写才看得清的眼睛，让人一眼认出是脸
      final eyePaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
      for (final side in [-1, 1]) {
        canvas.drawCircle(
          headCenter.translate(side * head * 0.18, -head * 0.04),
          head * 0.05,
          eyePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ShotFramePainter oldDelegate) =>
      oldDelegate.shot != shot ||
      oldDelegate.progress != progress ||
      oldDelegate.palette != palette;
}
