import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tictactoe/app_theme.dart';
import 'package:tictactoe/settings_controller.dart' hide AppTheme;
import 'package:tictactoe/widgets/game_board.dart';
import 'firebase_service.dart';
import 'models/game_model.dart' as game_model;
import 'online_game_controller.dart';
import 'sound_manager.dart';

class OnlineGameScreen extends StatefulWidget {
  final String gameId;

  const OnlineGameScreen({super.key, required this.gameId});

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  @override
  Widget build(BuildContext context) {
    // Set the orientation based on the screen size when the widget builds.
    _setOrientation(context);

    return ChangeNotifierProvider(
      create: (context) => OnlineGameController(
        context.read<FirebaseService>(),
        context.read<SoundManager>(),
        widget.gameId,
      ),
      child: Consumer<OnlineGameController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.error != null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: Center(
                child: Text(
                  controller.error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final game = controller.game!;
          final orientation = MediaQuery.of(context).orientation;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Online Game'),
            ),
            drawer: Drawer(
              // FIX: This is a more robust way to create a scrollable drawer that won't overflow.
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    child: Text('Game Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context); // Close the drawer
                      // TODO: Navigate to settings screen
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.exit_to_app),
                    title: const Text('Leave Game'),
                    onTap: () {
                       Navigator.pop(context); // Close the drawer
                       Navigator.pop(context); // Go back from game screen
                    },
                  ),
                  // Add more dummy items to demonstrate scrolling
                  for (var i = 0; i < 10; i++)
                    ListTile(
                      title: Text('Menu Item ${i + 1}'),
                      onTap: () {},
                    ),
                ],
              ),
            ),
            body: SafeArea(
              child: orientation == Orientation.portrait
                  ? _buildPortraitLayout(context, controller, game)
                  : _buildLandscapeLayout(context, controller, game),
            ),
          );
        },
      ),
    );
  }

  // Layout for Portrait Mode
  Widget _buildPortraitLayout(BuildContext context, OnlineGameController controller, game_model.Game game) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OnlinePlayerInfo(game: game),
          const SizedBox(height: 20),
          Expanded(
            child: GameBoard(
              boardIndex: 0,
              gradientStart: Theme.of(context).colorScheme.surface,
              gradientEnd: Theme.of(context).colorScheme.secondary,
              currentTheme: context.read<SettingsController>().currentTheme as AppTheme,
            ),
          ),
          const SizedBox(height: 20),
          _buildGameControls(context, controller, game),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // Layout for Landscape Mode
  Widget _buildLandscapeLayout(BuildContext context, OnlineGameController controller, game_model.Game game) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          // FIX: Use a LayoutBuilder for explicit and reliable resizing.
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // This forces the GameBoard into a square that fits the available height.
                final boardSize = constraints.maxHeight * 0.8; // Use 80% of height to add padding
                return SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: GameBoard(
                    boardIndex: 0,
                    gradientStart: Theme.of(context).colorScheme.surface,
                    gradientEnd: Theme.of(context).colorScheme.secondary,
                    currentTheme: context.read<SettingsController>().currentTheme as AppTheme,
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OnlinePlayerInfo(game: game),
                  const SizedBox(height: 30),
                  _buildGameControls(context, controller, game),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  // Shared UI for game status and post-game actions
  Widget _buildGameControls(BuildContext context, OnlineGameController controller, game_model.Game game) {
    // If the game is finished, show action buttons
    if (game.status == game_model.GameStatus.finished) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display the final game status (Win/Loss/Draw)
          Text(
            _getGameStatus(game, context.read<FirebaseService>().currentUser!.uid),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Play Again'),
            onPressed: () {
              // TODO: Implement "Play Again" functionality. This might involve creating a new game or resetting the current one.
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop(); // Go back to the previous screen
            },
          ),
        ],
      );
    }

    // If the game is in progress, show the current status and a progress indicator
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _getGameStatus(game, context.read<FirebaseService>().currentUser!.uid),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (controller.isMakingMove)
          const Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }


  // Helper function to determine the device's screen type and set orientation
  void _setOrientation(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = size.shortestSide;
    final inches = diagonal / 300; 
    
    if (inches <= 6.7) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else if (inches >= 7.0) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  String _getGameStatus(game_model.Game game, String currentUserId) {
    switch (game.status) {
      case game_model.GameStatus.waiting:
        return 'Waiting for another player...';
      case game_model.GameStatus.finished:
        if (game.isDraw) return "It's a Draw!";
        return game.winnerUid == currentUserId ? 'You Won!' : 'You Lost!';
      case game_model.GameStatus.in_progress:
        return game.currentPlayerUid == currentUserId ? 'Your Turn' : "Opponent's Turn";
    }
  }
}

class OnlinePlayerInfo extends StatelessWidget {
  final game_model.Game game;
  const OnlinePlayerInfo({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isPlayerXTurn = game.isPlayerX(game.currentPlayerUid);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildPlayerCard(context, 'Player X', game.playerXName, isPlayerXTurn),
        const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        _buildPlayerCard(context, 'Player O', game.playerOName, !isPlayerXTurn),
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
