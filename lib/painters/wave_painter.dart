import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final double animationValue;
  final double fillLevel;
  final bool isDarkTheme;

  WavePainter({
    required this.animationValue,
    required this.fillLevel,
    required this.isDarkTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clampedFill = fillLevel.clamp(0.0, 1.0);
    final baseHeight = size.height * (1 - clampedFill);
    final waveHeight = 14 + (1 - clampedFill) * 12;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDarkTheme
            ? [const Color(0xFF15304A), const Color(0xFF1C5C86)]
            : [const Color(0xFF7ED8F5), const Color(0xFF1E88E5)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final primaryPath = Path()..moveTo(0, baseHeight);
    for (double x = 0; x <= size.width; x++) {
      final wave =
          waveHeight * sin(2 * pi * (x / size.width) + animationValue * 2 * pi);
      primaryPath.lineTo(x, wave + baseHeight);
    }
    primaryPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final secondaryPath = Path()..moveTo(0, baseHeight + 12);
    for (double x = 0; x <= size.width; x++) {
      final wave = (waveHeight * 0.6) *
          sin(2 * pi * ((x / size.width) + animationValue * 0.8));
      secondaryPath.lineTo(x, wave + baseHeight + 12);
    }
    secondaryPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity( isDarkTheme ? 0.08 : 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawPath(primaryPath, paint);
    canvas.drawPath(secondaryPath, highlightPaint);

    final foamPaint = Paint()
      ..color = Colors.white.withOpacity( 0.38)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    for (double x = 0; x <= size.width; x += 5) {
      final wave =
          waveHeight * sin(2 * pi * (x / size.width) + animationValue * 2 * pi);
      final y = wave + baseHeight;
      canvas.drawCircle(Offset(x, y), 1.6, foamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}
