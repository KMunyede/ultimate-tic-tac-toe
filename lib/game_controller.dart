import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'firebase_service.dart';
import 'logic/match_referee.dart';
import 'models/game_board.dart';
import 'models/player.dart';
import 'services/ai_service.dart';
import 'settings_controller.dart';
import 'sound_manager.dart';

class GameController with ChangeNotifier {
  final SoundManager _soundManager;
  final FirebaseService _firebaseService;
  late SettingsController _settings;
  final AiService _aiService = AiService();
  final Random _random = Random();

  late List<GameBoard> boards;
  Player _currentPlayer = Player.X;
  Player? _matchWinner;
  bool _isAiThinking = false;
  bool _isMatchDraw = false;

  final _aiErrorController = StreamController<String>.broadcast();
  Stream<String> get aiErrorStream => _aiErrorController.stream;

  GameController(this._soundManager, this._settings, this._firebaseService) {
    initializeGame();
  }

  Player get currentPlayer => _currentPlayer;
  Player? get matchWinner => _matchWinner;
  bool get isAiThinking => _isAiThinking;
  bool get isMatchDraw => _isMatchDraw;

  String? get statusMessage {
    if (_matchWinner != null) return 'Player ${_matchWinner == Player.X ? "X" : "O"} Wins!';
    if (_isMatchDraw) return "It's a Draw!";
    if (_isAiThinking) return 'AI is thinking...';
    return "Player ${_currentPlayer == Player.X ? "X" : "O"}'s Turn";
  }

  bool get isOverallGameOver => _matchWinner != null || _isMatchDraw;
  Player? get overallWinner => _matchWinner;

  void updateDependencies(SettingsController settings) {
    _settings = settings;
  }

  void initializeGame({bool useMicrotask = false}) {
    int count = 1;
    if (_settings.boardLayout == BoardLayout.dual) count = 2;
    if (_settings.boardLayout == BoardLayout.trio) count = 3;
    if (_settings.boardLayout == BoardLayout.quad) count = 4;

    boards = List.generate(count, (_) => GameBoard());
    _currentPlayer = Player.X;
    _matchWinner = null;
    _isMatchDraw = false;
    _isAiThinking = false;

    // Logic to select a starting board that is NOT the same as the previous game's start
    if (count > 1) {
      int lastIndex = _settings.lastStartingBoardIndex;
      List<int> availableIndices = List.generate(count, (i) => i)
          .where((index) => index != lastIndex)
          .toList();
      
      // If for some reason we have no alternatives, fall back to all indices
      if (availableIndices.isEmpty) {
        availableIndices = List.generate(count, (i) => i);
      }

      int newStartIndex = availableIndices[_random.nextInt(availableIndices.length)];
      _settings.setLastStartingBoardIndex(newStartIndex);
    }

    if (useMicrotask) {
      Future.microtask(() => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  Future<void> makeMove(int boardIndex, int cellIndex, {bool isAiMove = false}) async {
    if (!isAiMove) {
      if (_settings.gameMode == GameMode.playerVsAi && _currentPlayer == Player.O) return;
      if (_isAiThinking) return;
    }

    if (isOverallGameOver ||
        boardIndex < 0 || boardIndex >= boards.length ||
        cellIndex < 0 || cellIndex >= 9 ||
        boards[boardIndex].cells[cellIndex] != Player.none ||
        boards[boardIndex].isGameOver) {
      return;
    }

    boards[boardIndex].cells[cellIndex] = _currentPlayer;
    _soundManager.playMoveSound();

    boards[boardIndex].checkWinner(_currentPlayer);
    boards[boardIndex].checkForDraw();

    _checkMatchWinner();

    if (!isOverallGameOver) {
      _switchPlayer();
      notifyListeners();

      if (_settings.gameMode == GameMode.playerVsAi && _currentPlayer == Player.O) {
        await _triggerAiMove();
      }
    } else {
      if (_matchWinner != null) {
        _settings.updateScore(_matchWinner!);
      }
      notifyListeners();
    }
  }

  void _switchPlayer() {
    _currentPlayer = (_currentPlayer == Player.X) ? Player.O : Player.X;
  }

  void _checkMatchWinner() {
    List<BoardResult> results = boards.map((b) {
      if (b.winner == Player.X) return BoardResult.playerX;
      if (b.winner == Player.O) return BoardResult.playerO;
      if (b.isDraw) return BoardResult.draw;
      return BoardResult.active;
    }).toList();

    BoardResult matchResult = MatchReferee.checkMatchWinner(results);

    if (matchResult == BoardResult.playerX) {
      _matchWinner = Player.X;
    } else if (matchResult == BoardResult.playerO) {
      _matchWinner = Player.O;
    } else if (matchResult == BoardResult.draw) {
      _isMatchDraw = true;
    }
  }

  Future<void> _triggerAiMove() async {
    _isAiThinking = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    if (_settings.useOnlineAi) {
      await _performRemoteAiMove();
    } else {
      final move = _aiService.getBestMove(boards, _currentPlayer,
          _settings.aiDifficulty, _settings.boardLayout);
      if (move != null) {
        await makeMove(move.boardIndex, move.cellIndex, isAiMove: true);
      }
    }

    _isAiThinking = false;
    notifyListeners();
  }

  Future<void> _performRemoteAiMove() async {
    final boardsData = boards.map((b) => 
      b.cells.map((c) => c == Player.none ? "" : c.name).toList()
    ).toList();

    try {
      final result = await _firebaseService.getAiMove(
        boardsData,
        _currentPlayer.name,
        _settings.aiDifficulty.name,
      );

      if (result != null) {
        await makeMove(result['boardIndex'], result['cellIndex'], isAiMove: true);
      } else {
        throw Exception("Invalid AI move");
      }
    } catch (e) {
      _aiErrorController.add("Remote AI failed. Using local fallback.");
      final move = _aiService.getBestMove(boards, _currentPlayer,
          _settings.aiDifficulty, _settings.boardLayout);
      if (move != null) {
        await makeMove(move.boardIndex, move.cellIndex, isAiMove: true);
      }
    }
  }

  @override
  void dispose() {
    _aiErrorController.close();
    super.dispose();
  }
}
