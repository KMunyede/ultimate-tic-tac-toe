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
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                // Global horizontal jolt
                final double shakeOffset = sin(value * pi * 2) * 12.0;
                return Transform.translate(
                  offset: Offset(shakeOffset, 0),
                  child: child,
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double spacing = 16.0;
                  const double padding = 12.0;
                  const double labelAreaHeight = 0.0;

                  final int itemsPerRow;
                  if (count == 1) {
                    itemsPerRow = 1;
                  } else if (count == 2) {
                    if (constraints.maxWidth > constraints.maxHeight) {
                      itemsPerRow = 2;
                    } else {
                      itemsPerRow = 1;
                    }
                  } else if (count > 6) {
                    itemsPerRow = 3;
                  } else {
                    itemsPerRow = 2;
                  }

                  final int rowCount = (count / itemsPerRow).ceil();
                  final double maxBoardWidth =
                      (constraints.maxWidth - (padding * 2) - (spacing * (itemsPerRow - 1))) / itemsPerRow;
                  final double maxBoardHeight =
                      (constraints.maxHeight - (padding * 2) - (spacing * (rowCount - 1)) - (labelAreaHeight * rowCount)) / rowCount;

                  final double boardSize = min(maxBoardWidth, maxBoardHeight).clamp(100.0, 600.0);

                  List<Widget> rows = [];
                  for (int i = 0; i < count; i += itemsPerRow) {
                    List<Widget> rowChildren = [];
                    for (int j = 0; j < itemsPerRow; j++) {
                      final int boardIndex = i + j;
                      if (boardIndex < count) {
                        rowChildren.add(
                          FlyInWrapper(
                            key: ValueKey('flyin_${boards[boardIndex].hashCode}_$boardIndex'),
                            index: boardIndex,
                            child: _buildBoard(context, boardIndex, boardSize),
                          ),
                        );
                      }
                    }

                    List<Widget> spacedRowChildren = [];
                    if (rowChildren.isNotEmpty) {
                      spacedRowChildren.add(rowChildren.first);
                      for (int k = 1; k < rowChildren.length; k++) {
                        spacedRowChildren.add(const SizedBox(width: spacing));
                        spacedRowChildren.add(rowChildren[k]);
                      }
                    }

                    rows.add(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: spacedRowChildren,
                      ),
                    );

                    if (i + itemsPerRow < count) {
                      rows.add(const SizedBox(height: spacing));
                    }
                  }

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: rows,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (controller.isOverallGameOver && controller.matchWinner != null)
              const Positioned.fill(
                child: ConfettiOverlay(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBoard(BuildContext context, int index, double size) {
    return SizedBox(
      width: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: BoardWidget(boardIndex: index),
      ),
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

class _FlyInWrapperState extends State<FlyInWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    final double startOffsetX = widget.index % 2 == 0 ? -1.5 : 1.5;
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(startOffsetX, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack, // Functionally identical to backOut
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) {
        _controller.forward();
      }
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
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
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
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        setState(() {
          for (var piece in _pieces) {
            piece.update(_controller.value);
          }
        });
      });

    _initConfetti();
    _controller.repeat();
  }

  void _initConfetti() {
    for (int i = 0; i < 100; i++) {
      _pieces.add(_ConfettiPiece(
        color: _colors[_random.nextInt(_colors.length)],
        x: _random.nextDouble(),
        y: _random.nextDouble() * -1.0,
        size: _random.nextDouble() * 8 + 4,
        rotation: _random.nextDouble() * 2 * pi,
        speed: _random.nextDouble() * 2 + 1,
        drift: (_random.nextDouble() - 0.5) * 0.2,
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
        painter: _ConfettiPainter(pieces: _pieces),
      ),
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

  void update(double progress) {
    y += 0.01 * speed;
    x += drift;
    rotation += 0.1;
    if (y > 1.0) {
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
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: piece.size, height: piece.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
