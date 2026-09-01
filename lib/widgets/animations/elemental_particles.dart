// lib/widgets/animations/elemental_particles.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/player.dart';

class ElementalImpact extends StatefulWidget {
  final Player player;
  final double boardSize;
  final VoidCallback onComplete;

  const ElementalImpact({
    super.key,
    required this.player,
    required this.boardSize,
    required this.onComplete,
  });

  @override
  State<ElementalImpact> createState() => _ElementalImpactState();
}

class _ElementalImpactState extends State<ElementalImpact> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    _particles = List.generate(widget.player == Player.X ? 15 : 8, (index) {
      return Particle(
        angle: _random.nextDouble() * 2 * pi,
        speed: 2.0 + _random.nextDouble() * 4.0,
        size: 2.0 + _random.nextDouble() * 3.0,
        color: widget.player == Player.X 
            ? Colors.amberAccent.withValues(alpha: 0.8) 
            : Colors.lightBlueAccent.withValues(alpha: 0.6),
      );
    });

    _controller.forward();
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
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            player: widget.player,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Player player;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.player,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (player == Player.X) {
      // Lightning Sparks for X
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (var p in particles) {
        final double dist = progress * p.speed * 40.0;
        final double opacity = (1.0 - progress).clamp(0.0, 1.0);
        
        paint.color = p.color.withValues(alpha: opacity);
        paint.strokeWidth = p.size * (1.0 - progress);

        final start = Offset(
          center.dx + cos(p.angle) * dist * 0.5,
          center.dy + sin(p.angle) * dist * 0.5,
        );
        final end = Offset(
          center.dx + cos(p.angle) * dist,
          center.dy + sin(p.angle) * dist,
        );
        
        canvas.drawLine(start, end, paint);
      }
    } else {
      // Ripples for O
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int i = 0; i < 3; i++) {
        final double rippleProgress = (progress - (i * 0.2)).clamp(0.0, 1.0);
        if (rippleProgress <= 0) continue;

        final double opacity = (1.0 - rippleProgress);
        final double radius = rippleProgress * 40.0;
        
        paint.color = Colors.lightBlueAccent.withValues(alpha: opacity * 0.5);
        canvas.drawCircle(center, radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
