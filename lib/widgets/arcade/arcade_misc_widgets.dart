// lib/widgets/arcade/arcade_misc_widgets.dart
import 'package:flutter/material.dart';
import 'arcade_painters.dart';

class LadybugIcon extends StatelessWidget {
  final double size;
  const LadybugIcon({super.key, this.size = 12.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE53935),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 1.0,
            height: size,
            color: Colors.black,
          ),
          Positioned(
            left: size * 0.15,
            top: size * 0.25,
            child: Container(width: 1.5, height: 1.5, color: Colors.black),
          ),
          Positioned(
            right: size * 0.15,
            top: size * 0.25,
            child: Container(width: 1.5, height: 1.5, color: Colors.black),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: size * 0.4,
              height: size * 0.25,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutIcon extends StatelessWidget {
  final double size;
  const DonutIcon({super.key, this.size = 12.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFF4081),
        border: Border.all(color: const Color(0xFFE5A882), width: size * 0.25),
      ),
    );
  }
}

class ArcadeScrewWidget extends StatelessWidget {
  final bool isLight;
  final double size;
  const ArcadeScrewWidget({super.key, required this.isLight, this.size = 14.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HexScrewPainter(isLight: isLight),
      ),
    );
  }
}

class GlowingCoinSlotWidget extends StatelessWidget {
  const GlowingCoinSlotWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.amber.shade700, width: 1),
      ),
      child: Center(
        child: Container(
          width: 2,
          height: 12,
          color: Colors.amber.shade700,
        ),
      ),
    );
  }
}
