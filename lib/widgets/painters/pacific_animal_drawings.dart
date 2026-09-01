// lib/widgets/painters/pacific_animal_drawings.dart
import 'dart:math';
import 'package:flutter/material.dart';

class PacificAnimalDrawings {
  static void drawPanda(Canvas canvas, Size size, double pulse) {
    final double w = size.width;
    final double h = size.height;
    final double bob = sin(pulse * 2 * pi) * 5.0;
    
    canvas.save();
    canvas.translate(0, bob);

    // 1. Body
    final Paint bodyPaint = Paint()..color = const Color(0xFFF5F5F0);
    final Paint borderPaint = Paint()..color = const Color(0xFFDDDDDD)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final Rect bodyRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.5), width: w * 0.8, height: h * 0.7);
    canvas.drawRRect(RRect.fromRectAndCorners(bodyRect, topLeft: Radius.circular(w * 0.4), topRight: Radius.circular(w * 0.4), bottomLeft: Radius.circular(w * 0.35), bottomRight: Radius.circular(w * 0.35)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndCorners(bodyRect, topLeft: Radius.circular(w * 0.4), topRight: Radius.circular(w * 0.4), bottomLeft: Radius.circular(w * 0.35), bottomRight: Radius.circular(w * 0.35)), borderPaint);

    // 2. Ears
    final Paint earPaint = Paint()..color = const Color(0xFF2A2A2A);
    canvas.drawCircle(Offset(w * 0.25, h * 0.25), w * 0.15, earPaint);
    canvas.drawCircle(Offset(w * 0.75, h * 0.25), w * 0.15, earPaint);

    // 3. Eye Patches
    final Paint patchPaint = Paint()..color = const Color(0xFF2A2A2A);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.35, h * 0.45), width: w * 0.25, height: h * 0.2), patchPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.65, h * 0.45), width: w * 0.25, height: h * 0.2), patchPaint);

    // 4. Eyes (Blinking)
    final bool isBlinking = (pulse * 10) % 10 > 9;
    final Paint eyePaint = Paint()..color = Colors.white;
    final Paint pupilPaint = Paint()..color = const Color(0xFF111111);
    
    if (!isBlinking) {
      canvas.drawCircle(Offset(w * 0.35, h * 0.45), w * 0.05, eyePaint);
      canvas.drawCircle(Offset(w * 0.65, h * 0.45), w * 0.05, eyePaint);
      canvas.drawCircle(Offset(w * 0.35, h * 0.45), w * 0.025, pupilPaint);
      canvas.drawCircle(Offset(w * 0.65, h * 0.45), w * 0.025, pupilPaint);
    } else {
      final Paint closedPaint = Paint()..color = Colors.white..strokeWidth = 2.0..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.3, h * 0.45), Offset(w * 0.4, h * 0.45), closedPaint);
      canvas.drawLine(Offset(w * 0.6, h * 0.45), Offset(w * 0.7, h * 0.45), closedPaint);
    }

    // 5. Nose & Mouth
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.6), width: w * 0.15, height: h * 0.08), Paint()..color = const Color(0xFFE8A0A0));
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.68), width: w * 0.25, height: h * 0.08), Paint()..color = const Color(0xFFE8A0A0).withValues(alpha: 0.5));

    canvas.restore();
  }

  static void drawTurtle(Canvas canvas, Size size, double pulse) {
    final double w = size.width;
    final double h = size.height;
    final double bob = sin(pulse * 2 * pi + 0.5) * 4.0;
    
    canvas.save();
    canvas.translate(0, bob);

    // 1. Shell
    final Paint shellPaint = Paint()..color = const Color(0xFF5A9A30);
    final Paint shellBorder = Paint()..color = const Color(0xFF3A7010)..style = PaintingStyle.stroke..strokeWidth = 2.5;
    final Rect shellRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.55), width: w * 0.8, height: h * 0.6);
    canvas.drawRRect(RRect.fromRectAndCorners(shellRect, topLeft: Radius.circular(w * 0.4), topRight: Radius.circular(w * 0.4), bottomLeft: Radius.circular(w * 0.3), bottomRight: Radius.circular(w * 0.3)), shellPaint);
    canvas.drawRRect(RRect.fromRectAndCorners(shellRect, topLeft: Radius.circular(w * 0.4), topRight: Radius.circular(w * 0.4), bottomLeft: Radius.circular(w * 0.3), bottomRight: Radius.circular(w * 0.3)), shellBorder);

    // 2. Hex Pattern (Simplified)
    final Paint patternPaint = Paint()..color = const Color(0xFF3A7010)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.4, h * 0.45), width: w * 0.2, height: h * 0.15), patternPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.6, h * 0.45), width: w * 0.2, height: h * 0.15), patternPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.5, h * 0.6), width: w * 0.2, height: h * 0.15), patternPaint);

    // 3. Head
    final Paint headPaint = Paint()..color = const Color(0xFF7ABA48);
    final Rect headRect = Rect.fromLTWH(w * 0.75, h * 0.4, w * 0.25, h * 0.3);
    canvas.drawOval(headRect, headPaint);
    canvas.drawCircle(Offset(w * 0.9, h * 0.5), w * 0.04, Paint()..color = const Color(0xFF222222)); // Eye

    // 4. Legs
    final Paint legPaint = Paint()..color = const Color(0xFF7ABA48)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.2, h * 0.8), w * 0.1, legPaint);
    canvas.drawCircle(Offset(w * 0.8, h * 0.8), w * 0.1, legPaint);

    canvas.restore();
  }

  static void drawCrab(Canvas canvas, Size size, double pulse) {
    final double w = size.width;
    final double h = size.height;
    final double wave = sin(pulse * 4 * pi) * 10.0;
    
    // 1. Eye Stalks
    final Paint stalkPaint = Paint()..color = const Color(0xFFE05530)..strokeWidth = 4..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.4, h * 0.4), Offset(w * 0.4, h * 0.2), stalkPaint);
    canvas.drawLine(Offset(w * 0.6, h * 0.4), Offset(w * 0.6, h * 0.2), stalkPaint);
    canvas.drawCircle(Offset(w * 0.4, h * 0.2), w * 0.08, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.6, h * 0.2), w * 0.08, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.4, h * 0.2), w * 0.03, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(w * 0.6, h * 0.2), w * 0.03, Paint()..color = Colors.black);

    // 2. Body
    final Paint bodyPaint = Paint()..color = const Color(0xFFE05530);
    final Paint bodyBorder = Paint()..color = const Color(0xFFB03010)..style = PaintingStyle.stroke..strokeWidth = 2.0;
    final Rect bodyRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.65), width: w * 0.7, height: h * 0.4);
    canvas.drawRRect(RRect.fromRectAndCorners(bodyRect, topLeft: Radius.circular(w * 0.35), topRight: Radius.circular(w * 0.35), bottomLeft: Radius.circular(w * 0.25), bottomRight: Radius.circular(w * 0.25)), bodyPaint);
    canvas.drawRRect(RRect.fromRectAndCorners(bodyRect, topLeft: Radius.circular(w * 0.35), topRight: Radius.circular(w * 0.35), bottomLeft: Radius.circular(w * 0.25), bottomRight: Radius.circular(w * 0.25)), bodyBorder);

    // 3. Claws (Animated)
    final Paint clawPaint = Paint()..color = const Color(0xFFE05530);
    canvas.save();
    canvas.translate(w * 0.2, h * 0.5);
    canvas.rotate(wave * 0.02);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.3, height: h * 0.25), clawPaint);
    canvas.restore();

    canvas.save();
    canvas.translate(w * 0.8, h * 0.5);
    canvas.rotate(-wave * 0.02);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.3, height: h * 0.25), clawPaint);
    canvas.restore();
    
    // 4. Legs
    final Paint legPaint = Paint()..color = const Color(0xFFE05530)..strokeWidth = 3;
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(Offset(w * 0.2, h * 0.7 + i * 5), Offset(w * 0.1, h * 0.8 + i * 5), legPaint);
      canvas.drawLine(Offset(w * 0.8, h * 0.7 + i * 5), Offset(w * 0.9, h * 0.8 + i * 5), legPaint);
    }
  }

  static void drawWhale(Canvas canvas, Size size, double pulse) {
    // Simplified Cartoon Whale
    final double w = size.width;
    final double h = size.height;
    final double sway = sin(pulse * 2 * pi) * 8.0;

    final Paint whalePaint = Paint()..color = const Color(0xFF3A8FBF);
    final Path path = Path()
      ..moveTo(w * 0.1, h * 0.6 + sway)
      ..quadraticBezierTo(w * 0.5, h * 0.2 + sway, w * 0.9, h * 0.6 + sway)
      ..quadraticBezierTo(w * 0.9, h * 0.8 + sway, w * 0.5, h * 0.85 + sway)
      ..quadraticBezierTo(w * 0.1, h * 0.8 + sway, w * 0.1, h * 0.6 + sway)
      ..close();
    canvas.drawPath(path, whalePaint);
    
    // Tail
    final Path tail = Path()
      ..moveTo(w * 0.9, h * 0.6 + sway)
      ..lineTo(w * 1.1, h * 0.5 + sway)
      ..lineTo(w * 1.1, h * 0.7 + sway)
      ..close();
    canvas.drawPath(tail, whalePaint);

    canvas.drawCircle(Offset(w * 0.3, h * 0.55 + sway), w * 0.04, Paint()..color = Colors.black);
  }

  static void drawSeagull(Canvas canvas, Size size, double pulse) {
    // Simplified Cartoon Seagull
    final double w = size.width;
    final double h = size.height;
    final double flap = sin(pulse * 4 * pi) * 10.0;

    final Paint birdPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    // Wings
    canvas.drawPath(Path()..moveTo(w * 0.3, h * 0.5)..quadraticBezierTo(w * 0.5, h * 0.5 - flap, w * 0.7, h * 0.5), birdPaint);
    canvas.drawPath(Path()..moveTo(w * 0.3, h * 0.5)..quadraticBezierTo(w * 0.1, h * 0.5 - flap, -w * 0.1, h * 0.5), birdPaint);
    
    // Body/Head
    canvas.drawCircle(Offset(w * 0.3, h * 0.5), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.35, h * 0.5), 2, Paint()..color = Colors.orange);
  }
}
