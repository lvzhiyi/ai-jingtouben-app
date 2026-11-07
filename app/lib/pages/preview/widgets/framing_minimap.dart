import 'package:flutter/material.dart';

import '../../../data/models/shot_size.dart';
import '../preview_motion.dart';
import '../sketch/sketch_scene.dart';

/// 景别小图：一个全身人形，上面套一个框，标出这个景别拍到身体的哪一部分。
///
/// 主画面再抽象，这张图也能把「中景截到腰、近景截到胸」讲清楚。
class FramingMinimap extends StatelessWidget {
  const FramingMinimap({super.key, required this.size, required this.colors});

  final ShotSize size;
  final SketchColors colors;

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white);
    return Semantics(
      label: '景别示意：${size.label}，${framingHint(size)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x80000000),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.paper,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CustomPaint(
                      painter: FramingMinimapPainter(
                        window: framingWindow(framingFor(size)),
                        ink: colors.ink,
                        accent: colors.accent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ExcludeSemantics(child: Text(framingHint(size), style: label)),
            ],
          ),
        ),
      ),
    );
  }
}

class FramingMinimapPainter extends CustomPainter {
  const FramingMinimapPainter({required this.window, required this.ink, required this.accent});

  /// 人体坐标里的取景框（见 [framingWindow]）。
  final Rect window;
  final Color ink;
  final Color accent;

  /// 人体在人体坐标里占的范围：头顶 0 到脚底 1，左右各约 0.2。
  static const body = Rect.fromLTRB(-0.2, 0, 0.2, 1);

  @override
  void paint(Canvas canvas, Size size) {
    // 把人体和取景框一起缩放进小图；取景框比人大很多时人会很小，正好说明是远景
    final bounds = body.expandToInclude(window).inflate(0.06);
    final scale = (size.width / bounds.width) < (size.height / bounds.height)
        ? size.width / bounds.width
        : size.height / bounds.height;
    canvas.translate(
      (size.width - bounds.width * scale) / 2 - bounds.left * scale,
      (size.height - bounds.height * scale) / 2 - bounds.top * scale,
    );
    canvas.scale(scale);

    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 / scale
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(0, 0.06), 0.06, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-0.15, 0.135, 0.15, 0.56),
        const Radius.circular(0.04),
      ),
      stroke,
    );
    canvas.drawLine(const Offset(-0.06, 0.56), const Offset(-0.07, 1), stroke);
    canvas.drawLine(const Offset(0.06, 0.56), const Offset(0.07, 1), stroke);

    canvas.drawRect(window, Paint()..color = accent.withValues(alpha: 0.22));
    canvas.drawRect(
      window,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 / scale,
    );
  }

  @override
  bool shouldRepaint(FramingMinimapPainter oldDelegate) =>
      oldDelegate.window != window || oldDelegate.ink != ink || oldDelegate.accent != accent;
}
