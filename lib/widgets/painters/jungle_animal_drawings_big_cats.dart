// lib/widgets/painters/jungle_animal_drawings_big_cats.dart
import 'dart:math';
import 'package:flutter/material.dart';

class JungleBigCatsDrawings {
  static void drawLion(Canvas canvas, Size size, double pulse) {
    final double w = size.width;
    final double h = size.height;
    final double bob = sin(pulse * 2 * pi) * 4.0;

    canvas.save();
    canvas.translate(0, bob);

    // 1. Mane
    final Paint manePaint = Paint()..color = Colors.orange.shade800;
    final Paint borderPaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.0;
    canvas.drawCircle(Offset(w * 0.5, h * 0.4), w * 0.4, manePaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.4), w * 0.4, borderPaint);

    // 2. Head
    final Paint headPaint = Paint()..color = Colors.orange.shade400;
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.25, headPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.25, borderPaint);

    // 3. Face
    canvas.drawCircle(Offset(w * 0.4, h * 0.4), 4, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(w * 0.6, h * 0.4), 4, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), 6, Paint()..color = Colors.pink.shade200);

    canvas.restore();
  }

  static void drawTiger(Canvas canvas, Size size, double pulse) {
    final double w = size.width;
    final double h = size.height;
    final double bob = sin(pulse * 2 * pi) * 4.0;

    canvas.save();
    canvas.translate(0, bob);

    // 1. Head
    final Paint headPaint = Paint()..color = Colors.orange;
    final Paint borderPaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3.0;
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.35, headPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.35, borderPaint);

    // 2. Stripes (Simplified)
    final Paint stripePaint = Paint()..color = Colors.black;
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(w * 0.3, h * 0.3 + i * 15, w * 0.1, 5), stripePaint);
      canvas.drawRect(Rect.fromLTWH(w * 0.6, h * 0.3 + i * 15, w * 0.1, 5), stripePaint);
    }

    // 3. Face
    canvas.drawCircle(Offset(w * 0.4, h * 0.45), 4, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(w * 0.6, h * 0.45), 4, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(w * 0.5, h * 0.55), 6, Paint()..color = Colors.pink.shade200);

    canvas.restore();
  }
}
