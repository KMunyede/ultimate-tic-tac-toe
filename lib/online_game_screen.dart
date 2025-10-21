import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_service.dart';
import 'game_screen.dart'; // For Player enum and other UI widgets
import 'models/game_model.dart';
import 'online_game_controller.dart';
import 'sound_manager.dart';

/// The screen that hosts an online Tic-Tac-Toe game.
///
/// It uses a `ChangeNotifierProvider` to create and provide the `OnlineGameController`
/// to all its children. This controller manages the state of the online game.
class OnlineGameScreen extends StatelessWidget {
  final String gameId;

  const OnlineGameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OnlineGameController(
        context.read<FirebaseService>(),
        context.read<SoundManager>(),
        gameId,
      ),
      child: const _OnlineGameView(),
    );
  }
}

class _OnlineGameView extends StatelessWidget {
  const _OnlineGameView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnlineGameController>();
    final game = controller.game;

    if (game == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // This is the new widget you requested!
            OnlinePlayerInfo(game: game),
            const SizedBox(height: 20),
            // We can reuse the existing GameBoard widget.
            Expanded(
              child: GameBoard(
                // You may need to adjust these parameters based on your theming
                gradientStart: Theme.of(context).colorScheme.surface,
                gradientEnd: Theme.of(context).colorScheme.secondary,
                currentTheme: context.read<SettingsController>().currentTheme,
              ),
            ),
            const SizedBox(height: 20),
            // Display game status
            Text(
              _getGameStatus(game, context.read<FirebaseService>().currentUser!.uid),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  String _getGameStatus(Game game, String currentUserId) {
    switch (game.status) {
      case GameStatus.waiting:
        return 'Waiting for another player...';
      case GameStatus.finished:
        if (game.isDraw) return "It's a Draw!";
        return game.winnerUid == currentUserId ? 'You Won!' : 'You Lost!';
      case GameStatus.in_progress:
        return game.currentPlayerUid == currentUserId ? 'Your Turn' : "Opponent's Turn";
    }
  }
}

/// A widget to display the names of the players in an online game.
class OnlinePlayerInfo extends StatelessWidget {
  final Game game;
  const OnlinePlayerInfo({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlayerCard(context, 'Player X', game.playerXName, game.currentPlayerUid == game.players['playerX_uid']),
        const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        _buildPlayerCard(context, 'Player O', game.playerOName, game.currentPlayerUid == game.players['playerO_uid']),
      ],
    );
  }

  Widget _buildPlayerCard(BuildContext context, String playerRole, String playerName, bool isCurrentTurn) {
    return Card(
      color: isCurrentTurn ? Theme.of(context).colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(playerRole, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(playerName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
