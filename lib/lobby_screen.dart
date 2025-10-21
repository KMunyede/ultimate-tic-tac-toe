import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tictactoe/online_game_screen.dart';
import 'firebase_service.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Lobby'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create New Game'),
              onPressed: () async {
                try {
                  final gameId = await firebaseService.createGame();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => OnlineGameScreen(gameId: gameId),
                  ));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to create game: $e")),
                  );
                }
              },
            ),
          ),
          const Divider(),
          const Text('Available Games', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firebaseService.getAvailableGames(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No available games. Create one!'));
                }

                return ListView( 
                  children: snapshot.data!.docs.map((doc) {
                    final gameData = doc.data() as Map<String, dynamic>;
                    final playerNames = Map<String, String>.from(gameData['player_names'] ?? {});
                    final creatorName = playerNames.values.first ?? 'Unknown Player';

                    return ListTile(
                      title: Text('Game by $creatorName'),
                      subtitle: Text('ID: ${doc.id}'),
                      trailing: const Icon(Icons.play_arrow),
                      onTap: () async {
                        try {
                          await firebaseService.joinGame(doc.id);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => OnlineGameScreen(gameId: doc.id),
                          ));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to join game: $e")),
                          );
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
