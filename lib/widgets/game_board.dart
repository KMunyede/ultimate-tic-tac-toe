import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tictactoe/app_theme.dart';
import 'package:tictactoe/game_controller.dart';
import 'package:tictactoe/models/player.dart';

class GameBoardWidget extends StatelessWidget {
  final int boardIndex;
  final Color gradientStart;
  final Color gradientEnd;
  final AppTheme currentTheme;

  const GameBoardWidget({
    super.key,
    required this.boardIndex,
    required this.gradientStart,
    required this.gradientEnd,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final board = game.boards[boardIndex];

    final boardSize = MediaQuery.of(context).size.width < 600
        ? MediaQuery.of(context).size.width * 0.8
        : 300.0;

    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [gradientStart, gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => game.handleTap(boardIndex, index),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: currentTheme.mainColor.withAlpha(128)),
                      ),
                      child: Center(
                        child: _buildPlayerIcon(board.cells[index]),
                      ),
                    ),
                  );
                },
              ),
              if (board.winningLine != null)
                CustomPaint(
                  size: Size.infinite,
                  painter: WinningLinePainter(
                    winningLine: board.winningLine!,
                    lineColor: board.winner == Player.X ? Colors.blue.withAlpha(204) : Colors.red.withAlpha(204),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerIcon(Player player) {
    if (player == Player.none) return const SizedBox.shrink();
    final icon = player == Player.X ? Icons.close : Icons.circle_outlined;
    final color = player == Player.X ? Colors.blue : Colors.red;
    return Icon(
      icon,
      size: 50.0,
      color: color,
      shadows: [
        Shadow(blurRadius: 8.0, color: color.withAlpha(128)),
      ],
    );
  }
}

class WinningLinePainter extends CustomPainter {
  final List<int> winningLine;
  final Color lineColor;
  final double strokeWidth;

  WinningLinePainter({
    required this.winningLine,
    this.lineColor = Colors.white,
    this.strokeWidth = 6.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final double cellWidth = size.width / 3;
    final double cellHeight = size.height / 3;

    Offset getCellCenter(int index) {
      final double x = (index % 3) * cellWidth + cellWidth / 2;
      final double y = (index ~/ 3) * cellHeight + cellHeight / 2;
      return Offset(x, y);
    }

    final startPoint = getCellCenter(winningLine[0]);
    final endPoint = getCellCenter(winningLine[2]);

    canvas.drawLine(startPoint, endPoint, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
