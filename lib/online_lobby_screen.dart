import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tictactoe/firebase_service.dart';
import 'package:tictactoe/online_game_screen.dart';
import 'package:tictactoe/sound_manager.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  bool _isProcessing = false;

  Future<void> _createNewGame(BuildContext context) async {
    final soundManager = context.read<SoundManager>();
    // ARCHITECTURAL FIX: Use the correct method name from SoundManager.
    soundManager.playMoveSound();

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final firebaseService = context.read<FirebaseService>();
    try {
      final gameId = await firebaseService.createGame();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OnlineGameScreen(gameId: gameId)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create game: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _joinGame(BuildContext context, String gameId) async {
    final soundManager = context.read<SoundManager>();
    // ARCHITECTURAL FIX: Use the correct method name from SoundManager.
    soundManager.playMoveSound();
    
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final firebaseService = context.read<FirebaseService>();
    try {
      await firebaseService.joinGame(gameId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OnlineGameScreen(gameId: gameId)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to join game: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.watch<FirebaseService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Lobby'),
        actions: [
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create New Game'),
              onPressed: _isProcessing ? null : () => _createNewGame(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Available Games', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firebaseService.getAvailableGames(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No games available. Create one!'));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final games = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final gameData = game.data() as Map<String, dynamic>;
                    final playerX = gameData['players']?['playerX'];
                    final playerXName = playerX?['displayName'] ?? 'Player X';
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text("Game by $playerXName"),
                        subtitle: Text("Waiting for a player..."),
                        trailing: const Icon(Icons.play_arrow),
                        onTap: _isProcessing ? null : () => _joinGame(context, game.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
