import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_controller.dart';
import 'board_widget.dart';

class MultiBoardView extends StatelessWidget {
  const MultiBoardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        final boards = controller.boards;
        final int count = boards.length;

        if (count == 0) return const SizedBox.shrink();

        return Stack(
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(controller.shakeCounter),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticIn,
              builder: (context, value, child) {
                final double shakeOffset = (value > 0 && value < 1.0)
                    ? sin(value * pi * 4) * 15.0
                    : 0.0;
                return Transform.translate(
                  offset: Offset(shakeOffset, 0),
                  child: child,
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Determine optimal grid dimensions (cols x rows)
                  int cols, rows;
                  if (count <= 1) { cols = 1; rows = 1; }
                  else if (count <= 2) { cols = 2; rows = 1; }
                  else if (count <= 4) { cols = 2; rows = 2; }
                  else if (count <= 6) { cols = 3; rows = 2; }
                  else { cols = 3; rows = 3; } // Up to 9 boards

                  // Adjust for Landscape on small screens
                  if (constraints.maxWidth > constraints.maxHeight && count > 1) {
                    if (count <= 3) { cols = count; rows = 1; }
                    else if (count <= 6) { cols = 3; rows = 2; }
                  }

                  final double spacing = count > 4 ? 8.0 : 16.0;
                  final double padding = 12.0;

                  // The total space available for the grid
                  final double availW = constraints.maxWidth - (padding * 2);
                  final double availH = constraints.maxHeight - (padding * 2);

                  // Calculate max board size:
                  // Each cell takes (boardSize + spacing) in total.
                  final double boardSize = min(
                    (availW / cols) - spacing,
                    (availH / rows) - spacing,
                  ).clamp(80.0, 450.0);

                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(rows, (r) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(cols, (c) {
                              int index = r * cols + c;
                              if (index >= count) return const SizedBox.shrink();
                              
                              return Padding(
                                padding: EdgeInsets.all(spacing / 2),
                                child: FlyInWrapper(
                                  key: ValueKey('bw_${boards[index].hashCode}_$index'),
                                  index: index,
                                  child: SizedBox(
                                    width: boardSize,
                                    height: boardSize,
                                    child: BoardWidget(boardIndex: index),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (controller.isOverallGameOver && controller.matchWinner != null)
              const Positioned.fill(child: ConfettiOverlay()),
          ],
        );
      },
    );
  }
}

class FlyInWrapper extends StatefulWidget {
  final Widget child;
  final int index;

  const FlyInWrapper({super.key, required this.child, required this.index});

  @override
  State<FlyInWrapper> createState() => _FlyInWrapperState();
}

class _FlyInWrapperState extends State<FlyInWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Staggered pop-in effect
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(position: _slideAnimation, child: widget.child),
      ),
    );
  }
}

// Confetti logic remains the same (unchanged)
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiPiece> _pieces = [];
  final Random _random = Random();

  final List<Color> _colors = [
    Colors.red,
    Colors.yellow,
    Colors.pink,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addListener(() {
            setState(() {
              for (var piece in _pieces) {
                piece.update();
              }
            });
          });

    _initConfetti();
    _controller.repeat();
  }

  void _initConfetti() {
    for (int i = 0; i < 120; i++) {
      _pieces.add(
        _ConfettiPiece(
          color: _colors[_random.nextInt(_colors.length)],
          x: _random.nextDouble(),
          y: _random.nextDouble() * -1.5,
          size: _random.nextDouble() * 10 + 5,
          rotation: _random.nextDouble() * 2 * pi,
          speed: _random.nextDouble() * 0.015 + 0.005,
          drift: (_random.nextDouble() - 0.5) * 0.01,
        ),
      );
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
      child: CustomPaint(painter: _ConfettiPainter(pieces: _pieces)),
    );
  }
}

class _ConfettiPiece {
  final Color color;
  final double size;
  final double speed;
  final double drift;
  double x;
  double y;
  double rotation;

  _ConfettiPiece({
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.speed,
    required this.drift,
  });

  void update() {
    y += speed;
    x += drift;
    rotation += 0.05;
    if (y > 1.1) {
      y = -0.1;
      x = Random().nextDouble();
    }
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;

  _ConfettiPainter({required this.pieces});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var piece in pieces) {
      paint.color = piece.color;
      canvas.save();
      canvas.translate(piece.x * size.width, piece.y * size.height);
      canvas.rotate(piece.rotation);

      final Path path = Path()
        ..moveTo(0, -piece.size / 2)
        ..lineTo(piece.size / 2, 0)
        ..lineTo(0, piece.size / 2)
        ..lineTo(-piece.size / 2, 0)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
