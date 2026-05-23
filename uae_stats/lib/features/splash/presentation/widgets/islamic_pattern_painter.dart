// lib/features/splash/presentation/widgets/islamic_pattern_painter.dart
//
// Renders a subtle Islamic geometric lattice pattern using CustomPainter.
// Used on the Splash Screen and Hero cards at ~8% white opacity.
// Pattern: repeating 8-pointed star grid (common in Islamic architecture).

import 'dart:math';
import 'package:flutter/material.dart';

class IslamicPatternPainter extends CustomPainter {
  const IslamicPatternPainter({
    this.color = Colors.white,
    this.strokeWidth = 0.8,
    this.cellSize = 36.0,
  });

  final Color color;
  final double strokeWidth;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final half = cellSize / 2;
    final inset = cellSize * 0.18;

    // Draw a grid of overlapping squares rotated 45°
    // producing the classic Islamic lattice effect.
    for (double x = -cellSize; x < size.width + cellSize; x += half) {
      for (double y = -cellSize; y < size.height + cellSize; y += half) {
        final cx = x + (((y / half).round() % 2 == 0) ? 0 : half / 2);
        _drawStar(canvas, paint, Offset(cx, y), cellSize * 0.38, inset);
      }
    }
  }

  void _drawStar(
    Canvas canvas,
    Paint paint,
    Offset center,
    double outerR,
    double innerOffset,
  ) {
    final innerR = outerR * 0.42;
    const points = 8;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Small square at center for depth
    final sq = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.6;

    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: innerR * 0.9,
        height: innerR * 0.9,
      ),
      sq,
    );
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.strokeWidth != strokeWidth;
}
