import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../game_controller.dart';
import 'game_board.dart';
import 'game_status_display.dart';
import 'score_display.dart';

class BoardWidget extends StatelessWidget {
  const BoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ScoreDisplay(),
            Expanded(
              child: _buildBoardLayout(context, screenWidth, screenHeight),
            ),
            const GameStatusDisplay(),
          ],
        );
      },
    );
  }

  Widget _buildBoardLayout(
      BuildContext context, double screenWidth, double screenHeight) {
    final game = context.watch<GameController>();
    final boards = game.boards;

    switch (boards.length) {
      case 1:
        return _buildSingleBoard(context, screenWidth, screenHeight);
      case 2:
        return _buildDualBoard(context, screenWidth, screenHeight);
      case 3:
        return _buildTrioBoard(context, screenWidth, screenHeight);
      default:
        return Container(); // Should not happen
    }
  }

  Widget _buildSingleBoard(
      BuildContext context, double screenWidth, double screenHeight) {
    final boardSize = screenWidth < screenHeight ? screenWidth : screenHeight;
    return Center(
      child: GameBoardWidget(
        boardIndex: 0,
        size: boardSize * 0.8,
      ),
    );
  }

  Widget _buildDualBoard(
      BuildContext context, double screenWidth, double screenHeight) {
    final boardSize = (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.4;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GameBoardWidget(boardIndex: 0, size: boardSize),
        const SizedBox(height: 20),
        GameBoardWidget(boardIndex: 1, size: boardSize),
      ],
    );
  }

  Widget _buildTrioBoard(
      BuildContext context, double screenWidth, double screenHeight) {
    if (screenWidth > screenHeight) {
      // Horizontal layout
      final boardSize = screenHeight * 0.4;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameBoardWidget(boardIndex: 0, size: boardSize),
              const SizedBox(width: 20),
              GameBoardWidget(boardIndex: 1, size: boardSize),
            ],
          ),
          const SizedBox(height: 20),
          GameBoardWidget(boardIndex: 2, size: boardSize),
        ],
      );
    } else {
      // Vertical layout
      final boardSize = screenWidth * 0.4;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GameBoardWidget(boardIndex: 0, size: boardSize),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameBoardWidget(boardIndex: 1, size: boardSize),
              const SizedBox(width: 20),
              GameBoardWidget(boardIndex: 2, size: boardSize),
            ],
          ),
        ],
      );
    }
  }
}
