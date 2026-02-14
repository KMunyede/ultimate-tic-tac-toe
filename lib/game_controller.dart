import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'firebase_service.dart';
//import 'logic/match_referee.dart';
import 'models/game_board.dart';
//import 'models/game_enums.dart';
import 'models/match_session.dart';
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

  MatchSession? _session;
  bool _isAiThinking = false;
  final _aiErrorController = StreamController<String>.broadcast();

  GameController(this._soundManager, this._settings, this._firebaseService) {
    initializeGame();
  }

  // Getters delegated to MatchSession
  List<GameBoard> get boards => _session?.boards ?? [];

  Player get currentPlayer => _session?.currentPlayer ?? Player.X;

  Player? get matchWinner => _session?.matchWinner;

  bool get isMatchDraw => _session?.isMatchDraw ?? false;

  bool get isOverallGameOver => _session?.isGameOver ?? false;

  bool get isAiThinking => _isAiThinking;

  Stream<String> get aiErrorStream => _aiErrorController.stream;

  String? get statusMessage {
    if (isMatchDraw) return "It's a Draw!";
    if (matchWinner != null) {
      return 'Player ${matchWinner == Player.X ? "X" : "O"} Wins!';
    }
    if (_isAiThinking) {
      return 'AI is thinking...';
    }
    return "Player ${currentPlayer == Player.X ? "X" : "O"}'s Turn";
  }

  void updateDependencies(SettingsController settings) {
    _settings = settings;
  }

  void initializeGame({bool useMicrotask = false}) {
    int count = _settings.boardCount;

    _session = MatchSession(
      boards: List.generate(count, (_) => GameBoard()),
      currentPlayer: Player.X,
    );

    _isAiThinking = false;

    if (count > 1) {
      int lastIndex = _settings.lastStartingBoardIndex;
      List<int> availableIndices = List.generate(count, (i) => i)
          .where((index) => index != lastIndex)
          .toList();

      if (availableIndices.isEmpty) {
        availableIndices = List.generate(count, (i) => i);
      }

      int newStartIndex =
          availableIndices[_random.nextInt(availableIndices.length)];
      _settings.setLastStartingBoardIndex(newStartIndex);
    }

    if (useMicrotask) {
      Future.microtask(() => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  Future<void> makeMove(int boardIndex, int cellIndex,
      {bool isAiMove = false}) async {
    if (_session == null || isOverallGameOver) return;

    if (!isAiMove) {
      if (_settings.gameMode == GameMode.playerVsAi &&
          currentPlayer == Player.O) {
        return;
      }
      if (_isAiThinking) {
        return;
      }
    }

    final success = _session!.applyMove(boardIndex, cellIndex);

    if (success) {
      _soundManager.playMoveSound();
      notifyListeners();

      if (isOverallGameOver) {
        if (matchWinner != null) {
          _settings.updateScore(matchWinner!);
        }
      } else if (_settings.gameMode == GameMode.playerVsAi &&
          currentPlayer == Player.O) {
        await _triggerAiMove();
      }
    }
  }

  Future<void> _triggerAiMove() async {
    _isAiThinking = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (_settings.useOnlineAi) {
        await _performRemoteAiMove();
      } else {
        final move = _aiService.getBestMove(boards, currentPlayer,
            _settings.aiDifficulty, _settings.boardCount);
        if (move != null) {
          await makeMove(move.boardIndex, move.cellIndex, isAiMove: true);
        }
      }
    } catch (e) {
      if (kDebugMode) print('AI Move Error: $e');
    } finally {
      _isAiThinking = false;
      notifyListeners();
    }
  }

  Future<void> _performRemoteAiMove() async {
    final boardsData = boards
        .map((b) => b.cells.map((c) => c == Player.none ? "" : c.name).toList())
        .toList();

    // Context for Online AI: What is the result of each board?
    final boardResults = boards.map((b) {
      if (b.winner == Player.X) return "playerX";
      if (b.winner == Player.O) return "playerO";
      if (b.isDraw) return "draw";
      return "active";
    }).toList();

    try {
      final result = await _firebaseService.getAiMove(
        boards: boardsData,
        boardResults: boardResults,
        player: currentPlayer,
        difficulty: _settings.aiDifficulty,
        boardCount: _settings.boardCount,
      );

      if (result != null) {
        int? finalBoardIndex = result.boardIndex;

        // Smart Mapping for Legacy or Invalid Responses
        if (finalBoardIndex == null || boards[finalBoardIndex].isGameOver) {
          finalBoardIndex = _findBestAvailableBoardForCell(result.cellIndex);
        }

        if (finalBoardIndex != null) {
          await makeMove(finalBoardIndex, result.cellIndex, isAiMove: true);
        } else {
          throw Exception(
              "AI suggested cell ${result.cellIndex} is blocked everywhere.");
        }
      } else {
        throw Exception("Invalid AI response");
      }
    } catch (e) {
      if (kDebugMode) print("Remote AI Exception: $e. Falling back.");
      _aiErrorController.add("Remote AI failed. Using local fallback.");
      final move = _aiService.getBestMove(
          boards, currentPlayer, _settings.aiDifficulty, _settings.boardCount);
      if (move != null) {
        await makeMove(move.boardIndex, move.cellIndex, isAiMove: true);
      }
    }
  }

  int? _findBestAvailableBoardForCell(int cellIndex) {
    List<int> candidates = [];
    for (int i = 0; i < boards.length; i++) {
      if (!boards[i].isGameOver && boards[i].cells[cellIndex] == Player.none) {
        candidates.add(i);
      }
    }
    if (candidates.isEmpty) return null;

    // Strategy: Prefer boards that aren't won/drawn yet
    return candidates[_random.nextInt(candidates.length)];
  }

  @override
  void dispose() {
    _aiErrorController.close();
    super.dispose();
  }
}
