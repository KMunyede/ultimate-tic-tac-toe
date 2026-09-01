// lib/widgets/board/marker_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/player.dart';
import 'marker_drawings.dart';

class MarkerPainter extends CustomPainter {
  final Player player;
  final double progress, boardSize;
  final bool isLarge;
  final Color baseColor;
  final String themeName;

  MarkerPainter({
    required this.player,
    required this.progress,
    required this.boardSize,
    required this.isLarge,
    required this.baseColor,
    required this.themeName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleMultiplier = isLarge ? 1.0 : (boardSize > 300 ? 1.0 : 1.05); // Dynamic 5% scale
    final double strokeFactor = isLarge ? 0.12 : (0.045 * scaleMultiplier);
    final double strokeWidth = (boardSize * strokeFactor).clamp(1.5, 45.0);
    final double padding = (isLarge ? size.width * 0.15 : size.width * 0.22) / scaleMultiplier;

    if (themeName == 'Pacific Waves') {
      // Add Drop Shadow to markers for depth on bamboo
      canvas.save();
      canvas.translate(2, 4); // Shadow offset
      if (player == Player.X) {
        MarkerDrawings.drawStarfish(canvas, size, Colors.black.withValues(alpha: 0.3), progress);
      } else if (player == Player.O) {
        MarkerDrawings.drawClamshell(canvas, size, Colors.black.withValues(alpha: 0.3), progress);
      }
      canvas.restore();

      if (player == Player.X) {
        MarkerDrawings.drawStarfish(canvas, size, baseColor, progress);
      } else if (player == Player.O) {
        // Use a warm cream for the clamshell to match cartoon style
        MarkerDrawings.drawClamshell(canvas, size, const Color(0xFFFDF5E6), progress);
      }
      return;
    }

    if (player == Player.X) {
      _drawX(canvas, size, padding, strokeWidth);
    } else if (player == Player.O) {
      _drawO(canvas, size, padding, strokeWidth);
    }
  }

  void _drawX(Canvas canvas, Size size, double padding, double strokeWidth) {
    final start1 = Offset(padding, padding);
    final end1 = Offset(size.width - padding, size.height - padding);
    final start2 = Offset(size.width - padding, padding);
    final end2 = Offset(padding, size.height - padding);

    double p1 = (progress * 2).clamp(0.0, 1.0);
    if (p1 > 0) {
      final target = Offset(start1.dx + (end1.dx - start1.dx) * p1, start1.dy + (end1.dy - start1.dy) * p1);
      MarkerDrawings.drawThemedLine(canvas, start1, target, themeName, baseColor, strokeWidth);
    }
    if (progress > 0.5) {
      double p2 = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final target = Offset(start2.dx + (end2.dx - start2.dx) * p2, start2.dy + (end2.dy - start2.dy) * p2);
      MarkerDrawings.drawThemedLine(canvas, start2, target, themeName, baseColor, strokeWidth);
    }
  }

  void _drawO(Canvas canvas, Size size, double padding, double strokeWidth) {
    final rect = Rect.fromLTRB(padding, padding, size.width - padding, size.height - padding);
    MarkerDrawings.drawThemedArc(canvas, rect, -pi / 2, 2 * pi * progress, themeName, baseColor, strokeWidth);
  }

  @override
  bool shouldRepaint(covariant MarkerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isLarge != isLarge || oldDelegate.baseColor != baseColor || oldDelegate.themeName != themeName;
}
