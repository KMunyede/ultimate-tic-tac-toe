//Modified game_controller 04/01/2026 00:30 CAT
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tictactoe/firebase_service.dart';
import 'package:tictactoe/models/game_board.dart';
import 'package:tictactoe/models/player.dart';
import 'package:tictactoe/services/ai_service.dart';
import 'package:tictactoe/settings_controller.dart';
import 'package:tictactoe/sound_manager.dart';

class GameController with ChangeNotifier {
  final SoundManager _soundManager;
  SettingsController _settingsController;
  final FirebaseService _firebaseService;
  final AiService _aiService = AiService();

  final StreamController<String> _aiErrorController =
      StreamController<String>.broadcast();
  Stream<String> get aiErrorStream => _aiErrorController.stream;

  GameController(
      this._soundManager, this._settingsController, this._firebaseService) {
    initializeGame();
  }

  @override
  void dispose() {
    _aiErrorController.close();
    super.dispose();
  }

  // --- STATE ---
  late List<GameBoard> _boards;
  Player? _overallWinner;
  bool _isOverallDraw = false;
  String? _statusMessage;
  int _gameId = 0;

  Player _currentPlayer = Player.X;

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
    _gameId++;
    _soundManager.stop();
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
      final int currentId = _gameId;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_gameId != currentId) return;
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

      // LOGGING: Check why AI might not be triggering
      if (kDebugMode) {
        print(
            "DEBUG: Current Player is $_currentPlayer. GameMode is ${_settingsController.gameMode}");
      }

      if (_settingsController.gameMode == GameMode.playerVsAi &&
          _currentPlayer == Player.O) {
        _makeAiMove();
      }
    }
    notifyListeners();
  }

  void _checkOverallGameStatus() {
    final int count = _boards.length;
    final bool allFinished = _boards.every((b) => b.isGameOver);

    if (count == 1) {
      _handleSingleBoardResult();
    } else if (count == 2) {
      _handleTwoBoardResult(allFinished);
    } else if (count == 3) {
      _handleThreeBoardResult(allFinished);
    }

    if (isOverallGameOver) {
      if (_overallWinner != null) {
        _settingsController.updateScore(_overallWinner!);
        _soundManager.playWinSound();
      } else if (_isOverallDraw) {
        _soundManager.playDrawSound();
      }
    }
  }

  void _handleSingleBoardResult() {
    final board = _boards[0];
    if (board.winner != null) {
      _overallWinner = board.winner;
    } else if (board.isDraw) {
      _isOverallDraw = true;
    }
  }

  void _handleTwoBoardResult(bool allFinished) {
    double scoreX = 0.0;
    double scoreO = 0.0;

    for (var b in _boards) {
      if (b.winner == Player.X)
        scoreX += 1.0;
      else if (b.winner == Player.O)
        scoreO += 1.0;
      else if (b.isDraw) {
        scoreX += 0.5;
        scoreO += 0.5;
      }
    }

    if (allFinished) {
      if (scoreX > scoreO) {
        _overallWinner = Player.X;
      } else if (scoreO > scoreX) {
        _overallWinner = Player.O;
      } else {
        _isOverallDraw = true;
      }
    } else {
      if (scoreX > 1.0) _overallWinner = Player.X;
      if (scoreO > 1.0) _overallWinner = Player.O;
    }
  }

  void _handleThreeBoardResult(bool allFinished) {
    int winsX = _boards.where((b) => b.winner == Player.X).length;
    int winsO = _boards.where((b) => b.winner == Player.O).length;

    if (winsX >= 2) {
      _overallWinner = Player.X;
      return;
    }
    if (winsO >= 2) {
      _overallWinner = Player.O;
      return;
    }

    if (allFinished) {
      if (winsX > winsO) {
        _overallWinner = Player.X;
      } else if (winsO > winsX) {
        _overallWinner = Player.O;
      } else {
        _isOverallDraw = true;
      }
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

    if (kDebugMode) {
      print(
          "DEBUG: AI Move Triggered. useOnlineAi is ${_settingsController.useOnlineAi}");
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (_gameId != capturingGameId || isOverallGameOver) return;

    final List<dynamic> serializedBoards =
        _boards.map((b) => b.cells.map((c) => c.name).toList()).toList();

    final bool remoteMoveSuccess = await _attemptRemoteAiMove(serializedBoards);

    if (!remoteMoveSuccess) {
      if (kDebugMode) {
        print("DEBUG: Remote move failed or disabled. Executing local AI...");
      }
      final move = _aiService.getBestMove(_boards, _currentPlayer,
          _settingsController.aiDifficulty, _settingsController.boardLayout);
      if (move != null) handleTap(move.boardIndex, move.cellIndex);
    }
  }

  Future<bool> _attemptRemoteAiMove(List<dynamic> serializedBoards) async {
    if (!_settingsController.useOnlineAi) {
      if (kDebugMode) {
        print("DEBUG: Skipping remote call - useOnlineAi is false");
      }
      return false;
    }

    if (kDebugMode) {
      print("DEBUG: Attempting REMOTE AI move via Firebase Function...");
    }

    try {
      final remoteMoveResult = await _firebaseService.getAiMove(
          serializedBoards,
          _currentPlayer.name,
          _settingsController.aiDifficulty.name);

      if (remoteMoveResult != null &&
          remoteMoveResult.containsKey('boardIndex') &&
          remoteMoveResult.containsKey('cellIndex')) {
        final int moveBoardIndex =
            (remoteMoveResult['boardIndex'] as num).toInt();
        final int moveCellIndex =
            (remoteMoveResult['cellIndex'] as num).toInt();
        if (moveBoardIndex >= 0 &&
            moveBoardIndex < _boards.length &&
            _boards[moveBoardIndex].cells[moveCellIndex] == Player.none) {
          handleTap(moveBoardIndex, moveCellIndex);
          return true;
        }
      } else {
        if (kDebugMode)
          print("DEBUG: Remote move returned null or invalid data structure");
      }
    } catch (e) {
      if (kDebugMode) print("DEBUG: Exception in remote AI call: $e");
      _aiErrorController
          .add("Failed to get Online AI Move. Switching to onboard AI.");
    }
    return false;
  }

  void updateDependencies(SettingsController newSettingsController) {
    final bool shouldReset = _settingsController.gameMode !=
            newSettingsController.gameMode ||
        _settingsController.boardLayout != newSettingsController.boardLayout;
    _settingsController = newSettingsController;
    if (shouldReset) initializeGame(useMicrotask: true);
  }
}
