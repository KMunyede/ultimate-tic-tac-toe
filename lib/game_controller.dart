import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tictactoe/models/player.dart';
import 'package:tictactoe/settings_controller.dart';
import 'package:tictactoe/sound_manager.dart';
import 'package:tictactoe/firebase_service.dart';

class GameController with ChangeNotifier {
  final SoundManager _soundManager;
  SettingsController _settingsController;
  final FirebaseService _firebaseService;

  GameController(this._soundManager, this._settingsController, this._firebaseService) {
    initializeGame();
  }

  // --- STATE ---
  List<List<Player>> _boards = [];
  List<Player?> _winners = [];
  List<List<int>?> _winningLines = [];

  Player _currentPlayer = Player.X;
  Player? _overallWinner; // ARCHITECTURAL ADDITION: Tracks the winner of the entire round.
  bool _isDraw = false;

  // --- GETTERS ---
  List<List<Player>> get boards => _boards;
  Player get currentPlayer => _currentPlayer;
  Player? get overallWinner => _overallWinner;
  bool get isDraw => _isDraw;
  bool get isGameOver => _overallWinner != null || _isDraw;

  Player? getWinnerForBoard(int boardIndex) => _winners[boardIndex];
  List<int>? getWinningLineForBoard(int boardIndex) => _winningLines[boardIndex];

  void initializeGame() {
    int boardCount;
    switch (_settingsController.boardLayout) {
      case BoardLayout.single: boardCount = 1; break;
      case BoardLayout.double: boardCount = 2; break;
      case BoardLayout.triple: boardCount = 3; break;
    }

    _boards = List.generate(boardCount, (_) => List.filled(9, Player.none));
    _winners = List.filled(boardCount, null);
    _winningLines = List.filled(boardCount, null);
    _currentPlayer = Player.X;
    _overallWinner = null;
    _isDraw = false;
    notifyListeners();
  }

  void handleTap(int boardIndex, int cellIndex) {
    if (isGameOver || _boards[boardIndex][cellIndex] != Player.none || _winners[boardIndex] != null) {
      return;
    }

    _boards[boardIndex][cellIndex] = _currentPlayer;
    _soundManager.playMoveSound();

    _updateGameState(boardIndex);
  }

  void _updateGameState(int boardIndex) {
    // 1. Check if the current move won the local board.
    if (_checkWinner(boardIndex)) {
      _winners[boardIndex] = _currentPlayer;
    }

    // 2. Check for an overall win condition (player has won ALL boards).
    if (_winners.every((w) => w == _currentPlayer)) {
      _overallWinner = _currentPlayer;
      _soundManager.playWinSound(); // Play the big win sound.
      _settingsController.updateScore(_currentPlayer);
      notifyListeners();
      return; // Game Over.
    }

    // 3. Check for an overall draw condition (all boards are finished, but no overall winner).
    bool allBoardsFinished = true;
    for (int i = 0; i < _boards.length; i++) {
      bool isFull = !_boards[i].contains(Player.none);
      if (_winners[i] == null && !isFull) {
        allBoardsFinished = false; // Found a board that is still in play.
        break;
      }
    }
    if (allBoardsFinished) {
      _isDraw = true;
      _soundManager.playDrawSound();
      notifyListeners();
      return; // Game Over.
    }

    // 4. If no overall win or draw, switch player and continue.
    _currentPlayer = (_currentPlayer == Player.X) ? Player.O : Player.X;
    if (_settingsController.gameMode == GameMode.playerVsAi && _currentPlayer == Player.O && !isGameOver) {
      _makeAiMove();
    }
    notifyListeners();
  }

  bool _checkWinner(int boardIndex) {
    const List<List<int>> winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6],
    ];

    final board = _boards[boardIndex];
    for (final line in winningCombos) {
      final Player first = board[line[0]];
      if (first != Player.none && first == board[line[1]] && first == board[line[2]]) {
        _winningLines[boardIndex] = line;
        return true;
      }
    }
    return false;
  }

  Future<void> _makeAiMove() async {
    // Delay slightly to feel natural
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (isGameOver) return;

    List<int> activeBoardIndices = [];
    for (int i = 0; i < _boards.length; i++) {
      if (_winners[i] == null && _boards[i].contains(Player.none)) {
        activeBoardIndices.add(i);
      }
    }

    if (activeBoardIndices.isEmpty) return;

    // Pick a board to play on.
    final random = Random();
    int boardIndex = activeBoardIndices[random.nextInt(activeBoardIndices.length)];

    // Convert board to format expected by Cloud Function
    List<String> boardData = _boards[boardIndex].map((p) {
      if (p == Player.X) return 'X';
      if (p == Player.O) return 'O';
      return '';
    }).toList();

    try {
      final moveIndex = await _firebaseService.getAiMove(
        boardData,
        _settingsController.aiDifficulty.name.toLowerCase(),
      );
      
      if (!isGameOver) {
        handleTap(boardIndex, moveIndex);
      }
    } catch (e) {
      print("AI Move failed: $e. Falling back to local random move.");
      _makeRandomMoveFallback(boardIndex);
    }
  }

  void _makeRandomMoveFallback(int boardIndex) {
    List<int> availableMoves = [];
    for (int j = 0; j < 9; j++) {
      if (_boards[boardIndex][j] == Player.none) {
        availableMoves.add(j);
      }
    }

    if (availableMoves.isNotEmpty) {
      final random = Random();
      final move = availableMoves[random.nextInt(availableMoves.length)];
      handleTap(boardIndex, move);
    }
  }

  void updateDependencies(SettingsController newSettingsController) {
    _settingsController = newSettingsController;

    int expectedBoardCount;
    switch (_settingsController.boardLayout) {
      case BoardLayout.single: expectedBoardCount = 1; break;
      case BoardLayout.double: expectedBoardCount = 2; break;
      case BoardLayout.triple: expectedBoardCount = 3; break;
    }

    if (_boards.length != expectedBoardCount) {
      initializeGame();
    }
  }
}
