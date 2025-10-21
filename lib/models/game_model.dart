import 'package:cloud_firestore/cloud_firestore.dart';

// Re-using the Player enum from the local game for consistency.
// We could also define it here if we wanted this model to be fully self-contained.
import '../game_screen.dart';

/// Enum representing the state of an online game.
enum GameStatus { waiting, in_progress, finished }

/// A type-safe representation of a 'game' document from Firestore.
///
/// ARCHITECTURAL DECISION:
/// Creating a model class like this is a best practice (part of the Repository
/// pattern). It decouples the rest of the app from the raw data structure of
/// Firestore. It provides type safety, autocompletion, and a single place to
/// handle the conversion from a Firestore `DocumentSnapshot` into a usable Dart object.
class Game {
  final String id;
  final List<Player> board;
  final Map<String, String> players; // e.g., {'playerX_uid': 'uid1', 'playerO_uid': 'uid2'}
  final Map<String, String> playerNames; // e.g., {'uid1': 'Alice', 'uid2': 'Bob'}
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

    return Game(
      id: snapshot.id,
      // Convert the List<dynamic> from Firestore (containing '', 'X', 'O') to List<Player>.
      board: (data['board'] as List<dynamic>).map((p) {
        if (p == 'X') return Player.X;
        if (p == 'O') return Player.O;
        return Player.none;
      }).toList(),
      players: Map<String, String>.from(data['players'] ?? {}),
      playerNames: Map<String, String>.from(data['player_names'] ?? {}),
      currentPlayerUid: data['currentPlayerUid'] ?? '',
      status: _parseGameStatus(data['status']),
      winnerUid: data['winnerUid'],
      isDraw: data['isDraw'] ?? false,
    );
  }

  /// A robust helper to parse the game status string from Firestore.
  static GameStatus _parseGameStatus(String? status) {
    switch (status) {
      case 'waiting':
        return GameStatus.waiting;
      case 'in_progress':
        return GameStatus.in_progress;
      case 'finished':
        return GameStatus.finished;
      default:
        return GameStatus.waiting; // Default to a safe state
    }
  }

  // ==========
  // UI Helpers
  // ==========

  /// Helper to get the display name for Player X.
  String get playerXName {
    final playerXUid = players['playerX_uid'];
    return playerNames[playerXUid] ?? 'Player X';
  }

  /// Helper to get the display name for Player O.
  String get playerOName {
    final playerOUid = players['playerO_uid'];
    return playerNames[playerOUid] ?? 'Player O';
  }

  /// Helper to determine if a specific user is Player X.
  bool isPlayerX(String userId) => players['playerX_uid'] == userId;

  /// Helper to determine if a specific user is Player O.
  bool isPlayerO(String userId) => players['playerO_uid'] == userId;
}
