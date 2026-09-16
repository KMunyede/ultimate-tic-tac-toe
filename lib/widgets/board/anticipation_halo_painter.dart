// lib/widgets/board/anticipation_halo_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';

class AnticipationHaloPainter extends CustomPainter {
  final double pulse;
  final double hover;
  final String themeName;
  final Color activeColor;
  final double boardSize;

  final Paint _paint = Paint()..style = PaintingStyle.stroke;
  final Paint _innerPaint = Paint()..style = PaintingStyle.stroke;
  final Path _wobblePath = Path();

  AnticipationHaloPainter({
    required this.pulse,
    required this.hover,
    required this.themeName,
    required this.activeColor,
    required this.boardSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width * 0.3) + (pulse * 5.0 * (1.0 + hover));
    
    _paint
      ..color = activeColor.withValues(alpha: (0.1 + hover * 0.2) * (1.0 - pulse * 0.5))
      ..strokeWidth = 2.0 + hover * 2.0;

    if (themeName == 'Pacific Waves' || themeName == 'Drifting Cloud') {
      canvas.drawCircle(center, radius, _paint);
      _innerPaint
        ..color = _paint.color.withValues(alpha: _paint.color.a * 0.5)
        ..strokeWidth = _paint.strokeWidth;
      canvas.drawCircle(center, radius * 0.7, _innerPaint);
    } else if (themeName == 'Amazon Jungle' || themeName == 'Rushing Wind' || themeName == 'Crimson Leaf') {
      _wobblePath.reset();
      for (int i = 0; i <= 360; i += 10) {
        final double rad = i * pi / 180;
        final double wobble = sin(rad * 8) * 2.0 + cos(rad * 3) * 1.5;
        final double px = center.dx + cos(rad) * (radius + wobble);
        final double py = center.dy + sin(rad) * (radius + wobble);
        if (i == 0) {
          _wobblePath.moveTo(px, py);
        } else {
          _wobblePath.lineTo(px, py);
        }
      }
      _wobblePath.close();
      canvas.drawPath(_wobblePath, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnticipationHaloPainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.hover != hover;
}
