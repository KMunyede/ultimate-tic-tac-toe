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
        themeName != 'Pacific Waves' &&
        themeName != 'Drifting Cloud' &&
        themeName != 'Crimson Leaf') {
      return; // only draw for nature themes!
    }

    final double w = size.width;
    final double h = size.height;

    // Calculate a normalized scaling factor based on standard 240px board widths
    final double scale = w / 240.0;
    
    // Gap between the 9 recessed squares
    final double gap = w * 0.035;
    
    // Cell dimension
    final double cellW = (w - (gap * 2)) / 3;
    final double radius = cellW * 0.2; // rounded corners for the debossed cells

    final double darkStrokeWidth = (4.5 * scale).clamp(2.0, 6.0);
    final double lightStrokeWidth = (4.0 * scale).clamp(1.5, 5.0);
    final double blurRadius = (3.5 * scale).clamp(1.0, 5.0);

    // REACTIVE LIGHTING: Shift crease offsets based on tilt
    final double shiftX = tiltY * 3.0;
    final double shiftY = -tiltX * 3.0;

    // 1. Dark inner shadow (inset top-left shadow)
    final paintDark = Paint()
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(alpha: 0.95) // Maximize opacity
      ..strokeWidth = darkStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius)
      ..style = PaintingStyle.stroke;

    // 2. Bright inner light catcher (inset bottom-right highlight)
    final paintLight = Paint()
      ..color = NeumorphicColors.getLightShadow(baseColor).withValues(alpha: 0.95)
      ..strokeWidth = lightStrokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius)
      ..style = PaintingStyle.stroke;

    // 3. Recessed fill
    final paintFill = Paint()
      ..color = (themeName == 'Pacific Waves' ? Colors.black : NeumorphicColors.getDarkShadow(baseColor)).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // 4. Subtle flat border to ensure visibility even if shadows fail
    final paintBorder = Paint()
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        // Tap area for this cell is exactly (w/3) by (h/3)
        // We inset the drawn rectangle by gap/2 on all sides so it perfectly centers in the tap area
        final double left = col * (w / 3) + gap / 2;
        final double top = row * (h / 3) + gap / 2;
        final double drawnCellW = (w / 3) - gap;
        final double drawnCellH = (h / 3) - gap;
        
        final rect = Rect.fromLTWH(left, top, drawnCellW, drawnCellH);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

        // Draw recessed background
        canvas.drawRRect(rrect, paintFill);
        
        // Draw hard border
        canvas.drawRRect(rrect, paintBorder);

        canvas.save();
        canvas.clipRRect(rrect);

        // Draw top-left dark inner shadow
        // We shift the rect slightly down-right and draw it with stroke, so its top-left edge falls inside the clip
        final Path darkPath = Path()
          ..addRRect(RRect.fromRectAndRadius(
            rect.translate(darkStrokeWidth * 0.5 + shiftX, darkStrokeWidth * 0.5 + shiftY), 
            Radius.circular(radius)
          ));
        canvas.drawPath(darkPath, paintDark);

        // Draw bottom-right light inner shadow
        // We shift the rect slightly up-left so its bottom-right edge falls inside the clip
        final Path lightPath = Path()
          ..addRRect(RRect.fromRectAndRadius(
            rect.translate(-lightStrokeWidth * 0.5 - shiftX, -lightStrokeWidth * 0.5 - shiftY), 
            Radius.circular(radius)
          ));
        canvas.drawPath(lightPath, paintLight);

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(DebossedGridPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
          oldDelegate.themeName != themeName ||
          oldDelegate.padding != padding ||
          oldDelegate.tiltX != tiltX ||
          oldDelegate.tiltY != tiltY;
}
