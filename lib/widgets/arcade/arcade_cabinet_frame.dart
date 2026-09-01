// lib/widgets/arcade/arcade_cabinet_frame.dart
import 'package:flutter/material.dart';
import 'arcade_painters.dart';

/// A high-fidelity Arcade Cabinet frame that wraps game content.
/// It provides a "bezel" look with hex screws and optional scanline overlays.
class ArcadeCabinetFrame extends StatelessWidget {
  final Widget child;
  final bool showScanlines;
  final bool isLightMode;
  final double bezelWidth;

  const ArcadeCabinetFrame({
    super.key,
    required this.child,
    this.showScanlines = true,
    this.isLightMode = false,
    this.bezelWidth = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isLightMode ? Colors.grey.shade200 : const Color(0xFF1A1A1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main Content Area with Bezel Padding
          Padding(
            padding: EdgeInsets.all(bezelWidth),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isLightMode ? Colors.grey.shade400 : Colors.grey.shade800,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  child,
                  if (showScanlines)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: LedGridPainter(isLight: isLightMode),
                        ),
                      ),
                    ),
                  // Screen Glare/Inner Shadow
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.5, -0.6),
                            radius: 1.2,
                            colors: [
                              Colors.white.withValues(alpha: 0.05),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bezel Decorations: Hex Screws
          _buildScrew(Alignment.topLeft),
          _buildScrew(Alignment.topRight),
          _buildScrew(Alignment.bottomLeft),
          _buildScrew(Alignment.bottomRight),
        ],
      ),
    );
  }

  Widget _buildScrew(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: SizedBox(
          width: 12,
          height: 12,
          child: CustomPaint(
            painter: HexScrewPainter(isLight: isLightMode),
          ),
        ),
      ),
    );
  }
}
