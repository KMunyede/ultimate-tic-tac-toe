import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tictactoe/game_controller.dart';
import 'package:tictactoe/models/player.dart';

class GameStatusDisplay extends StatelessWidget {
  const GameStatusDisplay({super.key});

  String _getStatusMessage(GameController gameController) {
    if (gameController.overallWinner != null) {
      return 'Player ${gameController.overallWinner!.name} Wins the Round!';
    }
    if (gameController.isDraw) {
      return 'It\'s a Draw!';
    }
    return 'Player ${gameController.currentPlayer.name}\'s Turn';
  }

  @override
  Widget build(BuildContext context) {
    final gameController = context.watch<GameController>();
    return Text(
      _getStatusMessage(gameController),
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
