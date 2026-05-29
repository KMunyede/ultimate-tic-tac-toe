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

class _InteractiveHolographicTiltState extends State<InteractiveHolographicTilt>
    with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero;
  late AnimationController _resetController;
  late Animation<Offset> _resetAnimation;
  Offset _exitStartTilt = Offset.zero;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _resetAnimation = _resetController.drive(
      Tween<Offset>(begin: Offset.zero, end: Offset.zero),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onPointerMove(Offset localPos, Size size) {
    if (!mounted) return;
    if (_resetController.isAnimating) {
      _resetController.stop();
    }
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
    _exitStartTilt = _tilt;
    _resetAnimation = _resetController.drive(
      Tween<Offset>(begin: _exitStartTilt, end: Offset.zero).chain(
        CurveTween(curve: Curves.easeOutBack), // Smooth retro physical bounce back!
      ),
    );
    _resetController.forward(from: 0.0);
    setState(() {
      _isTracking = false;
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
            child: AnimatedBuilder(
              animation: _resetController,
              builder: (context, child) {
                final currentTilt = _isTracking ? _tilt : _resetAnimation.value;
                // Max tilt angle (approx. 9 degrees)
                const double maxTiltAngle = 0.15;
                final double rotX = -currentTilt.dy * maxTiltAngle;
                final double rotY = currentTilt.dx * maxTiltAngle;

                // 3D Shadow shifting coordinates (moves opposite to tilt)
                final double shadowDx = -currentTilt.dx * 12.0;
                final double shadowDy = -currentTilt.dy * 12.0;

                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0008) // Soft realistic 3D perspective
                    ..rotateX(rotX)
                    ..rotateY(rotY),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Occlusion Shadow Layer shifting dynamically
                      Positioned(
                        left: shadowDx,
                        top: shadowDy,
                        right: -shadowDx,
                        bottom: -shadowDy,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  spreadRadius: -2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Actual gameplay board widget
                      widget.child,
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
