import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../services/firebase_service.dart';
import '../../../models/game_board.dart';
import '../../../models/match_session.dart';
import '../../../models/player.dart';
import '../../../services/ai_service.dart';
import '../../../services/stats_service.dart';
import '../../settings/logic/settings_controller.dart';
import '../../../core/audio/sound_manager.dart';

class GameController with ChangeNotifier {
  final SoundManager _soundManager;
  final FirebaseService _firebaseService;
  final StatsService _statsService;
  late SettingsController _settings;
  final AiService _aiService = AiService();
  final Random _random = Random();

  MatchSession? _session;
  bool _isAiThinking = false;
  int _shakeCounter = 0;
  final _aiErrorController = StreamController<String>.broadcast();

  GameController(
    this._soundManager,
    this._settings,
    this._firebaseService,
    this._statsService,
  ) {
    _initGameFromCloud();
  }

  Future<void> _initGameFromCloud() async {
    final cloudSession = await _firebaseService.loadGameState();
    if (cloudSession != null && !cloudSession.isGameOver) {
      _session = cloudSession;
      notifyListeners();
    } else {
      initializeGame();
    }
  }

  // Getters delegated to MatchSession
  List<GameBoard> get boards => _session?.boards ?? [];

  Player get currentPlayer => _session?.currentPlayer ?? Player.X;

  Player? get matchWinner => _session?.matchWinner;

  bool get isMatchDraw => _session?.isMatchDraw ?? false;

  bool get isOverallGameOver => _session?.isGameOver ?? false;

  // [NEW] Level 1: Board Wins within current match
  int get boardsWonX => _session?.boardsWonX ?? 0;

  int get boardsWonO => _session?.boardsWonO ?? 0;

  // [NEW] Level 2: Game Wins across session (from Settings)
  int get sessionWinsX => _settings.scoreX;

  int get sessionWinsO => _settings.scoreO;

  bool get isAiThinking => _isAiThinking;

  int get shakeCounter => _shakeCounter;

  Stream<String> get aiErrorStream => _aiErrorController.stream;

  int? get forcedBoardIndex => _session?.forcedBoardIndex;

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
    // Auto-trigger AI if it's AI's turn after settings update or dependency sync
    if (_settings.gameMode == GameMode.playerVsAi &&
        currentPlayer == Player.O &&
        !isOverallGameOver &&
        !_isAiThinking) {
      _triggerAiMove();
    }
  }

  void resetGame() {
    initializeGame();
  }

  void initializeGame({bool useMicrotask = false}) {
    int count = _settings.boardCount;

    _session = MatchSession(
      boards: List.generate(count, (_) => GameBoard()),
      ruleSet: _settings.ruleSet,
      currentPlayer: Player.X,
    );

    _isAiThinking = false;
    _shakeCounter = 0;

    if (count > 1) {
      int lastIndex = _settings.lastStartingBoardIndex;
      List<int> availableIndices = List.generate(
        count,
        (i) => i,
      ).where((index) => index != lastIndex).toList();

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

  Future<void> makeMove(
    int boardIndex,
    int cellIndex, {
    bool isAiMove = false,
  }) async {
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

    final bool wasMatchOverBefore = isOverallGameOver;

    final success = _session!.applyMove(boardIndex, cellIndex);

    if (success) {
      _soundManager.playMoveSound();
      
      // Sync state to Cloud
      await _firebaseService.saveGameState(_session!);

      if (!wasMatchOverBefore && isOverallGameOver) {
        if (matchWinner != null) {
          _soundManager.playWinSound();
          _shakeCounter++;
        } else if (isMatchDraw) {
          _soundManager.playDrawSound();
        }
      }

      notifyListeners();

      if (isOverallGameOver) {
        if (matchWinner != null) {
          _settings.updateScore(matchWinner!);
          _statsService.updateWinCount(matchWinner!);
        }
        // Wipe cloud session on game over to prevent resuming finished games
        await _firebaseService.saveGameState(_session!);
      } else if (_settings.gameMode == GameMode.playerVsAi &&
          currentPlayer == Player.O) {
        await _triggerAiMove();
      }
    }
  }

  Future<void> _triggerAiMove() async {
    if (isOverallGameOver || _isAiThinking || _session == null) return;

    _isAiThinking = true;
    notifyListeners();

    try {
      // Add a timeout to catch cases where AI (Remote or Local Isolate) hangs
      await Future.delayed(const Duration(milliseconds: 800));

      final aiTask = _settings.useOnlineAi
          ? _performRemoteAiMove()
          : _getAndApplyLocalMove();

      await aiTask.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _handleAiFailure("AI timed out after 15 seconds.");
          throw TimeoutException("AI took too long to respond.");
        },
      );
    } catch (e) {
      if (e is! TimeoutException) {
  
        _handleAiFailure("Critical error during AI calculation: $e");
      }
    } finally {
      _isAiThinking = false;
      notifyListeners();
    }
  }

  Future<void> _getAndApplyLocalMove() async {
    final move = await _aiService.getBestMove(
      boards,
      currentPlayer,
      _settings.aiDifficulty,
      _settings.boardCount,
      _settings.ruleSet,
      forcedBoardIndex,
    );
    if (move != null) {
      await makeMove(move.boardIndex, move.cellIndex, isAiMove: true);
    } else {
      _handleAiFailure("Local AI returned null move.");
    }
  }

  void _handleAiFailure(String reason) {
    if (kDebugMode) {

    }
    _aiErrorController.add("AI failed: $reason");
  }

  Future<void> _performRemoteAiMove() async {
    final boardsData = boards
        .map((b) => b.cells.map((c) => c == Player.none ? "" : c.name).toList())
        .toList();

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
        ruleSet: _settings.ruleSet,
        boardCount: _settings.boardCount,
        forcedBoardIndex: forcedBoardIndex,
      );

      if (result != null) {
        int boardIdx = result.boardIndex ?? (forcedBoardIndex ?? -1);
        int cellIdx = result.cellIndex;

        // Ultimate Mode Enforcement: If there's a forced board, AI must play there.
        if (_settings.ruleSet == GameRuleSet.ultimate &&
            forcedBoardIndex != null) {
          boardIdx = forcedBoardIndex!;
        }

        // Final sanity check: if the chosen board is full/won, find any valid board for this cell
        if (boardIdx == -1 || boards[boardIdx].isGameOver) {
          boardIdx = _findBestAvailableBoardForCell(cellIdx) ?? -1;
        }

        // If still invalid, find ANY valid move as a last resort before failing
        if (boardIdx == -1 || boards[boardIdx].cells[cellIdx] != Player.none) {
          final fallbackMove = await _aiService.getBestMove(
            boards,
            currentPlayer,
            _settings.aiDifficulty,
            _settings.boardCount,
            _settings.ruleSet,
            forcedBoardIndex,
          );
          if (fallbackMove != null) {
            await makeMove(fallbackMove.boardIndex, fallbackMove.cellIndex,
                isAiMove: true);
            return;
          }
          throw Exception("AI returned illegal move and fallback failed.");
        }

        await makeMove(boardIdx, cellIdx, isAiMove: true);
      } else {
        throw Exception("No response from Remote AI.");
      }
    } catch (e) {
      // We do NOT change the GameMode here. We stay in PlayerVsAi.
      _aiErrorController.add("No Response from Online AI. Falling back to Local AI");
      
      final move = await _aiService.getBestMove(
        boards,
        currentPlayer,
        _settings.aiDifficulty,
        _settings.boardCount,
        _settings.ruleSet,
        forcedBoardIndex,
      );
      
      if (move != null) {
        await makeMove(move.boardIndex, move.cellIndex, isAiMove: true);
      } else {
        _handleAiFailure("Critical: Both Remote and Local AI failed to compute a move.");
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

    return candidates[_random.nextInt(candidates.length)];
  }

  @override
  void dispose() {
    _aiErrorController.close();
    super.dispose();
  }
}
