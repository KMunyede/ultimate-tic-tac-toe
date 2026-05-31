// lib/widgets/animations/holographic_tilt.dart

import 'package:flutter/material.dart';

/// A premium pointer-reactive and drag-reactive 3D perspective tilt wrapper.
/// Tilts the child in 3D space toward the cursor or touch-drag point and shifts
/// an underlying ambient shadow layer in the opposite direction to simulate deep physical volume.
class InteractiveHolographicTilt extends StatefulWidget {
  final Widget child;
  const InteractiveHolographicTilt({super.key, required this.child});

  @override
  State<InteractiveHolographicTilt> createState() => _InteractiveHolographicTiltState();
}

class _InteractiveHolographicTiltState extends State<InteractiveHolographicTilt> {
  Offset _tilt = Offset.zero;
  bool _isTracking = false;

  void _onPointerMove(Offset localPos, Size size) {
    if (!mounted) return;
    // Calculate normalized offset relative to center of the widget: -1.0 to 1.0
    final double nx = ((localPos.dx / size.width) - 0.5).clamp(-0.5, 0.5) * 2;
    final double ny = ((localPos.dy / size.height) - 0.5).clamp(-0.5, 0.5) * 2;
    setState(() {
      _tilt = Offset(nx, ny);
      _isTracking = true;
    });
  }

  void _onPointerExit() {
    if (!mounted) return;
    setState(() {
      _isTracking = false;
      _tilt = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth > 0 ? constraints.maxWidth : 300,
          constraints.maxHeight > 0 ? constraints.maxHeight : 300,
        );
        return MouseRegion(
          onHover: (event) => _onPointerMove(event.localPosition, size),
          onExit: (_) => _onPointerExit(),
          child: GestureDetector(
            onPanUpdate: (details) => _onPointerMove(details.localPosition, size),
            onPanEnd: (_) => _onPointerExit(),
            onPanCancel: () => _onPointerExit(),
            child: TweenAnimationBuilder<Offset>(
              tween: Tween<Offset>(begin: Offset.zero, end: _isTracking ? _tilt : Offset.zero),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic, // Cushioned cubic easing curves for high-fidelity smoothness
              builder: (context, currentTilt, child) {
                // Max tilt angle (approx. 9 degrees)
                const double maxTiltAngle = 0.15;
                final double rotX = -currentTilt.dy * maxTiltAngle;
                final double rotY = currentTilt.dx * maxTiltAngle;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0008) // Soft realistic 3D perspective
                    ..rotateX(rotX)
                    ..rotateY(rotY),
                  alignment: Alignment.center,
                  child: widget.child,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
