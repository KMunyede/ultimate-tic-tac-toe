import 'dart:async';
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
  double xRotation = 0;
  double yRotation = 0;
  StreamSubscription<AccelerometerEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // Normalize accelerometer data to a reasonable tilt range (approx -0.1 to 0.1 radians)
          // Adjust sensitivity by changing the divisor (e.g., 50.0)
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

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..rotateX(xRotation)
        ..rotateY(yRotation),
      alignment: FractionalOffset.center,
      child: Container(
        decoration: BoxDecoration(
          color: boardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: NeumorphicColors.getDarkShadow(themeBgColor),
              offset: Offset(6 + (yRotation * 10), 6 + (xRotation * 10)),
              blurRadius: 12,
            ),
            BoxShadow(
              color: NeumorphicColors.getLightShadow(themeBgColor),
              offset: Offset(-6 + (yRotation * 10), -6 + (xRotation * 10)),
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
              xTilt: xRotation,
              yTilt: yRotation,
            );
          },
        ),
      ),
    );
  }
}

class NeumorphicCell extends StatelessWidget {
  final VoidCallback onTap;
  final Player player;
  final Color baseColor;
  final double xTilt;
  final double yTilt;

  const NeumorphicCell({
    super.key,
    required this.onTap,
    required this.player,
    required this.baseColor,
    required this.xTilt,
    required this.yTilt,
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
              // Dynamic shadow offset based on tilt
              offset: Offset(3 + (yTilt * 20), 3 + (xTilt * 20)),
              blurRadius: 5,
            ),
            BoxShadow(
              color: NeumorphicColors.getLightShadow(baseColor),
              offset: Offset(-3 + (yTilt * 20), -3 + (xTilt * 20)),
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
