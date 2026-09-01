// lib/widgets/board/painter_utils.dart
import 'dart:math';
import 'package:flutter/material.dart';

class PainterUtils {
  static void drawWobblyLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double len = sqrt(dx * dx + dy * dy);
    if (len < 2) {
      canvas.drawLine(p1, p2, paint);
      return;
    }

    final int segments = (len / 6.0).clamp(4, 30).toInt();
    final path = Path();
    path.moveTo(p1.dx, p1.dy);

    final double px = -dy / len;
    final double py = dx / len;
    final random = Random(p1.dx.toInt() ^ p2.dy.toInt());

    for (int i = 1; i <= segments; i++) {
      final double ratio = i / segments;
      final double x = p1.dx + dx * ratio;
      final double y = p1.dy + dy * ratio;
      final double wobble = sin(ratio * pi * 5) * 0.9 + (random.nextDouble() - 0.5) * 0.6;
      path.lineTo(x + px * wobble, y + py * wobble);
    }
    canvas.drawPath(path, paint);
  }

  static void drawWobblyArc(Canvas canvas, Rect rect, double startAngle, double sweepAngle, Paint paint) {
    final double cx = rect.center.dx;
    final double cy = rect.center.dy;
    final double rx = rect.width / 2;
    final double ry = rect.height / 2;

    final int segments = (sweepAngle.abs() * 25).clamp(6, 60).toInt();
    final path = Path();

    final double firstAngle = startAngle;
    final double firstWobble = sin(firstAngle * 6) * 0.8;
    path.moveTo(cx + cos(firstAngle) * (rx + firstWobble), cy + sin(firstAngle) * (ry + firstWobble));

    final random = Random(rect.left.toInt() ^ rect.top.toInt());

    for (int i = 1; i <= segments; i++) {
      final double ratio = i / segments;
      final double angle = startAngle + sweepAngle * ratio;
      final double wobble = sin(angle * 7) * 0.9 + (random.nextDouble() - 0.5) * 0.5;
      path.lineTo(cx + cos(angle) * (rx + wobble), cy + sin(angle) * (ry + wobble));
    }
    canvas.drawPath(path, paint);
  }

  static void drawCalligraphicLine(Canvas canvas, Offset p1, Offset p2, Color color, double strokeWidth) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double len = sqrt(dx * dx + dy * dy);
    if (len < 2) return;

    final int segments = (len / 3.0).clamp(10, 45).toInt();
    final List<Offset> points = [p1];

    final double px = -dy / len;
    final double py = dx / len;
    final random = Random(p1.dx.toInt() ^ p2.dy.toInt());

    for (int i = 1; i <= segments; i++) {
      final double ratio = i / segments;
      final double x = p1.dx + dx * ratio;
      final double y = p1.dy + dy * ratio;
      final double wobble = sin(ratio * pi * 4) * 0.35 + (random.nextDouble() - 0.5) * 0.25;
      points.add(Offset(x + px * wobble, y + py * wobble));
    }

    for (int i = 0; i < points.length - 1; i++) {
      final double ratio = i / (points.length - 1);
      final double scale = 0.28 + sin(ratio * pi) * 1.15;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.95)
        ..strokeWidth = strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  static void drawCalligraphicArc(Canvas canvas, Rect rect, double startAngle, double sweepAngle, Color color, double strokeWidth) {
    final double cx = rect.center.dx;
    final double cy = rect.center.dy;
    final double rx = rect.width / 2;
    final double ry = rect.height / 2;

    const int segments = 50;
    final List<Offset> points = [];
    final random = Random(rect.left.toInt() ^ rect.top.toInt());

    for (int i = 0; i <= segments; i++) {
      final double ratio = i / segments;
      final double angle = startAngle + sweepAngle * ratio;
      final double wobble = sin(angle * 5) * 0.4 + (random.nextDouble() - 0.5) * 0.25;
      points.add(Offset(cx + cos(angle) * (rx + wobble), cy + sin(angle) * (ry + wobble)));
    }

    for (int i = 0; i < points.length - 1; i++) {
      final double ratio = i / (points.length - 1);
      final double scale = 0.32 + sin(ratio * pi) * 1.1;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.95)
        ..strokeWidth = strokeWidth * scale
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  static void drawBristleStroke(Canvas canvas, Offset p1, Offset p2, Color color, double strokeWidth) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double len = sqrt(dx * dx + dy * dy);
    if (len < 2) return;

    const int numBristles = 14;
    final random = Random(p1.dx.toInt() ^ p2.dy.toInt());

    for (int b = 0; b < numBristles; b++) {
      final path = Path();
      path.moveTo(p1.dx, p1.dy);
      final double bristleSpread = (random.nextDouble() - 0.5) * strokeWidth;
      final double bristleWidth = 1.0 + random.nextDouble() * 2.0;
      final double bristleAlpha = 0.3 + random.nextDouble() * 0.6;

      const int segments = 15;
      final double px = -dy / len;
      final double py = dx / len;

      for (int i = 1; i <= segments; i++) {
        final double ratio = i / segments;
        final double x = p1.dx + dx * ratio;
        final double y = p1.dy + dy * ratio;
        final double pressure = sin(ratio * pi);
        final double currentOffset = bristleSpread * pressure;
        path.lineTo(x + px * currentOffset, y + py * currentOffset);
      }
      final paint = Paint()..color = color.withValues(alpha: bristleAlpha)..strokeWidth = bristleWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }
  }

  static void drawBristleArc(Canvas canvas, Rect rect, double startAngle, double sweepAngle, Color color, double strokeWidth) {
    final double cx = rect.center.dx;
    final double cy = rect.center.dy;
    final double rx = rect.width / 2;
    final double ry = rect.height / 2;

    const int numBristles = 16;
    final random = Random(rect.left.toInt() ^ rect.top.toInt());

    for (int b = 0; b < numBristles; b++) {
      final path = Path();
      final double bristleSpread = (random.nextDouble() - 0.5) * strokeWidth;
      final double bristleWidth = 1.0 + random.nextDouble() * 2.0;
      final double bristleAlpha = 0.3 + random.nextDouble() * 0.6;

      const int segments = 30;
      path.moveTo(cx + cos(startAngle) * rx, cy + sin(startAngle) * ry);

      for (int i = 1; i <= segments; i++) {
        final double ratio = i / segments;
        final double angle = startAngle + sweepAngle * ratio;
        final double pressure = 0.3 + 0.7 * sin(ratio * pi);
        final double currentSpread = bristleSpread * pressure;
        path.lineTo(cx + cos(angle) * (rx + currentSpread), cy + sin(angle) * (ry + currentSpread));
      }
      final paint = Paint()..color = color.withValues(alpha: bristleAlpha)..strokeWidth = bristleWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      canvas.drawPath(path, paint);
    }
  }
}
