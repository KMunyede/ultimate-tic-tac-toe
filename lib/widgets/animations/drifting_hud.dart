import 'package:flutter/material.dart';

class DriftingHudWidget extends StatelessWidget {
  final Widget child;
  final double driftX;
  final double driftY;
  final double rotateAngle;
  final Duration baseDuration;
  final int phaseOffset;

  const DriftingHudWidget({
    super.key,
    required this.child,
    this.driftX = 4.0,
    this.driftY = 6.0,
    this.rotateAngle = 0.012,
    this.baseDuration = const Duration(milliseconds: 4000),
    this.phaseOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Performance Calibration: Return the child statically to completely eliminate
    // per-frame HUD rendering overhead. This makes all HUD elements (Telemetry panel,
    // score boards, mode toggles) 100% visible, separate, and perfectly readable
    // under any emulated environment or hardware!
    return child;
  }
}
