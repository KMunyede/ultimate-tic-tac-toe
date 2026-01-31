//Modified game_controller 03/01/2026 23:25 CAT
import 'dart:async';

import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:tictactoe/firebase_service.dart'; // Added Import
import 'package:tictactoe/models/game_board.dart';
import 'package:tictactoe/models/player.dart';
import 'package:tictactoe/services/ai_service.dart';
import 'package:tictactoe/settings_controller.dart';
import 'package:tictactoe/sound_manager.dart';

class GameController with ChangeNotifier {
  final SoundManager _soundManager;
  SettingsController _settingsController;
  final FirebaseService _firebaseService; // Added FirebaseService
  final AiService _aiService = AiService(); // Local Fallback AI

  GameController(
      this._soundManager, this._settingsController, this._firebaseService) {
    initializeGame();
  }

  // --- STATE ---
  late List<GameBoard> _boards;
  Player? _overallWinner;
  Player _currentPlayer = Player.X;
  bool _isOverallDraw = false;
  String? _statusMessage;

  // Game generation ID to handle async AI moves during resets
  int _gameId = 0;

  // --- GETTERS ---
  List<GameBoard> get boards => _boards;
  Player get currentPlayer => _currentPlayer;
  Player? get overallWinner => _overallWinner;
  bool get isOverallDraw => _isOverallDraw;
  bool get isOverallGameOver => _overallWinner != null || _isOverallDraw;
  String? get statusMessage => _statusMessage;

  int get _numberOfBoards {
    switch (_settingsController.boardLayout) {
      case BoardLayout.single:
        return 1;
      case BoardLayout.dual:
        return 2;
      case BoardLayout.trio:
        return 3;
    }
  }

  void initializeGame({bool useMicrotask = false}) {
    _gameId++; // Invalidate any pending AI moves
    _soundManager.stop(); // Stop any playing sounds (e.g., win sound)

    _boards = List.generate(_numberOfBoards, (_) => GameBoard());
    _overallWinner = null;
    _currentPlayer = Player.X;
    _isOverallDraw = false;
    _statusMessage = null;

    if (useMicrotask) {
      Future.microtask(() => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  void handleTap(int boardIndex, int cellIndex) {
    final board = _boards[boardIndex];
    if (isOverallGameOver ||
        board.isGameOver ||
        board.cells[cellIndex] != Player.none) {
      return;
    }

    board.cells[cellIndex] = _currentPlayer;
    _soundManager.playMoveSound();

    _updateGameState(boardIndex);
  }

  void _updateGameState(int boardIndex) {
    final board = _boards[boardIndex];

    final winningLine = _findWinningLine(board);
    if (winningLine != null) {
      board.winner = _currentPlayer;
      _soundManager.playWinSound();

      // Delay drawing the victory line to allow the last move to be fully rendered
      // We also check _gameId to ensure we don't update state if game was reset
      final int currentId = _gameId;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_gameId != currentId) return;

        // Ensure the game state hasn't been reset while waiting
        if (board.winner == _currentPlayer && !board.isDraw) {
          board.winningLine = winningLine;
          notifyListeners();
        }
      });
    } else if (!board.cells.contains(Player.none)) {
      board.isDraw = true;
    }

    _checkOverallGameStatus();

    if (!isOverallGameOver) {
      _currentPlayer = (_currentPlayer == Player.X) ? Player.O : Player.X;
      if (_settingsController.gameMode == GameMode.playerVsAi &&
          _currentPlayer == Player.O) {
        _makeAiMove();
      }
    }

    notifyListeners();
  }

  void _checkOverallGameStatus() {
    final wonBoardsByX = _boards.where((b) => b.winner == Player.X).length;
    final wonBoardsByO = _boards.where((b) => b.winner == Player.O).length;

    // Calculate required wins for an overall win (majority for multi-board)
    final int requiredWins = (_numberOfBoards / 2).ceil();

    if (wonBoardsByX >= requiredWins) {
      _overallWinner = Player.X;
      _settingsController.updateScore(Player.X);
      _soundManager.playWinSound();
      return;
    }
    if (wonBoardsByO >= requiredWins) {
      _overallWinner = Player.O;
      _settingsController.updateScore(Player.O);
      _soundManager.playWinSound();
      return;
    }

    final activeBoards = _boards.where((b) => !b.isGameOver).length;
    final maxPossibleX = wonBoardsByX + activeBoards;
    final maxPossibleO = wonBoardsByO + activeBoards;

    // Check if it's impossible for either to win a majority of boards
    if (maxPossibleX < requiredWins && maxPossibleO < requiredWins) {
      _isOverallDraw = true;
      _soundManager.playDrawSound();
    }
  }

  List<int>? _findWinningLine(GameBoard board) {
    const List<List<int>> winningCombos = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final line in winningCombos) {
      final Player first = board.cells[line[0]];
      if (first != Player.none &&
          first == board.cells[line[1]] &&
          first == board.cells[line[2]]) {
        return line;
      }
    }
    return null;
  }

  Future<void> _makeAiMove() async {
    final int capturingGameId = _gameId;

    // Artificial delay for realism
    await Future.delayed(const Duration(milliseconds: 600));

    // If game has been reset (ID changed), abort
    if (_gameId != capturingGameId) return;

    if (isOverallGameOver) return;

    // --- 1. Attempt Remote AI Move via Firebase Function ---
    // Log the intent to call the function
    if (kDebugMode) {
      print("Attempting REMOTE AI move via Firebase Function...");
    }

    // Flatten the boards data structure for remote transmission
    final List<dynamic> serializedBoards =
        _boards.map((b) => b.cells.map((c) => c.name).toList()).toList();

    // The remote function is expected to return a single flattened index (0-8)
    // or null on failure.
    final moveIndex = await _firebaseService.getAiMove(
      serializedBoards,
      _currentPlayer.name,
      _settingsController.aiDifficulty.name,
    );

    // We expect the Firebase service logs to confirm if the remote function was called.
    // Since we can't rely on the remote move structure for multi-board yet,
    // we fall through to the local AI if the remote call succeeds but returns an un-usable move,
    // or if it fails/returns null.

    // --- 2. Fallback to Local AI Move ---
    final move = _aiService.getBestMove(
      _boards,
      _currentPlayer,
      _settingsController.aiDifficulty,
      _settingsController.boardLayout,
    );

    if (move != null) {
      handleTap(move.boardIndex, move.cellIndex);
      _statusMessage = "AI made a move.";
    } else {
      // Should technically not happen if game is not over
      _statusMessage = "AI stuck.";
    }
  }

  void clearStatusMessage() {
    _statusMessage = null;
  }

  void updateDependencies(SettingsController newSettingsController) {
    final bool shouldReset = _settingsController.gameMode !=
            newSettingsController.gameMode ||
        _settingsController.boardLayout != newSettingsController.boardLayout;

    _settingsController = newSettingsController;

    if (shouldReset) {
      initializeGame(useMicrotask: true);
    }
  }
}
