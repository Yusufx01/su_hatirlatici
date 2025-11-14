import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final double shimmer;
  final bool isDarkTheme;

  ProgressRingPainter({
    required this.progress,
    required this.shimmer,
    required this.isDarkTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final strokeWidth = size.width * 0.085;
    final rect = Offset.zero & size;

    final basePaint = Paint()
        ..color = (isDarkTheme
          ? Colors.white.withOpacity( 0.08)
          : Colors.white.withOpacity( 0.25))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -pi / 2,
      2 * pi,
      false,
      basePaint,
    );

    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: -pi / 2 + 2 * pi * clampedProgress,
      colors: isDarkTheme
          ? [
              const Color(0xFF3BC9DB),
              const Color(0xFF1C7ED6),
              const Color(0xFF15AABF),
            ]
          : [
              const Color(0xFF1FA2FF),
              const Color(0xFF12D8FA),
              const Color(0xFFA6FFCB),
            ],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -pi / 2,
      2 * pi * clampedProgress,
      false,
      progressPaint,
    );

    final innerRadius = (size.width / 2) - strokeWidth * 1.25;
    final innerPaint = Paint()
        ..color = isDarkTheme
          ? const Color(0xFF0E1821).withOpacity( 0.92)
          : Colors.white.withOpacity( 0.88)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(rect.center, innerRadius, innerPaint);

    final shimmerAngle = (-pi / 2) + (2 * pi * clampedProgress * shimmer);
    final shimmerRadius = (size.width / 2) - strokeWidth / 2;
    final shimmerOffset = Offset(
      rect.center.dx + shimmerRadius * cos(shimmerAngle),
      rect.center.dy + shimmerRadius * sin(shimmerAngle),
    );

    final shimmerPaint = Paint()
      ..color = Colors.white.withOpacity( isDarkTheme ? 0.28 : 0.4)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 6);

    canvas.drawCircle(shimmerOffset, strokeWidth * 0.4, shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.isDarkTheme != isDarkTheme;
  }
}
