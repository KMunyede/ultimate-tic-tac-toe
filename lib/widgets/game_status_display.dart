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
        return text.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              );
      },
    );
  }

  String _getStatusText(GameController game) {
    if (game.isOverallGameOver) {
      if (game.overallWinner != null) {
        return 'Player ${game.overallWinner == Player.X ? 'X' : 'O'} wins!';
      } else {
        return 'It\'s a draw!';
      }
    } else {
      return 'Player ${game.currentPlayer == Player.X ? 'X' : 'O'}\'s turn';
    }
  }
}
