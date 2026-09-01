// lib/widgets/arcade/arcade_painters.dart
import 'dart:math';
import 'package:flutter/material.dart';

class LedGridPainter extends CustomPainter {
  final bool isLight;
  const LedGridPainter({this.isLight = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paintDot = Paint()
      ..color = isLight ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const double scanHeight = 2.0;
    for (double y = 0; y < size.height; y += scanHeight * 1.5) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, scanHeight), paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant LedGridPainter oldDelegate) => oldDelegate.isLight != isLight;
}

class HexScrewPainter extends CustomPainter {
  final bool isLight;
  HexScrewPainter({required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isLight ? 0.25 : 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + 1), radius, shadowPaint);

    final rimPaint = Paint()
      ..shader = RadialGradient(
        colors: isLight
            ? [Colors.grey.shade300, Colors.grey.shade500]
            : [const Color(0xFF555562), const Color(0xFF22222A)],
        center: const Alignment(-0.2, -0.2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 0.5, rimPaint);

    final hexPaint = Paint()
      ..color = isLight ? Colors.grey.shade800 : const Color(0xFF0F0F12)
      ..style = PaintingStyle.fill;

    final hexPath = Path();
    final double hexRadius = radius * 0.45;
    for (int i = 0; i < 6; i++) {
      final double angle = i * pi / 3;
      final double x = center.dx + cos(angle) * hexRadius;
      final double y = center.dy + sin(angle) * hexRadius;
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, hexPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 1.5),
      -2.2,
      1.0,
      false,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant HexScrewPainter oldDelegate) => oldDelegate.isLight != isLight;
}
