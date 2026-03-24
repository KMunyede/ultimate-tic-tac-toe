// lib/widgets/board_widget.dart
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
    // Sensors are only supported on mobile platforms. 
    // Checking platform to avoid MissingPluginException on Windows/Web.
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        if (mounted) {
          setState(() {
            yRotation = (event.x / 10.0).clamp(-0.1, 0.1);
            xRotation = (-event.y / 10.0).clamp(-0.1, 0.1);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    if (widget.boardIndex >= controller.boards.length) {
      return const SizedBox.shrink();
    }

    final board = controller.boards[widget.boardIndex];
    final theme = Theme.of(context);
    final themeBgColor = theme.scaffoldBackgroundColor;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth;
        
        // ADAPTIVE SCALING FACTORS
        final double padding = boardSize * 0.08; // 8% padding
        final double spacing = boardSize * 0.05; // 5% spacing between cells
        final double borderRadius = boardSize * 0.12;
        final double shadowOffset = (boardSize * 0.04).clamp(2.0, 10.0);
        final double shadowBlur = shadowOffset * 2;

        final hsl = HSLColor.fromColor(themeBgColor);
        final boardColor = hsl.withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0)).toColor();

        return TweenAnimationBuilder<double>(
          key: ValueKey(board.winner),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            final double shake = (board.winner != null && value < 1.0) ? sin(value * pi * 4) * (boardSize * 0.05) : 0.0;
            return Transform.translate(
              offset: Offset(shake, 0),
              child: Transform(
                transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(xRotation)..rotateY(yRotation),
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: boardColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(color: NeumorphicColors.getDarkShadow(themeBgColor), offset: Offset(shadowOffset, shadowOffset), blurRadius: shadowBlur),
                    BoxShadow(color: NeumorphicColors.getLightShadow(themeBgColor), offset: Offset(-shadowOffset, -shadowOffset), blurRadius: shadowBlur),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, cellIndex) {
                      return NeumorphicCell(
                        onTap: board.isGameOver ? null : () => controller.makeMove(widget.boardIndex, cellIndex),
                        player: board.cells[cellIndex],
                        baseColor: boardColor,
                        isBlocked: board.isGameOver,
                        boardSize: boardSize,
                      );
                    },
                  ),
                ),
              ),
              if (board.winner != null && board.winningLine != null)
                Positioned.fill(
                  child: WinningLineWidget(
                    winner: board.winner!,
                    winningLine: board.winningLine!,
                    boardSize: boardSize,
                    padding: padding,
                    spacing: spacing,
                  ),
                ),
              if (board.winner != null)
                Positioned.fill(child: BoardWinnerEffect(winner: board.winner!, boardSize: boardSize)),
            ],
          ),
        );
      },
    );
  }
}

class WinningLineWidget extends StatefulWidget {
  final Player winner;
  final List<int> winningLine;
  final double boardSize;
  final double padding;
  final double spacing;

  const WinningLineWidget({
    super.key,
    required this.winner,
    required this.winningLine,
    required this.boardSize,
    required this.padding,
    required this.spacing,
  });

  @override
  State<WinningLineWidget> createState() => _WinningLineWidgetState();
}

class _WinningLineWidgetState extends State<WinningLineWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
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
      builder: (context, child) => CustomPaint(
        painter: WinningLinePainter(
          winner: widget.winner,
          winningLine: widget.winningLine,
          progress: _controller.value,
          boardSize: widget.boardSize,
          padding: widget.padding,
          spacing: widget.spacing,
        ),
      ),
    );
  }
}

class WinningLinePainter extends CustomPainter {
  final Player winner;
  final List<int> winningLine;
  final double progress, boardSize, padding, spacing;

  WinningLinePainter({
    required this.winner,
    required this.winningLine,
    required this.progress,
    required this.boardSize,
    required this.padding,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = boardSize * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    paint.color = (winner == Player.X ? Colors.red.shade900 : const Color(0xFF0D47A1)).withValues(alpha: 0.8);

    final double cellSize = (boardSize - (padding * 2) - (spacing * 2)) / 3;

    Offset getCenter(int index) {
      final int row = index ~/ 3;
      final int col = index % 3;
      return Offset(
        padding + col * (cellSize + spacing) + cellSize / 2,
        padding + row * (cellSize + spacing) + cellSize / 2,
      );
    }

    final start = getCenter(winningLine.first);
    final end = getCenter(winningLine.last);
    final currentEnd = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );

    canvas.drawLine(start, currentEnd, paint);
  }

  @override
  bool shouldRepaint(WinningLinePainter oldDelegate) => oldDelegate.progress != progress;
}

class BoardWinnerEffect extends StatefulWidget {
  final Player winner;
  final double boardSize;

  const BoardWinnerEffect({super.key, required this.winner, required this.boardSize});

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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..addListener(() => setState(() {}));
    _createParticles();
    _controller.forward();
  }

  void _createParticles() {
    final color = widget.winner == Player.X ? Colors.red : const Color(0xFF0D47A1);
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
      child: CustomPaint(painter: ParticlePainter(particles: _particles, progress: _controller.value, boardSize: widget.boardSize)),
    );
  }
}

class Particle {
  final Color color;
  final double angle, speed, size;
  Particle({required this.color, required this.angle, required this.speed, required this.size});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress, boardSize;
  ParticlePainter({required this.particles, required this.progress, required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    for (var p in particles) {
      final distance = p.speed * progress * (boardSize * 0.5);
      final x = center.dx + cos(p.angle) * distance;
      final y = center.dy + sin(p.angle) * distance;
      paint.color = p.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0) * p.color.a);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class NeumorphicCell extends StatefulWidget {
  final VoidCallback? onTap;
  final Player player;
  final Color baseColor;
  final bool isBlocked;
  final double boardSize;

  const NeumorphicCell({
    super.key,
    required this.onTap,
    required this.player,
    required this.baseColor,
    required this.boardSize,
    this.isBlocked = false,
  });

  @override
  State<NeumorphicCell> createState() => _NeumorphicCellState();
}

class _NeumorphicCellState extends State<NeumorphicCell> with TickerProviderStateMixin {
  late AnimationController _pressController, _shakeController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100), lowerBound: 0.92, upperBound: 1.0, value: 1.0);
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double borderRadius = widget.boardSize * 0.08;
    final double shadowOffset = (widget.boardSize * 0.02).clamp(1.0, 6.0);
    final double shadowBlur = shadowOffset * 2;

    return GestureDetector(
      onTapDown: !widget.isBlocked ? (_) => _pressController.reverse() : null,
      onTapUp: !widget.isBlocked ? (_) => _pressController.forward() : null,
      onTap: () => widget.onTap != null ? widget.onTap!() : (widget.isBlocked ? _shakeController.forward(from: 0.0) : null),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) => Transform.translate(
          offset: Offset(sin(_shakeController.value * pi * 4) * (widget.boardSize * 0.03), 0),
          child: ScaleTransition(scale: _pressController, child: child),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: widget.isBlocked && widget.player == Player.none ? widget.baseColor.withValues(alpha: 0.3) : widget.baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(color: NeumorphicColors.getDarkShadow(widget.baseColor), offset: Offset(shadowOffset, shadowOffset), blurRadius: shadowBlur),
              BoxShadow(color: NeumorphicColors.getLightShadow(widget.baseColor), offset: Offset(-shadowOffset, -shadowOffset), blurRadius: shadowBlur),
            ],
          ),
          child: Center(child: AnimatedMarker(player: widget.player, boardSize: widget.boardSize)),
        ),
      ),
    );
  }
}

class AnimatedMarker extends StatefulWidget {
  final Player player;
  final double boardSize;
  const AnimatedMarker({super.key, required this.player, required this.boardSize});

  @override
  State<AnimatedMarker> createState() => _AnimatedMarkerState();
}

class _AnimatedMarkerState extends State<AnimatedMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Player? _lastPlayer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    if (widget.player != Player.none) {
      _controller.forward();
    }
    _lastPlayer = widget.player;
  }

  @override
  void didUpdateWidget(AnimatedMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.player != _lastPlayer) {
      if (widget.player == Player.none) _controller.reset();
      else _controller.forward(from: 0.0);
      _lastPlayer = widget.player;
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.player == Player.none) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        size: Size.infinite,
        painter: MarkerPainter(player: widget.player, progress: _controller.value, boardSize: widget.boardSize),
      ),
    );
  }
}

class MarkerPainter extends CustomPainter {
  final Player player;
  final double progress, boardSize;
  MarkerPainter({required this.player, required this.progress, required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = (boardSize * 0.04).clamp(2.0, 10.0)..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final double padding = size.width * 0.25;
    if (player == Player.X) {
      paint.color = Colors.red.withValues(alpha: 0.9);
      if (progress > 0) {
        double p1 = (progress * 2).clamp(0.0, 1.0);
        canvas.drawLine(Offset(padding, padding), Offset(padding + (size.width - 2 * padding) * p1, padding + (size.height - 2 * padding) * p1), paint);
      }
      if (progress > 0.5) {
        double p2 = ((progress - 0.5) * 2).clamp(0.0, 1.0);
        canvas.drawLine(Offset(size.width - padding, padding), Offset((size.width - padding) - (size.width - 2 * padding) * p2, padding + (size.height - 2 * padding) * p2), paint);
      }
    } else if (player == Player.O) {
      paint.color = const Color(0xFF0D47A1).withValues(alpha: 0.9);
      canvas.drawArc(Rect.fromLTRB(padding, padding, size.width - padding, size.height - padding), -1.5, 6.28 * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) => oldDelegate.progress != progress;
}
