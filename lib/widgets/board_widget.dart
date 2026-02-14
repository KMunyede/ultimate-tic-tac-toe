import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app_theme.dart';
import '../game_controller.dart';
import '../models/player.dart';

class BoardWidget extends StatefulWidget {
  final int boardIndex;

  const BoardWidget({super.key, required this.boardIndex});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  // We keep the variables to avoid breaking existing logic, but they won't affect the UI anymore
  double xRotation = 0;
  double yRotation = 0;
  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    // Accelerometer still runs, but we've removed the transform to avoid the 3D slant
    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          yRotation = event.x / 50.0;
          xRotation = -event.y / 50.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final board = controller.boards[widget.boardIndex];
    final theme = Theme.of(context);
    final themeBgColor = theme.scaffoldBackgroundColor;
    
    final hsl = HSLColor.fromColor(themeBgColor);
    final boardColor = hsl.withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0)).toColor();

    return TweenAnimationBuilder<double>(
      key: ValueKey(board.winner),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final double shakeOffset = (board.winner != null && value < 1.0) 
            ? sin(value * pi * 2) * 12.0 
            : 0.0;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child, // Removed the 3D Perspective Transform here
        );
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: boardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: NeumorphicColors.getDarkShadow(themeBgColor),
                  offset: const Offset(6, 6), // Static shadows for a cleaner look
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: NeumorphicColors.getLightShadow(themeBgColor),
                  offset: const Offset(-6, -6),
                  blurRadius: 12,
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 9,
              itemBuilder: (context, cellIndex) {
                final cellValue = board.cells[cellIndex];
                return NeumorphicCell(
                  onTap: () => controller.makeMove(widget.boardIndex, cellIndex),
                  player: cellValue,
                  baseColor: boardColor,
                );
              },
            ),
          ),
          if (board.winner != null)
            Positioned.fill(
              child: BoardWinnerEffect(winner: board.winner!),
            ),
        ],
      ),
    );
  }
}

class BoardWinnerEffect extends StatefulWidget {
  final Player winner;
  const BoardWinnerEffect({super.key, required this.winner});

  @override
  State<BoardWinnerEffect> createState() => _BoardWinnerEffectState();
}

class _BoardWinnerEffectState extends State<BoardWinnerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() => setState(() {}));

    _createParticles();
    _controller.forward();
  }

  void _createParticles() {
    final color = widget.winner == Player.X ? Colors.redAccent : const Color(0xFF1A237E);
    for (int i = 0; i < 40; i++) {
      _particles.add(Particle(
        color: color.withOpacity(_random.nextDouble() * 0.8 + 0.2),
        angle: _random.nextDouble() * 2 * pi,
        speed: _random.nextDouble() * 4 + 2,
        size: _random.nextDouble() * 6 + 2,
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
      child: CustomPaint(
        painter: ParticlePainter(
          particles: _particles,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class Particle {
  final Color color;
  final double angle;
  final double speed;
  final double size;

  Particle({required this.color, required this.angle, required this.speed, required this.size});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    for (var particle in particles) {
      final distance = particle.speed * progress * 150;
      final x = center.dx + cos(particle.angle) * distance;
      final y = center.dy + sin(particle.angle) * distance;
      
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = particle.color.withOpacity(opacity * (particle.color.opacity));
      
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class NeumorphicCell extends StatelessWidget {
  final VoidCallback onTap;
  final Player player;
  final Color baseColor;

  const NeumorphicCell({
    super.key,
    required this.onTap,
    required this.player,
    required this.baseColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: NeumorphicColors.getDarkShadow(baseColor),
              offset: const Offset(3, 3),
              blurRadius: 5,
            ),
            BoxShadow(
              color: NeumorphicColors.getLightShadow(baseColor),
              offset: const Offset(-3, -3),
              blurRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: AnimatedMarker(player: player),
        ),
      ),
    );
  }
}

class AnimatedMarker extends StatefulWidget {
  final Player player;

  const AnimatedMarker({super.key, required this.player});

  @override
  State<AnimatedMarker> createState() => _AnimatedMarkerState();
}

class _AnimatedMarkerState extends State<AnimatedMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Player? _lastPlayer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.player != Player.none) {
      _controller.forward();
    }
    _lastPlayer = widget.player;
  }

  @override
  void didUpdateWidget(AnimatedMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.player != _lastPlayer) {
      if (widget.player == Player.none) {
        _controller.reset();
      } else {
        _controller.forward(from: 0.0);
      }
      _lastPlayer = widget.player;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.player == Player.none) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: MarkerPainter(
            player: widget.player,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class MarkerPainter extends CustomPainter {
  final Player player;
  final double progress;

  MarkerPainter({required this.player, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double padding = size.width * 0.25;

    if (player == Player.X) {
      paint.color = Colors.redAccent;
      if (progress > 0) {
        double p1 = (progress * 2).clamp(0.0, 1.0);
        canvas.drawLine(
          Offset(padding, padding),
          Offset(
            padding + (size.width - 2 * padding) * p1,
            padding + (size.height - 2 * padding) * p1,
          ),
          paint,
        );
      }
      if (progress > 0.5) {
        double p2 = ((progress - 0.5) * 2).clamp(0.0, 1.0);
        canvas.drawLine(
          Offset(size.width - padding, padding),
          Offset(
            (size.width - padding) - (size.width - 2 * padding) * p2,
            padding + (size.height - 2 * padding) * p2,
          ),
          paint,
        );
      }
    } else if (player == Player.O) {
      paint.color = const Color(0xFF1A237E);
      final rect = Rect.fromLTRB(
        padding,
        padding,
        size.width - padding,
        size.height - padding,
      );
      canvas.drawArc(
        rect,
        -1.5,
        6.28 * progress,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
