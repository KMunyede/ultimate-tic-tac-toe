//Modified game_controller 03/01/2026 23:06 CAT
import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:tictactoe/ai_logic.dart';
import 'package:tictactoe/firebase_service.dart';
import 'package:tictactoe/models/game_board.dart';
import 'package:tictactoe/models/player.dart';
import 'package:tictactoe/settings_controller.dart';
import 'package:tictactoe/sound_manager.dart';

// Represents a single Tic-Tac-Toe board
class GameBoard {
  List<Player> cells;
  Player? winner;
  List<int>? winningLine;
  bool isDraw;

  GameBoard()
      : cells = List.filled(9, Player.none),
        winner = null,
        winningLine = null,
        isDraw = false;

  bool get isGameOver => winner != null || isDraw;

  void reset() {
    cells = List.filled(9, Player.none);
    winner = null;
    winningLine = null;
    isDraw = false;
  }
}

class GameController with ChangeNotifier {
  final SoundManager _soundManager;
  SettingsController _settingsController;
  final FirebaseService? _firebaseService;

  GameController(this._soundManager, this._settingsController,
      [this._firebaseService]) {
    initializeGame();
  }

  // --- STATE ---
  late List<GameBoard> _boards;
  Player? _overallWinner;
  Player _currentPlayer = Player.X;
  bool _isOverallDraw = false;
  String? _statusMessage;

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

  void initializeGame() {
    _boards = List.generate(_numberOfBoards, (_) => GameBoard());
    _overallWinner = null;
    _currentPlayer = Player.X;
    _isOverallDraw = false;
    notifyListeners();
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

    if (_checkBoardWinner(board)) {
      board.winner = _currentPlayer;
      _soundManager.playWinSound();
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

    if (wonBoardsByX == _numberOfBoards) {
      _overallWinner = Player.X;
      _settingsController.updateScore(Player.X);
      _soundManager.playWinSound();
      return;
    }
    if (wonBoardsByO == _numberOfBoards) {
      _overallWinner = Player.O;
      _settingsController.updateScore(Player.O);
      _soundManager.playWinSound();
      return;
    }

    final activeBoards = _boards.where((b) => !b.isGameOver).length;
    final maxPossibleX = wonBoardsByX + activeBoards;
    final maxPossibleO = wonBoardsByO + activeBoards;

    if (maxPossibleX < _numberOfBoards && maxPossibleO < _numberOfBoards) {
      _isOverallDraw = true;
      _soundManager.playDrawSound();
    }
  }

  bool _checkBoardWinner(GameBoard board) {
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
        board.winningLine = line;
        return true;
      }
    }
    return false;
  }

  Future<void> _makeAiMove() async {
    // Artificial delay for realism
    await Future.delayed(const Duration(milliseconds: 600));
    if (isOverallGameOver) return;

    final availableBoards = _boards.asMap().entries.where((entry) => !entry.value.isGameOver).toList();
    if (availableBoards.isEmpty) return;

    final randomBoardEntry = availableBoards[Random().nextInt(availableBoards.length)];
    final boardIndex = randomBoardEntry.key;
    final board = randomBoardEntry.value;
    
    int? bestMove;

    if (_firebaseService != null && _settingsController.aiDifficulty != AiDifficulty.easy) {
      try {
        final boardState = board.cells.map((p) => p.toString().split('.').last).toList();
        final difficulty = _settingsController.aiDifficulty.name;
        final move = await _firebaseService!.getAiMove(boardState, _currentPlayer.toString().split('.').last, difficulty);
        
        _statusMessage = "AI move received successfully.";

        if (move != null && board.cells[move] == Player.none) {
          bestMove = move;
        }
      } on FirebaseFunctionsException catch (e) {
        _statusMessage = "Error fetching AI move: ${e.message}";
      } catch (e) {
        _statusMessage = "An unknown error occurred.";
      }
      notifyListeners();
    }

    if (bestMove == null) {
      // Fallback to random move
      final availableCells = board.cells.asMap().entries.where((entry) => entry.value == Player.none).map((e) => e.key).toList();
      if (availableCells.isNotEmpty) {
        bestMove = availableCells[Random().nextInt(availableCells.length)];
      }
    }

    if (bestMove != null) {
      handleTap(boardIndex, bestMove);
    }
  }

  void clearStatusMessage() {
    _statusMessage = null;
  }

  void updateDependencies(SettingsController newSettingsController) {
    if (_settingsController.gameMode != newSettingsController.gameMode ||
        _settingsController.boardLayout != newSettingsController.boardLayout) {
      initializeGame();
    }
    _settingsController = newSettingsController;
  }
}
