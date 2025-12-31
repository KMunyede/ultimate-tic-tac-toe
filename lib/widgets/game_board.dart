import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tictactoe/app_theme.dart';
import 'package:tictactoe/game_controller.dart';
import 'package:tictactoe/models/player.dart';

class GameBoard extends StatelessWidget {
  final int boardIndex;
  final Color gradientStart;
  final Color gradientEnd;
  final AppTheme currentTheme;

  const GameBoard({
    super.key,
    required this.boardIndex,
    required this.gradientStart,
    required this.gradientEnd,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    final gameController = context.watch<GameController>();
    final board = gameController.boards[boardIndex];
    final winningLine = gameController.getWinningLineForBoard(boardIndex);
    final winner = gameController.getWinnerForBoard(boardIndex);
    final theme = Theme.of(context);

    final Color shadowColor, lightShadowColor;
    if (currentTheme == const AppTheme(name: 'Forest Green', mainColor: Color(0xFF2D6A4F))) {
      shadowColor = theme.colorScheme.primary;
      lightShadowColor = theme.colorScheme.surface.withOpacity(0.8);
    } else {
      shadowColor = Color.lerp(theme.scaffoldBackgroundColor, Colors.black, 0.4)!;
      lightShadowColor = Color.lerp(theme.scaffoldBackgroundColor, Colors.white, 0.5)!;
    }

    // UI UPDATE: Constrained the board size to 250px by 250px and wrapped in a Center widget.
    // The tiles will proportionally adjust because GridView uses SliverGridDelegateWithFixedCrossAxisCount.
    return Center(
      child: SizedBox(
        width: 250,
        height: 250,
        child: AspectRatio(
          aspectRatio: 1,
            child: Stack(
              children: [
                // UI UPDATE: Reduced tile size by increasing spacing (15.0 -> 25.0).
                // This effectively shrinks each tile by -10px width and -10px height
                // because the total space available remains constant while gaps grow.
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10.0, // Adjusted back to a smaller gap for the smaller board size
                    mainAxisSpacing: 10.0,
                  ),
                itemCount: 9,
                itemBuilder: (context, cellIndex) {
                  return GameCell(
                    player: board[cellIndex],
                    onTap: () => gameController.handleTap(boardIndex, cellIndex),
                    gradientStart: gradientStart,
                    gradientEnd: gradientEnd,
                    shadowColor: shadowColor,
                    lightShadowColor: lightShadowColor,
                  );
                },
                ),
                if (winner != null && winningLine != null)
                  AnimatedWinningLine(
                    winningLine: winningLine,
                    color: winner == Player.X
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF388E3C),
                  ),
              ],
            )
        ),
      ),
    );
  }
}

class GameCell extends StatefulWidget {
  final Player player;
  final VoidCallback onTap;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadowColor;
  final Color lightShadowColor;

  const GameCell({
    super.key,
    required this.player,
    required this.onTap,
    required this.gradientStart,
    required this.gradientEnd,
    required this.shadowColor,
    required this.lightShadowColor,
  });

  @override
  State<GameCell> createState() => _GameCellState();
}

class _GameCellState extends State<GameCell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    if (widget.player != Player.none) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(GameCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.player != oldWidget.player) {
      if (widget.player == Player.none) {
        _controller.reset();
      } else {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.gradientStart, widget.gradientEnd]),
          boxShadow: [
            BoxShadow(color: widget.shadowColor, offset: const Offset(5, 5), blurRadius: 10),
            BoxShadow(color: widget.lightShadowColor, offset: const Offset(-5, -5), blurRadius: 10),
          ],
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _PlayerMarkPainter(player: widget.player, animationValue: _animation.value),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlayerMarkPainter extends CustomPainter {
  final Player player;
  final double animationValue;

  _PlayerMarkPainter({required this.player, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.1
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final halfSize = size.width / 2 * 0.6;

    if (player == Player.X) {
      paint.color = const Color(0xFFD32F2F);
      final firstStrokeProgress = Interval(0.0, 0.5, curve: Curves.easeIn).transform(animationValue);
      final secondStrokeProgress = Interval(0.5, 1.0, curve: Curves.easeOut).transform(animationValue);

      if (firstStrokeProgress > 0.0) {
        final p1 = Offset(center.dx - halfSize, center.dy - halfSize);
        final p2 = Offset(center.dx + halfSize, center.dy + halfSize);
        canvas.drawLine(p1, Offset.lerp(p1, p2, firstStrokeProgress)!, paint);
      }
      if (secondStrokeProgress > 0.0) {
        final p3 = Offset(center.dx + halfSize, center.dy - halfSize);
        final p4 = Offset(center.dx - halfSize, center.dy + halfSize);
        canvas.drawLine(p3, Offset.lerp(p3, p4, secondStrokeProgress)!, paint);
      }
    } else if (player == Player.O) {
      paint.color = const Color(0xFF388E3C);
      final rect = Rect.fromCircle(center: center, radius: halfSize);
      canvas.drawArc(rect, -90 * (3.14 / 180), 360 * (3.14 / 180) * animationValue, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlayerMarkPainter oldDelegate) {
    return player != oldDelegate.player || (animationValue != oldDelegate.animationValue && player != Player.none);
  }
}

class AnimatedWinningLine extends StatefulWidget {
  final List<int> winningLine;
  final Color color;

  const AnimatedWinningLine({
    super.key,
    required this.winningLine,
    required this.color,
  });

  @override
  State<AnimatedWinningLine> createState() => _AnimatedWinningLineState();
}

class _AnimatedWinningLineState extends State<AnimatedWinningLine>
    with TickerProviderStateMixin {
  late AnimationController _drawController;
  late Animation<double> _drawAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _drawAnimation = CurvedAnimation(parent: _drawController, curve: Curves.easeOutCubic);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _drawController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.repeat(reverse: true);
      }
    });

    _drawController.forward();
  }

  @override
  void dispose() {
    _drawController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_drawAnimation, _pulseAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: _WinningLinePainter(
            winningLine: widget.winningLine,
            color: widget.color,
            drawProgress: _drawAnimation.value,
            pulseProgress: _pulseAnimation.value,
            spacing: 10.0, // Pass spacing to the painter
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _WinningLinePainter extends CustomPainter {
  final List<int> winningLine;
  final Color color;
  final double drawProgress;
  final double pulseProgress;
  final double spacing; // Added spacing

  _WinningLinePainter({
    required this.winningLine,
    required this.color,
    required this.drawProgress,
    required this.pulseProgress,
    required this.spacing,
  }) : super();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    // Adjusted cell size to account for spacing
    final cellSize = (size.width - 2 * spacing) / 3;

    Offset getCellCenter(int index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(
        col * (cellSize + spacing) + cellSize / 2,
        row * (cellSize + spacing) + cellSize / 2,
      );
    }

    final startPoint = getCellCenter(winningLine.first);
    final endPoint = getCellCenter(winningLine.last);

    final animatedEndPoint = Offset.lerp(startPoint, endPoint, drawProgress)!;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.5 + (pulseProgress * 0.5))
      ..strokeWidth = 12.0 + (pulseProgress * 8.0)
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, pulseProgress * 5);

    if (drawProgress == 1.0) {
      canvas.drawLine(startPoint, animatedEndPoint, glowPaint);
    }
    canvas.drawLine(startPoint, animatedEndPoint, paint);
  }

  @override
  bool shouldRepaint(covariant _WinningLinePainter oldDelegate) {
    return winningLine != oldDelegate.winningLine ||
           color != oldDelegate.color ||
           drawProgress != oldDelegate.drawProgress ||
           pulseProgress != oldDelegate.pulseProgress;
  }
}
