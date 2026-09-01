// lib/widgets/painters/jungle_animal_drawings.dart
import 'dart:math';
import 'package:flutter/material.dart';

class JungleAnimalDrawings {
  static void drawToucan(Canvas canvas, Size size, double pulse) {
    final double w = size.width;
    final double h = size.height;
    final double bob = sin(pulse * 2 * pi) * 4.0;

    canvas.save();
    canvas.translate(0, bob);

    // 1. Body
    final Paint bodyPaint = Paint()..color = const Color(0xFF212121);
    final Paint borderPaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.0;
    final Rect bodyRect = Rect.fromCenter(center: Offset(w * 0.4, h * 0.6), width: w * 0.6, height: h * 0.5);
    canvas.drawOval(bodyRect, bodyPaint);
    canvas.drawOval(bodyRect, borderPaint);

    // 2. Beak (Cartoon Giant)
    final Paint beakPaint = Paint()..color = Colors.orange;
    final Path beakPath = Path()
      ..moveTo(w * 0.6, h * 0.5)
      ..quadraticBezierTo(w * 0.9, h * 0.3, w * 1.1, h * 0.5)
      ..quadraticBezierTo(w * 0.9, h * 0.7, w * 0.6, h * 0.6)
      ..close();
    canvas.drawPath(beakPath, beakPaint);
    canvas.drawPath(beakPath, borderPaint);

    // 3. Eye
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.1, Paint()..color = Colors.lightBlueAccent);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.04, Paint()..color = Colors.black);

    canvas.restore();
  }

  static void drawSnake(Canvas canvas, Size size, double pulse) {
    final double w = size.width;
    final double h = size.height;
    final double sway = sin(pulse * 2 * pi) * 10.0;

    // 1. Coiled Body
    final Paint snakePaint = Paint()..color = Colors.green;
    final Paint borderPaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.0;
    
    final Path body = Path()
      ..moveTo(w * 0.2, h * 0.8)
      ..quadraticBezierTo(w * 0.5 + sway, h * 0.2, w * 0.8, h * 0.8);
    
    canvas.drawPath(body, Paint()..color = Colors.green..style = PaintingStyle.stroke..strokeWidth = w * 0.2..strokeCap = StrokeCap.round);
    canvas.drawPath(body, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = w * 0.2 + 6..strokeCap = StrokeCap.round);
    canvas.drawPath(body, Paint()..color = Colors.green..style = PaintingStyle.stroke..strokeWidth = w * 0.2..strokeCap = StrokeCap.round);

    // 2. Head
    final Rect headRect = Rect.fromCenter(center: Offset(w * 0.8, h * 0.8), width: w * 0.3, height: h * 0.2);
    canvas.drawOval(headRect, snakePaint);
    canvas.drawOval(headRect, borderPaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.75), 4, Paint()..color = Colors.black);
  }

  static void drawTreeFrog(Canvas canvas, Size size, double pulse) {
    final double w = size.width;
    final double h = size.height;
    final double jump = (sin(pulse * 4 * pi)).abs() * 10.0;

    // 1. Body
    final Paint frogPaint = Paint()..color = Colors.lightGreenAccent;
    final Paint borderPaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.0;
    
    final Rect bodyRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.6 - jump), width: w * 0.7, height: h * 0.4);
    canvas.drawOval(bodyRect, frogPaint);
    canvas.drawOval(bodyRect, borderPaint);

    // 2. Eyes (Huge Cartoon)
    canvas.drawCircle(Offset(w * 0.3, h * 0.4 - jump), w * 0.15, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(w * 0.3, h * 0.4 - jump), w * 0.15, borderPaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.4 - jump), w * 0.15, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(w * 0.7, h * 0.4 - jump), w * 0.15, borderPaint);
    
    canvas.drawCircle(Offset(w * 0.3, h * 0.4 - jump), w * 0.05, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(w * 0.7, h * 0.4 - jump), w * 0.05, Paint()..color = Colors.black);
  }
}
