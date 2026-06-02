// lib/widgets/board/winner_effect.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../features/settings/logic/settings_controller.dart';

class BoardWinnerEffect extends StatefulWidget {
  final Player winner;
  final double boardSize;

  const BoardWinnerEffect(
      {super.key, required this.winner, required this.boardSize});

  @override
  State<BoardWinnerEffect> createState() => _BoardWinnerEffectState();
}

class _BoardWinnerEffectState extends State<BoardWinnerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addListener(() => setState(() {}));
    _createParticles();
    _controller.forward();
  }

  void _createParticles() {
    final settings = Provider.of<SettingsController>(context, listen: false);
    final activeTheme = settings.currentTheme;
    final color = widget.winner == Player.X ? activeTheme.colorX : activeTheme
        .colorO;
    for (int i = 0; i < 40; i++) {
      _particles.add(Particle(
        color: color.withValues(alpha: _random.nextDouble() * 0.8 + 0.2),
        angle: _random.nextDouble() * 2 * pi,
        speed: _random.nextDouble() * 4 + 2,
        size: _random.nextDouble() * (widget.boardSize * 0.04) + 2,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: ParticlePainter(particles: _particles,
          progress: _controller.value,
          boardSize: widget.boardSize)),
    );
  }
}

class Particle {
  final Color color;
  final double angle, speed, size;

  Particle(
      {required this.color, required this.angle, required this.speed, required this.size});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress, boardSize;

  ParticlePainter(
      {required this.particles, required this.progress, required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    for (var p in particles) {
      final distance = p.speed * progress * (boardSize * 0.5);
      final x = center.dx + cos(p.angle) * distance;
      final y = center.dy + sin(p.angle) * distance;
      paint.color = p.color.withValues(
          alpha: (1.0 - progress).clamp(0.0, 1.0) * p.color.a);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
