import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tictactoe/models/player.dart';
import 'firebase_service.dart';
import 'models/game_model.dart';
import 'sound_manager.dart';

/// A controller for managing the state of an *online* multiplayer game.
///
/// ARCHITECTURAL DECISION:
/// We use a dedicated controller for online games to cleanly separate the logic
/// from the local/AI game (`GameController`). This controller is responsible for
/// subscribing to a Firestore game document, handling game logic (like making a move),
/// and exposing the real-time game state to the UI.
class OnlineGameController with ChangeNotifier {
  final FirebaseService _firebaseService;
  final SoundManager _soundManager;
  final String gameId;

  OnlineGameController(this._firebaseService, this._soundManager, this.gameId) {
    _listenToGameUpdates();
  }

  Game? _game;
  Game? get game => _game;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  StreamSubscription<Game>? _gameSubscription;

  /// Subscribes to the real-time stream of the current game from Firestore.
  void _listenToGameUpdates() {
    _gameSubscription = _firebaseService.getGameStream(gameId).listen(
      (updatedGame) {
        // Check for winner or draw to play sounds
        if (_game != null) {
          final bool justWon = updatedGame.status == GameStatus.finished && updatedGame.winnerUid != null && _game!.status != GameStatus.finished;
          final bool justDrew = updatedGame.status == GameStatus.finished && updatedGame.isDraw && !_game!.isDraw;

          if (justWon) {
            _soundManager.playWinSound();
          } else if (justDrew) {
            _soundManager.playDrawSound();
          }
        }

        _game = updatedGame;
        _error = null;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        print("Error listening to game updates: $e");
        _error = "Lost connection to the game.";
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Handles a user tapping a cell on the board.
  Future<void> makeMove(int index) async {
    if (_game == null || _isLoading) return;

    final currentUser = _firebaseService.currentUser;
    if (currentUser == null) return; // Not logged in

    // Check if it's the current user's turn and the cell is empty
    if (_game!.currentPlayerUid == currentUser.uid && _game!.board[index] == Player.none) {
      _isLoading = true;
      notifyListeners();

      try {
        _soundManager.playMoveSound();
        
        // Determine the next player
        final playerXUid = _game!.players['playerX_uid'];
        final playerOUid = _game!.players['playerO_uid'];
        final nextPlayerUid = currentUser.uid == playerXUid ? playerOUid! : playerXUid!;
        
        final playerSymbol = _game!.isPlayerX(currentUser.uid) ? Player.X : Player.O;

        // Here, we are not checking for a winner on the client. We'd rely on a Cloud Function
        // for that in a production app. For now, we just make the move.
        await _firebaseService.makeMove(gameId, index, playerSymbol, nextPlayerUid);

      } catch (e) {
        print("Error making move: $e");
        _error = "Could not make move. Please try again.";
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }
}
