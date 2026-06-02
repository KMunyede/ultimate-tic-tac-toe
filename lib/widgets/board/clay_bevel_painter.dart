// lib/widgets/board/clay_bevel_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
    final deflated = rrect.deflate(
        1.0); // Inset slightly to hug the inner curve perfectly

    // REACTIVE LIGHTING: Shift bevel intensities based on tilt
    // If we tilt towards the light (top-left), the highlight intensifies
    final double lightIntensity = (1.0 + (tiltY - tiltX) * 2.0).clamp(0.4, 1.5);
    final double darkIntensity = (1.0 - (tiltY - tiltX) * 2.0).clamp(0.4, 1.5);

    final paintLight = Paint()
      ..color = NeumorphicColors.getLightShadow(
          baseColor).withValues(alpha: (0.95 * lightIntensity).clamp(0.0, 1.0)) // Dynamic soft highlight catcher
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDark = Paint()
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(
          alpha: (0.65 * darkIntensity).clamp(0.0, 1.0)) // Deep sharp bevel shadow
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-Left Bevel Path (starts from bottom-left corner and travels around the curve to the top-right corner)
    final pathLight = Path()
      ..moveTo(deflated.left, deflated.bottom - deflated.blRadiusY)
      ..lineTo(deflated.left, deflated.top + deflated.tlRadiusY)
      ..quadraticBezierTo(
          deflated.left, deflated.top, deflated.left + deflated.tlRadiusX,
          deflated.top)
      ..lineTo(deflated.right - deflated.trRadiusX, deflated.top);

    // Bottom-Right Bevel Path (starts from top-right corner and travels around the curve to the bottom-left corner)
    final pathDark = Path()
      ..moveTo(deflated.right - deflated.trRadiusX, deflated.top)
      ..quadraticBezierTo(deflated.right, deflated.top, deflated.right,
          deflated.top + deflated.trRadiusY)
      ..lineTo(deflated.right, deflated.bottom - deflated.brRadiusY)
      ..quadraticBezierTo(
          deflated.right, deflated.bottom, deflated.right - deflated.brRadiusX,
          deflated.bottom)
      ..lineTo(deflated.left + deflated.blRadiusX, deflated.bottom)
      ..quadraticBezierTo(deflated.left, deflated.bottom, deflated.left,
          deflated.bottom - deflated.blRadiusY);

    // Draw realistic background and spotlight for Amazon Jungle
    canvas.save();
    canvas.clipRRect(rrect);

    if (themeName == 'Amazon Jungle') {
      // 1. Solid rich mahogany backing
      final Paint bgPaint = Paint()..color = baseColor;
      canvas.drawRect(rect, bgPaint);

      // 2. Concentric Tree Rings
      final Paint ringPaint = Paint()
        ..color = const Color(0x1F27120E) // Rich dark mahogany wood rings
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      final double nodeX = size.width * 0.15;
      final double nodeY = size.height * 0.20;
      
      for (int i = 1; i <= 10; i++) {
        final double radius = i * (size.width * 0.16);
        final Path ringPath = Path();
        
        for (int angleDeg = 0; angleDeg <= 360; angleDeg += 5) {
          final double angle = angleDeg * pi / 180;
          final double distortion = sin(angle * 6) * (radius * 0.04) + cos(angle * 3) * (radius * 0.02);
          final double r = radius + distortion;
          final double px = nodeX + cos(angle) * r;
          final double py = nodeY + sin(angle) * r;
          
          if (angleDeg == 0) {
            ringPath.moveTo(px, py);
          } else {
            ringPath.lineTo(px, py);
          }
        }
        canvas.drawPath(ringPath, ringPaint);
      }

      // 3. Subtle Wood Grains (Parallel vertical fibers)
      final Paint fiberPaint = Paint()
        ..color = const Color(0x0CFFFFFF) // Soft light fiber sheen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      
      for (double i = -size.width * 0.5; i < size.width * 1.5; i += 12.0) {
        final Path fiberPath = Path()
          ..moveTo(i, -10)
          ..cubicTo(i + 15, size.height * 0.3, i - 15, size.height * 0.7, i + 10, size.height + 10);
        canvas.drawPath(fiberPath, fiberPaint);
      }

      // 4. Gold Spotlight Glow
      final Paint spotlightPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            const Color(0x40FFF8E1), // Bright warm honey gold center
            const Color(0x15FFF8E1), // Fading warm halo
            Colors.transparent,      // Dissolves into forest shadow
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect)
        ..blendMode = BlendMode.srcOver;
      canvas.drawRect(rect, spotlightPaint);

      // 5. Raw Textured Tree Bark Outer Border
      final Paint barkPaint = Paint()
        ..color = const Color(0xFF27120E).withValues(alpha: 0.8)
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke;
      final Path barkPath = Path();
      
      for (int angleDeg = 0; angleDeg <= 360; angleDeg += 3) {
        final double angle = angleDeg * pi / 180;
        final double cx = size.width / 2;
        final double cy = size.height / 2;
        final double rx = size.width / 2 - 2.5;
        final double ry = size.height / 2 - 2.5;
        final double wobble = sin(angle * 32) * 1.4 + cos(angle * 12) * 0.8;
        final double px = cx + cos(angle) * (rx + wobble);
        final double py = cy + sin(angle) * (ry + wobble);
        
        if (angleDeg == 0) {
          barkPath.moveTo(px, py);
        } else {
          barkPath.lineTo(px, py);
        }
      }
      canvas.drawPath(barkPath, barkPaint);
    }

    canvas.restore();

    canvas.drawPath(pathLight, paintLight);
    canvas.drawPath(pathDark, paintDark);
  }

  @override
  bool shouldRepaint(ClayBevelPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
          oldDelegate.baseColor != baseColor ||
          oldDelegate.themeName != themeName ||
          oldDelegate.tiltX != tiltX ||
          oldDelegate.tiltY != tiltY;
}
