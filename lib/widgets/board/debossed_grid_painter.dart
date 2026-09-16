// lib/widgets/board/debossed_grid_painter.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DebossedGridPainter extends CustomPainter {
  final Color baseColor;
  final String themeName;
  final double padding;
  final double tiltX, tiltY;

  final Paint _paintDark = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  final Paint _paintLight = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
  final Paint _paintFill = Paint()..style = PaintingStyle.fill;
  final Paint _paintBorder = Paint()..style = PaintingStyle.stroke;
  final Path _darkPath = Path();
  final Path _lightPath = Path();

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

    final double scale = w / 240.0;
    final double gap = w * 0.035;
    final double cellW = (w - (gap * 2)) / 3;
    final double radius = cellW * 0.2;

    final double darkStrokeWidth = (4.5 * scale).clamp(2.0, 6.0);
    final double lightStrokeWidth = (4.0 * scale).clamp(1.5, 5.0);
    final double blurRadius = (3.5 * scale).clamp(1.0, 5.0);

    final double shiftX = tiltY * 3.0;
    final double shiftY = -tiltX * 3.0;

    _paintDark
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(alpha: 0.95)
      ..strokeWidth = darkStrokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    _paintLight
      ..color = NeumorphicColors.getLightShadow(baseColor).withValues(alpha: 0.95)
      ..strokeWidth = lightStrokeWidth
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);

    _paintFill.color = (themeName == 'Pacific Waves' ? Colors.black : NeumorphicColors.getDarkShadow(baseColor)).withValues(alpha: 0.15);
    _paintBorder
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final double left = col * (w / 3) + gap / 2;
        final double top = row * (h / 3) + gap / 2;
        final double drawnCellW = (w / 3) - gap;
        final double drawnCellH = (h / 3) - gap;
        
        final rect = Rect.fromLTWH(left, top, drawnCellW, drawnCellH);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

        canvas.drawRRect(rrect, _paintFill);
        canvas.drawRRect(rrect, _paintBorder);

        canvas.save();
        canvas.clipRRect(rrect);

        _darkPath.reset();
        _darkPath.addRRect(RRect.fromRectAndRadius(
          rect.translate(darkStrokeWidth * 0.5 + shiftX, darkStrokeWidth * 0.5 + shiftY), 
          Radius.circular(radius)
        ));
        canvas.drawPath(_darkPath, _paintDark);

        _lightPath.reset();
        _lightPath.addRRect(RRect.fromRectAndRadius(
          rect.translate(-lightStrokeWidth * 0.5 - shiftX, -lightStrokeWidth * 0.5 - shiftY), 
          Radius.circular(radius)
        ));
        canvas.drawPath(_lightPath, _paintLight);

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
