// lib/widgets/painters/animal_painter.dart
import 'package:flutter/material.dart';
import 'jungle_animal_drawings.dart';
import 'jungle_animal_drawings_big_cats.dart';
import 'pacific_animal_drawings.dart';

class AnimalPainter extends CustomPainter {
  final int animalIndex;
  final double pulse;
  final double sizeFactor;
  final String themeName;

  AnimalPainter({
    required this.animalIndex,
    required this.pulse,
    required this.sizeFactor,
    required this.themeName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (themeName == 'Pacific Waves') {
      switch (animalIndex) {
        case 0: PacificAnimalDrawings.drawSeagull(canvas, size, pulse); break;
        case 1: PacificAnimalDrawings.drawPanda(canvas, size, pulse); break;
        case 2: PacificAnimalDrawings.drawCrab(canvas, size, pulse); break;
        case 3: PacificAnimalDrawings.drawWhale(canvas, size, pulse); break;
        case 4: PacificAnimalDrawings.drawTurtle(canvas, size, pulse); break;
      }
    } else if (themeName == 'Amazon Jungle') {
      switch (animalIndex) {
        case 0: JungleAnimalDrawings.drawToucan(canvas, size, pulse); break;
        case 1: JungleAnimalDrawings.drawSnake(canvas, size, pulse); break;
        case 2: JungleAnimalDrawings.drawTreeFrog(canvas, size, pulse); break;
        case 3: JungleBigCatsDrawings.drawTiger(canvas, size, pulse); break;
        case 4: JungleBigCatsDrawings.drawLion(canvas, size, pulse); break;
      }
    } else {
      // Fallback/Random for other themes
      switch (animalIndex % 5) {
        case 0: JungleAnimalDrawings.drawToucan(canvas, size, pulse); break;
        case 1: PacificAnimalDrawings.drawPanda(canvas, size, pulse); break;
        case 2: JungleAnimalDrawings.drawTreeFrog(canvas, size, pulse); break;
        case 3: PacificAnimalDrawings.drawCrab(canvas, size, pulse); break;
        case 4: JungleBigCatsDrawings.drawLion(canvas, size, pulse); break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimalPainter oldDelegate) =>
      oldDelegate.pulse != pulse ||
      oldDelegate.animalIndex != animalIndex ||
      oldDelegate.sizeFactor != sizeFactor ||
      oldDelegate.themeName != themeName;
}
