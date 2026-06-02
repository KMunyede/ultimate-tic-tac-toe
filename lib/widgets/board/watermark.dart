// lib/widgets/board/watermark.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/player.dart';

class SubBoardWatermark extends StatelessWidget {
  final Player winner;
  final String themeName;
  final double boardSize;
  final int boardIndex;

  const SubBoardWatermark({
    super.key,
    required this.winner,
    required this.themeName,
    required this.boardSize,
    required this.boardIndex,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: WatermarkPainter(
        winner: winner,
        themeName: themeName,
        boardSize: boardSize,
        boardIndex: boardIndex,
      ),
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final Player winner;
  final String themeName;
  final double boardSize;
  final int boardIndex;

  WatermarkPainter({
    required this.winner,
    required this.themeName,
    required this.boardSize,
    required this.boardIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (themeName.contains('Candy Meadow')) {
      _paintCandyWatermark(canvas, size, center);
    } else if (themeName.contains('Woodville Carve')) {
      _paintWoodvilleWatermark(canvas, size, center);
    } else if (themeName.contains('Amazon Jungle')) {
      _paintAmazonJungleWatermark(canvas, size, center);
    } else {
      _paintNeonWatermark(canvas, size, center);
    }
  }

  void _paintAmazonJungleWatermark(Canvas canvas, Size size, Offset center) {
    // 1. Deep carved concentric wood growth rings (engraved circles expanded!)
    final paintBaseGroove = Paint()
      ..color = const Color(0xFF1B0F0D).withValues(alpha: 0.65) // Deep mahogany groove shadow
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    final paintLightHighlight = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.25) // Glowing gold rim light catcher
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double r1 = size.width * 0.40;
    final double r2 = size.width * 0.22;

    void drawEngravedCircle(double radius) {
      final Path path = Path();
      for (int i = 0; i <= 360; i += 8) {
        final double rad = i * pi / 180;
        final double wobble = sin(rad * 10) * 1.5 + cos(rad * 4) * 0.8;
        final double px = center.dx + cos(rad) * (radius + wobble);
        final double py = center.dy + sin(rad) * (radius + wobble);
        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      path.close();
      canvas.drawPath(path, paintBaseGroove);
      canvas.drawPath(path.shift(const Offset(1.0, 1.0)), paintLightHighlight);
    }

    drawEngravedCircle(r1);
    drawEngravedCircle(r2);

    // 2. Thick carved Player mark (debossed stone/wood carving in center)
    final carvedMarkPaint = Paint()
      ..color = const Color(0xFF150E0C).withValues(alpha: 0.72) // Deep carved core
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

    final carvedMarkHighlight = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.3) // Gold/moss highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03
      ..strokeCap = StrokeCap.round;

    final double pad = size.width * 0.22;

    if (winner == Player.X) {
      // Draw deeply carved X
      final p1 = Offset(pad, pad);
      final p2 = Offset(size.width - pad, size.height - pad);
      final p3 = Offset(size.width - pad, pad);
      final p4 = Offset(pad, size.height - pad);

      canvas.drawLine(p1, p2, carvedMarkPaint);
      canvas.drawLine(p3, p4, carvedMarkPaint);

      canvas.drawLine(p1 + const Offset(1, 1), p2 + const Offset(1, 1), carvedMarkHighlight);
      canvas.drawLine(p3 + const Offset(-1, 1), p4 + const Offset(-1, 1), carvedMarkHighlight);

      // Branch/bark cracks spreading from center of X
      final crackPaint = Paint()
        ..color = const Color(0xFF27120E).withValues(alpha: 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(center, Offset(center.dx + size.width * 0.18, center.dy - size.height * 0.12), crackPaint);
      canvas.drawLine(center, Offset(center.dx - size.width * 0.15, center.dy + size.height * 0.16), crackPaint);
    } else {
      // Draw deeply carved O
      final rect = Rect.fromLTRB(pad, pad, size.width - pad, size.height - pad);
      canvas.drawOval(rect, carvedMarkPaint);
      canvas.drawOval(rect.shift(const Offset(1, 1)), carvedMarkHighlight);

      // Concentric inner spiral engraving
      final paintSpiral = Paint()
        ..color = const Color(0xFF27120E).withValues(alpha: 0.6)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawOval(rect.deflate(size.width * 0.05), paintSpiral);
    }

    // 3. Sprouting creep moss growing inside the carved grooves and circles
    final paintMossDark = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;
    final paintMossLight = Paint()
      ..color = const Color(0xFF8BC34A).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    // Place a few volumetric moss puffs along the outer carved circle and center marks
    final List<Offset> mossSpots = [
      Offset(center.dx + cos(1.0) * r1, center.dy + sin(1.0) * r1),
      Offset(center.dx + cos(3.2) * r1, center.dy + sin(3.2) * r1),
      Offset(center.dx + cos(4.8) * r1, center.dy + sin(4.8) * r1),
      Offset(center.dx + 5, center.dy - 10),
      Offset(center.dx - 12, center.dy + 8),
    ];

    for (var spot in mossSpots) {
      canvas.drawCircle(spot, 3.5, paintMossDark);
      canvas.drawCircle(spot + const Offset(1, -1), 2.2, paintMossLight);
      canvas.drawCircle(spot + const Offset(-1.5, 1), 1.5, paintMossLight);
    }
  }

  void _paintCandyWatermark(Canvas canvas, Size size, Offset center) {
    final paintGrid = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double hexRadius = size.width * 0.12;
    final double hexWidth = hexRadius * sqrt(3);
    final double hexHeight = hexRadius * 1.5;

    for (int row = -2; row <= 2; row++) {
      for (int col = -2; col <= 2; col++) {
        final double cx = center.dx + col * hexWidth +
            (row % 2 != 0 ? hexWidth / 2 : 0);
        final double cy = center.dy + row * hexHeight;

        final path = Path();
        for (int i = 0; i < 6; i++) {
          final double angle = i * pi / 3;
          final double px = cx + cos(angle) * hexRadius;
          final double py = cy + sin(angle) * hexRadius;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paintGrid);
      }
    }

    final beePaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromCenter(
        center: center, width: size.width * 0.28, height: size.height * 0.18),
        beePaint);

    final wingPaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(
        center.dx - size.width * 0.13, center.dy - size.height * 0.08),
        width: size.width * 0.15,
        height: size.height * 0.22), wingPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(
        center.dx + size.width * 0.13, center.dy - size.height * 0.08),
        width: size.width * 0.15,
        height: size.height * 0.22), wingPaint);
  }

  void _paintWoodvilleWatermark(Canvas canvas, Size size, Offset center) {
    final darkCharcoal = const Color(0xFF271A15).withValues(alpha: 0.38);
    final burntPaint = Paint()
      ..color = darkCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    if (winner == Player.X) {
      final double pad = size.width * 0.15;
      canvas.drawLine(
          Offset(pad, pad), Offset(size.width - pad, size.height - pad),
          burntPaint);
      canvas.drawLine(
          Offset(size.width - pad, pad), Offset(pad, size.height - pad),
          burntPaint);
    } else {
      final double pad = size.width * 0.15;
      canvas.drawCircle(center, size.width / 2 - pad, burntPaint);
    }

    final crackPaint = Paint()
      ..color = const Color(0xFF150E0C).withValues(alpha: 0.50)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center,
        Offset(center.dx + size.width * 0.25, center.dy - size.height * 0.15),
        crackPaint);
    canvas.drawLine(center,
        Offset(center.dx - size.width * 0.20, center.dy + size.height * 0.22),
        crackPaint);
  }

  void _paintNeonWatermark(Canvas canvas, Size size, Offset center) {
    final activeColor = winner == Player.X
        ? const Color(0xFFFF007F)
        : const Color(0xFF00FFCC);
    final pulseColor = activeColor.withValues(alpha: 0.15);

    final paintRing = Paint()
      ..color = pulseColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, size.width * 0.4, paintRing);
    canvas.drawCircle(center, size.width * 0.22, paintRing);

    final paintLine = Paint()
      ..color = pulseColor.withValues(alpha: 0.20)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width * 0.05, center.dy),
        Offset(size.width * 0.95, center.dy), paintLine);
    canvas.drawLine(Offset(center.dx, size.height * 0.05),
        Offset(center.dx, size.height * 0.95), paintLine);

    final tickPaint = Paint()
      ..color = pulseColor
      ..strokeWidth = 2.0;
    for (int i = 0; i < 4; i++) {
      final double angle = i * pi / 2;
      final Offset tickStart = Offset(
        center.dx + cos(angle) * size.width * 0.38,
        center.dy + sin(angle) * size.width * 0.38,
      );
      final Offset tickEnd = Offset(
        center.dx + cos(angle) * size.width * 0.42,
        center.dy + sin(angle) * size.width * 0.42,
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }
  }

  @override
  bool shouldRepaint(WatermarkPainter oldDelegate) =>
      oldDelegate.winner != winner || oldDelegate.themeName != themeName ||
          oldDelegate.boardIndex != boardIndex;
}
