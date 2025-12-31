import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tictactoe/models/player.dart';
import 'firebase_service.dart';
import 'models/game_model.dart';
import 'sound_manager.dart';

/// A controller for managing the state of an *online* multiplayer game.
class OnlineGameController with ChangeNotifier {
  final FirebaseService _firebaseService;
  final SoundManager _soundManager;
  final String gameId;

  // --- State Variables ---
  Game? _game;
  // ARCHITECTURAL FIX: `isLoading` is ONLY for the initial fetch of game data.
  // It now correctly starts as `true`.
  bool _isLoading = true;
  // ARCHITECTURAL FIX: `isMakingMove` is a separate flag for move processing.
  bool _isMakingMove = false;
  String? _error;

  // --- Public Getters ---
  Game? get game => _game;
  bool get isLoading => _isLoading;
  bool get isMakingMove => _isMakingMove;
  String? get error => _error;

  StreamSubscription<Game>? _gameSubscription;

  OnlineGameController(this._firebaseService, this._soundManager, this.gameId) {
    _listenToGameUpdates();
  }

  void _listenToGameUpdates() {
    _gameSubscription = _firebaseService.getGameStream(gameId).listen(
      (updatedGame) {
        final Game? oldGame = _game;
        _game = updatedGame;

        // Play sounds only on the transition to a finished state.
        if (oldGame != null) {
          final bool justWon = updatedGame.status == GameStatus.finished && updatedGame.winnerUid != null && oldGame.status != GameStatus.finished;
          final bool justDrew = updatedGame.status == GameStatus.finished && updatedGame.isDraw && !oldGame.isDraw;

          if (justWon) {
            _soundManager.playWinSound();
          } else if (justDrew) {
            _soundManager.playDrawSound();
          }
        }
        
        // Data has arrived, so we are no longer in the initial loading state.
        _isLoading = false;
        _error = null;
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
    // Guard against making moves when the game isn't ready or it's not your turn.
    if (game == null || isLoading || isMakingMove) return;

    final currentUser = _firebaseService.currentUser;
    if (currentUser == null || game!.currentPlayerUid != currentUser.uid || game!.board[index] != Player.none) {
      return;
    }

    _isMakingMove = true;
    notifyListeners();

    try {
      _soundManager.playMoveSound();
      await _firebaseService.makeMove(gameId, index);
    } catch (e) {
      print("Error making move: $e");
      _error = e.toString();
    } finally {
      _isMakingMove = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }
}
