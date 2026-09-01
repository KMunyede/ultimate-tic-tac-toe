// lib/widgets/board/clay_bevel_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';

class ClayBevelPainter extends CustomPainter {
  final double borderRadius;
  final Color baseColor;
  final String themeName;
  final double tiltX, tiltY;

  ClayBevelPainter({
    required this.borderRadius,
    required this.baseColor,
    required this.themeName,
    this.tiltX = 0,
    this.tiltY = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // CARTOON ENGINE: Sharp edges, no blurs, bold 3px black strokes
    final Paint fillPaint = Paint()..color = baseColor;
    canvas.drawRRect(rrect, fillPaint);

    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRRect(rrect, borderPaint);

    // Dynamic sharp highlights based on tilt
    final double highlightOpacity = (0.2 + (tiltY - tiltX) * 0.4).clamp(0.1, 0.5);
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: highlightOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final Path highlightPath = Path()
      ..moveTo(borderRadius, 6)
      ..lineTo(size.width - borderRadius, 6)
      ..moveTo(6, borderRadius)
      ..lineTo(6, size.height - borderRadius);
    canvas.drawPath(highlightPath, highlightPaint);

    canvas.save();
    canvas.clipRRect(rrect);

    final Random rand = Random(themeName.hashCode);

    if (themeName == 'Amazon Jungle') {
      final Paint grainPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      for (double i = 20; i < size.width; i += 40) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), grainPaint);
      }
      final Paint knotPaint = Paint()..color = Colors.black.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), 15, knotPaint);
      canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), 10, knotPaint);
    }

    if (themeName == 'Pacific Waves') {
      final int numPoles = 5;
      final double poleWidth = size.width / numPoles;
      final Paint linePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..strokeWidth = 2.0;
      for (int i = 1; i < numPoles; i++) {
        canvas.drawLine(Offset(i * poleWidth, 0), Offset(i * poleWidth, size.height), linePaint);
      }
      final Paint ropePaint = Paint()..color = const Color(0xFF7A5218);
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.12, size.width, 12), ropePaint);
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.85, size.width, 12), ropePaint);
    }

    if (themeName == 'River Flow') {
      final Paint wavePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      for (double y = 30; y < size.height; y += 60) {
        final Path wave = Path()
          ..moveTo(0, y)
          ..quadraticBezierTo(size.width * 0.25, y - 12, size.width * 0.5, y)
          ..quadraticBezierTo(size.width * 0.75, y + 12, size.width, y);
        canvas.drawPath(wave, wavePaint);
      }
    }

    if (themeName == 'Drifting Cloud') {
      final Paint stonePaint = Paint()..color = Colors.black.withValues(alpha: 0.08)..style = PaintingStyle.stroke..strokeWidth = 2.0;
      for (int i = 0; i < 6; i++) {
        final double sx = rand.nextDouble() * size.width;
        final double sy = rand.nextDouble() * size.height;
        canvas.drawOval(Rect.fromCenter(center: Offset(sx, sy), width: 40, height: 25), stonePaint);
      }
    }

    if (themeName == 'Crimson Leaf') {
      final Paint leafPaint = Paint()..color = Colors.black.withValues(alpha: 0.1);
      for (int i = 0; i < 8; i++) {
        final double lx = rand.nextDouble() * size.width;
        final double ly = rand.nextDouble() * size.height;
        canvas.save();
        canvas.translate(lx, ly);
        canvas.rotate(rand.nextDouble() * pi);
        canvas.drawOval(Rect.fromLTWH(-10, -15, 20, 30), leafPaint);
        canvas.restore();
      }
    }

    if (themeName.contains('Studio Pro')) {
      final Paint proPaint = Paint()..color = Colors.black.withValues(alpha: 0.05);
      for (int i = 0; i < 12; i++) {
        final double px = rand.nextDouble() * size.width;
        final double py = rand.nextDouble() * size.height;
        canvas.drawRect(Rect.fromLTWH(px, py, 4, 4), proPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(ClayBevelPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.themeName != themeName ||
      oldDelegate.tiltX != tiltX ||
      oldDelegate.tiltY != tiltY;
}
