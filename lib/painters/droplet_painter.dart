import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/droplet.dart';

class DropletPainter extends CustomPainter {
  final List<Droplet> droplets;
  final bool isDark;

  DropletPainter(this.droplets, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isDark ? Colors.white : Colors.lightBlueAccent;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 6);

    for (final droplet in droplets) {
      final opacity = (isDark ? 0.10 + droplet.speed * 0.4 : 0.18 + droplet.speed * 0.45).clamp(0.08, 0.35);
      paint.color = baseColor.withOpacity(opacity);
      canvas.drawCircle(
        Offset(droplet.x * size.width, droplet.y * size.height),
        droplet.size + 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DropletPainter oldDelegate) => true;
}
