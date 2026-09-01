// lib/widgets/animations/ocean_float.dart
import 'dart:math';
import 'package:flutter/material.dart';

class OceanFloat extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double drift;
  final double swell;
  final double rotation;

  const OceanFloat({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 8),
    this.drift = 6.0,
    this.swell = 10.0,
    this.rotation = 0.02,
  });

  @override
  State<OceanFloat> createState() => _OceanFloatState();
}

class _OceanFloatState extends State<OceanFloat> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double angle = _controller.value * 2 * pi;
        final double dx = sin(angle) * widget.drift;
        final double dy = cos(angle * 0.8) * widget.swell;
        final double rot = sin(angle * 0.5) * widget.rotation;

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rot,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
