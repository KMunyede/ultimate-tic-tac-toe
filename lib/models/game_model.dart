import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tictactoe/models/player.dart';

/// Enum representing the state of an online game.
enum GameStatus { waiting, in_progress, finished }

/// A type-safe representation of a 'game' document from Firestore.
class Game {
  final String id;
  final List<Player> board;
  // ARCHITECTURAL FIX: Use a more specific, correctly-typed map for players.
  // This prevents runtime cast errors.
  final Map<String, Map<String, dynamic>> players;
  final Map<String, String> playerNames;
  final String currentPlayerUid;
  final GameStatus status;
  final String? winnerUid;
  final bool isDraw;

  Game({
    required this.id,
    required this.board,
    required this.players,
    required this.playerNames,
    required this.currentPlayerUid,
    required this.status,
    this.winnerUid,
    required this.isDraw,
  });

  /// Factory constructor to create a `Game` instance from a Firestore snapshot.
  factory Game.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Game document was null for ID: ${snapshot.id}");
    }

    // ARCHITECTURAL FIX: Deeply parse the nested players map.
    // This ensures that the inner maps for playerX and playerO are also correctly
    // typed as Map<String, dynamic>, preventing cast errors in the UI.
    final playersData = data['players'] as Map<String, dynamic>? ?? {};
    final parsedPlayers = playersData.map((key, value) {
      return MapEntry(key, Map<String, dynamic>.from(value as Map));
    });

    return Game(
      id: snapshot.id,
      board: (data['board'] as List<dynamic>).map((p) {
        if (p == 'X') return Player.X;
        if (p == 'O') return Player.O;
        return Player.none;
      }).toList(),
      players: parsedPlayers, // Use the correctly parsed map
      playerNames: Map<String, String>.from(data['player_names'] ?? {}),
      currentPlayerUid: data['currentPlayerUid'] ?? '',
      status: _parseGameStatus(data['status']),
      winnerUid: data['winnerUid'],
      isDraw: data['isDraw'] ?? false,
    );
  }

  static GameStatus _parseGameStatus(String? status) {
    switch (status) {
      case 'waiting':
        return GameStatus.waiting;
      case 'in_progress':
        return GameStatus.in_progress;
      case 'finished':
        return GameStatus.finished;
      default:
        return GameStatus.waiting;
    }
  }

  // ==========
  // UI Helpers (Now simpler and safer due to the typed `players` map)
  // ==========

  String get playerXName {
    return players['playerX']?['displayName'] as String? ?? 'Player X';
  }

  String get playerOName {
    // This is now safe because `players['playerO']` is guaranteed to be a Map or null.
    return players['playerO']?['displayName'] as String? ?? 'Waiting...';
  }

  bool isPlayerX(String userId) {
    return players['playerX']?['uid'] == userId;
  }

  bool isPlayerO(String userId) {
    return players['playerO']?['uid'] == userId;
  }
}
