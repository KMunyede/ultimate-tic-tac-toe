// lib/widgets/board/marker_drawings.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'painter_utils.dart';

class MarkerDrawings {
  static void draw3DMetallicX(Canvas canvas, Size size, Color baseColor, double progress) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double s = size.width * 0.35 * progress;
    final double thickness = size.width * 0.12;

    final Paint metallicPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF03A9F4), // Light Blue
          const Color(0xFF01579B), // Deep Blue
          const Color(0xFF0288D1), // Mid Blue
        ],
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: s * 2.5, height: s * 2.5));

    final Paint bevelPaint = Paint()
      ..color = const Color(0xFFECEFF1).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    void drawArm(double angle) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: s * 2, height: thickness);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(rrect, metallicPaint);
      canvas.drawRRect(rrect, bevelPaint);
      canvas.restore();
    }

    drawArm(pi / 4);
    drawArm(-pi / 4);
  }

  static void draw3DCeramicO(Canvas canvas, Size size, Color baseColor, double progress) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double outerRadius = size.width * 0.35 * progress;
    final double innerRadius = outerRadius * 0.6;

    final Rect rect = Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius);

    final Paint ceramicPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF), // Highlight
          const Color(0xFFECEFF1), // Base
          const Color(0xFFB0BEC5), // Shadow
        ],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(rect);

    final Path torusPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: outerRadius))
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: innerRadius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(torusPath, ceramicPaint);

    // Subtle edge shine
    final Paint shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), outerRadius, shinePaint);
  }

  static void drawStarfish(Canvas canvas, Size size, Color color, double progress) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width * 0.4 * progress;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Path path = Path();
    const int points = 5;
    for (int i = 0; i < points * 2; i++) {
      final double angle = i * pi / points;
      final double r = i.isEven ? radius : radius * 0.4;
      // Add wobbly organic feel to the points
      final double wobble = sin(angle * 10) * (radius * 0.05);
      final double px = cx + cos(angle - pi / 2) * (r + wobble);
      final double py = cy + sin(angle - pi / 2) * (r + wobble);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.quadraticBezierTo(
          cx + cos(angle - pi / points - pi / 2) * (r * 0.5),
          cy + sin(angle - pi / points - pi / 2) * (r * 0.5),
          px, py
        );
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Add suction cup dots if progress is significant
    if (progress > 0.8) {
      final Paint dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
      for (int i = 0; i < points; i++) {
        final double angle = i * 2 * pi / points;
        for (double d = 0.3; d < 0.9; d += 0.2) {
          final double px = cx + cos(angle - pi / 2) * (radius * d);
          final double py = cy + sin(angle - pi / 2) * (radius * d);
          canvas.drawCircle(Offset(px, py), radius * 0.04, dotPaint);
        }
      }
    }
  }

  static void drawClamshell(Canvas canvas, Size size, Color color, double progress) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double radius = size.width * 0.4 * progress;
    
    final Paint shellPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Fan shape path
    final Path path = Path();
    path.moveTo(cx, cy + radius * 0.8); // Hinge at bottom
    
    // Top arc of the shell
    final Rect rect = Rect.fromCenter(center: Offset(cx, cy), width: radius * 2, height: radius * 1.6);
    path.arcTo(rect, -pi * 0.9, pi * 1.8, false);
    path.close();
    
    canvas.drawPath(path, shellPaint);

    // Radial ribs
    if (progress > 0.5) {
      final Paint ribPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      for (double angle = -pi * 0.8; angle <= pi * 0.8; angle += pi * 0.2) {
        canvas.drawLine(
          Offset(cx, cy + radius * 0.8),
          Offset(cx + cos(angle - pi/2) * radius, cy + sin(angle - pi/2) * radius * 0.8),
          ribPaint
        );
      }
    }
    
    // Highlight on top
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawArc(rect.deflate(2), -pi * 0.8, pi * 1.6, false, highlightPaint);
  }

  static void drawThemedLine(Canvas canvas, Offset p1, Offset p2, String themeName, Color baseColor, double strokeWidth) {
    if (themeName == 'Pacific Waves') {
      final paintGlow = Paint()..color = baseColor.withValues(alpha: 0.45)..strokeWidth = strokeWidth * 1.4..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyLine(canvas, p1, p2, paintGlow);
      final paintCore = Paint()..color = baseColor.withValues(alpha: 0.95)..strokeWidth = strokeWidth * 0.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyLine(canvas, p1, p2, paintCore);
      final paintHighlight = Paint()..color = Colors.white..strokeWidth = strokeWidth * 0.22..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyLine(canvas, p1, p2, paintHighlight);
    } else if (themeName == 'Amazon Jungle') {
      final paintShadow = Paint()..color = const Color(0xFF1B0F0D).withValues(alpha: 0.65)..strokeWidth = strokeWidth * 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyLine(canvas, Offset(p1.dx + 2.0, p1.dy + 3.0), Offset(p2.dx + 2.0, p2.dy + 3.0), paintShadow);
      final paintStone = Paint()..color = const Color(0xFFCFD8DC)..strokeWidth = strokeWidth * 1.3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyLine(canvas, p1, p2, paintStone);
      final paintHighlight = Paint()..color = Colors.white.withValues(alpha: 0.8)..strokeWidth = strokeWidth * 0.22..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyLine(canvas, Offset(p1.dx - 1.0, p1.dy - 1.0), Offset(p2.dx - 1.0, p2.dy - 1.0), paintHighlight);
    } else if (themeName == 'Crimson Leaf') {
      PainterUtils.drawCalligraphicLine(canvas, p1, p2, baseColor, strokeWidth);
    } else {
      PainterUtils.drawBristleStroke(canvas, p1, p2, baseColor, strokeWidth);
    }
  }

  static void drawThemedArc(Canvas canvas, Rect rect, double start, double sweep, String themeName, Color baseColor, double strokeWidth) {
    if (themeName == 'Pacific Waves') {
      final paintGlow = Paint()..color = baseColor.withValues(alpha: 0.45)..strokeWidth = strokeWidth * 1.4..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyArc(canvas, rect, start, sweep, paintGlow);
      final paintCore = Paint()..color = baseColor.withValues(alpha: 0.95)..strokeWidth = strokeWidth * 0.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyArc(canvas, rect, start, sweep, paintCore);
    } else if (themeName == 'Amazon Jungle') {
      final paintShadow = Paint()..color = const Color(0xFF1B0F0D).withValues(alpha: 0.65)..strokeWidth = strokeWidth * 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyArc(canvas, rect.translate(2.0, 3.0), start, sweep, paintShadow);
      final paintVine = Paint()..color = const Color(0xFF4CAF50)..strokeWidth = strokeWidth * 1.3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyArc(canvas, rect, start, sweep, paintVine);
      final paintHighlight = Paint()..color = const Color(0xFFA5D6A7)..strokeWidth = strokeWidth * 0.22..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      PainterUtils.drawWobblyArc(canvas, rect.translate(-1.0, -1.0), start, sweep, paintHighlight);
    } else if (themeName == 'Crimson Leaf') {
      PainterUtils.drawCalligraphicArc(canvas, rect, start, sweep, baseColor, strokeWidth);
    } else {
      PainterUtils.drawBristleArc(canvas, rect, start, sweep, baseColor, strokeWidth);
    }
  }
}
