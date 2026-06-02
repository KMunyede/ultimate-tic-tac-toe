// lib/widgets/board/debossed_grid_painter.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DebossedGridPainter extends CustomPainter {
  final Color baseColor;
  final String themeName;
  final double padding;
  final double tiltX, tiltY;

  DebossedGridPainter({
    required this.baseColor,
    required this.themeName,
    required this.padding,
    this.tiltX = 0,
    this.tiltY = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (themeName != 'Rushing Wind' &&
        themeName != 'Amazon Jungle' &&
        themeName != 'Rising Moon' &&
        themeName != 'Drifting Cloud' &&
        themeName != 'Crimson Leaf') {
      return; // only draw for nature themes!
    }

    final double w = size.width;
    final double h = size.height;

    // Grid coordinates (exact cell boundaries)
    final double x1 = w / 3;
    final double x2 = 2 * w / 3;
    final double y1 = h / 3;
    final double y2 = 2 * h / 3;

    // Lines start slightly into the outer padding area to give the elegant carved cap look from the design mockup
    final double lineStart = -padding * 0.55;
    final double lineEndW = w + (padding * 0.55);
    final double lineEndH = h + (padding * 0.55);

    // Calculate a normalized scaling factor based on standard 240px board widths
    final double scale = w / 240.0;
    final double baseStrokeWidth = (5.2 * scale).clamp(1.2, 8.0);
    final double darkStrokeWidth = (2.0 * scale).clamp(0.6, 3.5);
    final double lightStrokeWidth = (1.6 * scale).clamp(0.5, 3.0);
    final double blurRadius = (1.2 * scale).clamp(0.3, 2.5);

    // REACTIVE LIGHTING: Shift crease offsets based on tilt
    final double shiftX = tiltY * 4.0;
    final double shiftY = -tiltX * 4.0;

    // Carved groove styling:
    // 1. Dark shadow crease (base layer to ground the groove depth)
    final paintBase = Paint()
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(alpha: 0.45) // Deepened crease
      ..strokeWidth = baseStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius); // Tighter blur for deeper look

    // 2. Dark inner shadow (inset top-left shadow)
    final paintDark = Paint()
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(alpha: 0.75) // Sharp dark inner shadow
      ..strokeWidth = darkStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 3. Bright inner light catcher (inset bottom-right highlight)
    final paintLight = Paint()
      ..color = NeumorphicColors.getLightShadow(baseColor).withValues(alpha: 0.45) // Softer nature highlight blend
      ..strokeWidth = lightStrokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawCarvedLine(Offset p1, Offset p2) {
      // Draw base dark crease
      canvas.drawLine(p1, p2, paintBase);

      // Draw dark shadow line (offset top-left, shifted by tilt)
      canvas.drawLine(
        Offset(p1.dx - 0.7 + shiftX, p1.dy - 0.7 + shiftY),
        Offset(p2.dx - 0.7 + shiftX, p2.dy - 0.7 + shiftY),
        paintDark,
      );

      // Draw light catching line (offset bottom-right, shifted opposite to tilt)
      canvas.drawLine(
        Offset(p1.dx + 0.7 - shiftX, p1.dy + 0.7 - shiftY),
        Offset(p2.dx + 0.7 - shiftX, p2.dy + 0.7 - shiftY),
        paintLight,
      );
    }

    // Horizontal lines
    drawCarvedLine(Offset(lineStart, y1), Offset(lineEndW, y1));
    drawCarvedLine(Offset(lineStart, y2), Offset(lineEndW, y2));

    // Vertical lines
    drawCarvedLine(Offset(x1, lineStart), Offset(x1, lineEndH));
    drawCarvedLine(Offset(x2, lineStart), Offset(x2, lineEndH));
  }

  @override
  bool shouldRepaint(DebossedGridPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
          oldDelegate.themeName != themeName ||
          oldDelegate.padding != padding ||
          oldDelegate.tiltX != tiltX ||
          oldDelegate.tiltY != tiltY;
}
