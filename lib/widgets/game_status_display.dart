import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tictactoe/game_controller.dart';
import 'package:tictactoe/models/player.dart';

class GameStatusDisplay extends StatelessWidget {
  const GameStatusDisplay({super.key});

  String _getStatusMessage(GameController gameController) {
    if (gameController.overallWinner != null) {
      return 'Player ${gameController.overallWinner!.name} Wins!';
    }
    if (gameController.isOverallDraw) {
      return 'It\'s a Draw!';
    }
    return 'Player ${gameController.currentPlayer.name}\'s Turn';
  }

  @override
  Widget build(BuildContext context) {
    final gameController = context.watch<GameController>();
    final theme = Theme.of(context);

    // Define a text style that can be reused and adapted
    final baseStyle = TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(blurRadius: 4.0, color: Colors.black.withAlpha(77), offset: const Offset(2, 2))
        ]
    );

    // Choose color based on the game state for better visual feedback
    Color statusColor;
    if (gameController.overallWinner != null) {
        statusColor = gameController.overallWinner! == Player.X ? Colors.blue.shade300 : Colors.red.shade300;
    } else if (gameController.isOverallDraw) {
        statusColor = Colors.grey.shade400;
    } else {
        statusColor = theme.colorScheme.onSurface; // Default color for turns
    }

    return Text(
      _getStatusMessage(gameController),
      style: baseStyle.copyWith(color: statusColor),
      textAlign: TextAlign.center,
    );
  }
}
