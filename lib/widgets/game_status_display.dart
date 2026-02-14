import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game_controller.dart';
import '../models/player.dart';

class GameStatusDisplay extends StatelessWidget {
  const GameStatusDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final text = _getStatusText(game);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        );
      },
    );
  }

  String _getStatusText(GameController game) {
    if (game.isOverallGameOver) {
      if (game.matchWinner != null) {
        return 'Player ${game.matchWinner == Player.X ? 'X' : 'O'} Wins!';
      } else {
        return "It's a Draw!";
      }
    } else if (game.isAiThinking) {
      return 'AI is thinking...';
    } else {
      return "Player ${game.currentPlayer == Player.X ? 'X' : 'O'}'s Turn";
    }
  }
}
