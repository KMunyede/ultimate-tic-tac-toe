import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../services/firebase_service.dart';
import '../../../models/game_board.dart';
import '../../../models/match_session.dart';
import '../../../models/player.dart';
import '../../../logic/match_referee.dart';
import '../../../services/ai_service.dart';
import '../../../services/stats_service.dart';
import '../../settings/logic/settings_controller.dart';
import '../../../core/audio/sound_manager.dart';

class GameController with ChangeNotifier {
  final SoundManager _soundManager;
  final FirebaseService _firebaseService;
  final StatsService _statsService;
  late SettingsController _settings;
  late final AiService _aiService;
  final Random _random = Random();

  MatchSession? _session;
  MatchSession? _pendingCloudSession; // Store for user prompt
  bool _isAiThinking = false;
  bool _isCompletingMove = false; // Guard for state transitions
  int _shakeCounter = 0;
  int _matchId = 0;
  final _aiErrorController = StreamController<String>.broadcast();

  int get matchId => _matchId;

  // [NEW] Active power-up card states
  PowerUpType? _activePowerUp;
  PowerUpType? get activePowerUp => _activePowerUp;

  void selectPowerUp(PowerUpType? type) {
    if (_activePowerUp == type) {
      _activePowerUp = null; // Toggle off
    } else {
      _activePowerUp = type;
    }
    notifyListeners();
  }

  // [NEW] Card inventory delegations to MatchSession
  int get shieldCardsX => _session?.shieldCardsX ?? 0;
  int get eraserCardsX => _session?.eraserCardsX ?? 0;
  int get hackerCardsX => _session?.hackerCardsX ?? 0;

  int get shieldCardsO => _session?.shieldCardsO ?? 0;
  int get eraserCardsO => _session?.eraserCardsO ?? 0;
  int get hackerCardsO => _session?.hackerCardsO ?? 0;

  GameController(
    this._soundManager,
    this._settings,
    this._firebaseService,
    this._statsService,
  ) : _aiService = AiService(_firebaseService) {
    _initGameFromCloud();
  }

  Future<void> _initGameFromCloud() async {
    // Registered users check for cloud state; Guests always start fresh
    if (!_settings.isGuest) {
      final cloudSession = await _firebaseService.loadGameState();
      if (cloudSession != null && !cloudSession.isGameOver) {
        _pendingCloudSession = cloudSession;
        Future.microtask(() => notifyListeners());
        return;
      }
    }
    
    initializeGame(useMicrotask: true);
  }

  /// Called by the UI when the user decides whether to resume or start new.
  void resolvePendingSession({required bool resume}) {
    if (_pendingCloudSession == null) return;

    if (resume) {
      _session = _pendingCloudSession;
      _pendingCloudSession = null;
      notifyListeners();
    } else {
      _pendingCloudSession = null;
      initializeGame();
    }
  }

  // Getters delegated to MatchSession
  List<GameBoard> get boards => _session?.boards ?? [];

  Player get currentPlayer => _session?.currentPlayer ?? Player.X;

  Player? get matchWinner => _session?.matchWinner;

  MatchOutcome get matchOutcome => _session?.outcome ?? MatchOutcome.active;

  bool get hasPendingCloudSession => _pendingCloudSession != null;

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
    if (isOverallGameOver) {
      if (matchOutcome == MatchOutcome.winX) return 'Player X Wins!';
      if (matchOutcome == MatchOutcome.winO) return 'Player O Wins!';
      if (matchOutcome == MatchOutcome.draw) return "It's A Draw! Play Again?";
      if (matchOutcome == MatchOutcome.noWinner) {
        return (boardsWonX + boardsWonO) > 0 
            ? "No clear winner. Play again?" 
            : "No wins. Try again";
      }
    }

    if (_isAiThinking) {
      return 'AI is thinking...';
    }
    return "Player ${currentPlayer == Player.X ? "X" : "O"}'s Turn";
  }

  String get winTargetMessage {
    if (isOverallGameOver) return "";
    
    final count = boards.length;
    final ruleSet = _settings.ruleSet;
    
    if (ruleSet == GameRuleSet.ultimate) {
      return "Conquer 3-in-a-row to claim Victory";
    }
    
    if (ruleSet == GameRuleSet.standard) {
      if (count == 1) return "Conquer the board to claim Victory";
      if (count == 2) return "Conquer both boards to claim Victory";
    }
    
    if (ruleSet == GameRuleSet.majorityWins) {
      switch (count) {
        case 1: return "Conquer the board to claim Victory";
        case 2: return "Conquer 2 boards to claim Victory";
        case 3: return "Conquer 2 or 3 boards to claim Victory";
        case 4: return "Conquer 3 or 4 boards to claim Victory";
        case 5: return "Conquer 4 or 5 boards to claim Victory";
        case 6: return "Conquer 4, 5 or 6 boards to claim Victory";
        case 7: return "Conquer 5, 6 or 7 boards to claim Victory";
        case 8: return "Conquer 5, 6, 7 or 8 boards to claim Victory";
        case 9: return "Conquer 5, 6, 7, 8 or 9 boards to claim Victory";
      }
    }
    
    return "";
  }

  void updateDependencies(SettingsController settings) {
    _settings = settings;
    // Auto-trigger AI if it's AI's turn after settings update or dependency sync
    if (_settings.gameMode == GameMode.playerVsAi &&
        currentPlayer == Player.O &&
        !isOverallGameOver &&
        !_isAiThinking &&
        !_isCompletingMove) {
      // Use microtask to avoid notifying during the build phase of a ProxyProvider
      Future.microtask(() => _triggerAiMove());
    }
  }

  void resetGame() {
    initializeGame();
  }

  /// Explicitly saves the current game state to the cloud/local storage.
  /// Used for lifecycle management (pausing/resuming).
  Future<void> saveCurrentState() async {
    // Only registered users persist state across sessions
    if (!_settings.isGuest && _session != null && !isOverallGameOver) {
      await _firebaseService.saveGameState(_session!);
    }
  }

  void initializeGame({bool useMicrotask = false}) {
    _matchId++;
    int count = _settings.boardCount;
    int? initialForcedBoardIndex;

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

      if (_settings.ruleSet == GameRuleSet.ultimate) {
        initialForcedBoardIndex = newStartIndex;
      }
    }

    _session = MatchSession(
      boards: List.generate(count, (_) => GameBoard()),
      ruleSet: _settings.ruleSet,
      currentPlayer: Player.X,
      forcedBoardIndex: initialForcedBoardIndex,
    );

    _isAiThinking = false;
    _shakeCounter = 0;

    // Sync to cloud immediately for registered users to start a fresh "session"
    if (!_settings.isGuest) {
      unawaited(_firebaseService.saveGameState(_session!));
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
    PowerUpType? aiPowerUp,
  }) async {
    if (_session == null || isOverallGameOver) return;

    if (isAiMove) {
      if (_settings.gameMode != GameMode.playerVsAi ||
          currentPlayer != Player.O) {
        return;
      }
    }

    if (!isAiMove) {
      if (_settings.gameMode == GameMode.playerVsAi &&
          currentPlayer == Player.O) {
        return;
      }
      if (_isAiThinking || _isCompletingMove) {
        return;
      }
    }

    _isCompletingMove = true;
    final bool wasMatchOverBefore = isOverallGameOver;

    final bool success;
    if (!isAiMove && _activePowerUp != null) {
      success = _session!.applyPowerUp(boardIndex, cellIndex, _activePowerUp!);
      if (success) {
        _activePowerUp = null; // Reset selection on success
      }
    } else if (isAiMove && aiPowerUp != null) {
      success = _session!.applyPowerUp(boardIndex, cellIndex, aiPowerUp);
    } else {
      success = _session!.applyMove(boardIndex, cellIndex);
    }

    if (success) {
      // 1. Play sound immediately
      _soundManager.playMoveSound();

      // 2. Notify listeners IMMEDIATELY so the mark appears without lag
      notifyListeners();

      // 3. Handle Game Over sounds/stats
      if (!wasMatchOverBefore && isOverallGameOver) {
        if (matchWinner != null) {
          _soundManager.playWinSound();
          _shakeCounter++;
          
          // Persist Game Win for ALL users (Guest and Registered)
          _settings.updateScore(matchWinner!);
        } else if (isMatchDraw) {
          _soundManager.playDrawSound();
        }

        // Record progression stats (wins, losses, draws, and XP grants)
        unawaited(_statsService.recordMatchOutcome(
          gameMode: _settings.gameMode,
          aiDifficulty: _settings.aiDifficulty,
          outcome: matchOutcome,
        ));
      }

      // 4. Background Cloud Sync (don't block the UI thread)
      if (!_settings.isGuest) {
        unawaited(_firebaseService.saveGameState(_session!));
      }

      _isCompletingMove = false;

      // 5. Trigger AI if necessary
      if (!isOverallGameOver &&
          _settings.gameMode == GameMode.playerVsAi &&
          currentPlayer == Player.O) {
        await _triggerAiMove();
      }
    } else {
      _isCompletingMove = false;
    }
  }

  Future<void> _triggerAiMove() async {
    if (isOverallGameOver || _isAiThinking || _session == null) return;

    final currentMatchId = _matchId;
    _isAiThinking = true;
    notifyListeners();

    // Intentional suspenseful delay to simulate AI calculation and allow LED tickers to register
    await Future.delayed(const Duration(milliseconds: 1400));

    if (_matchId != currentMatchId || isOverallGameOver || _session == null) {
      return;
    }
    if (_settings.gameMode != GameMode.playerVsAi || currentPlayer != Player.O) {
      _isAiThinking = false;
      notifyListeners();
      return;
    }

    try {
      PowerUpType? selectedAiPowerUp;
      int selectedBoardIdx = -1;
      int selectedCellIdx = -1;

      // Smart AI Heuristic for Chaos Mode (AI is O)
      if (_settings.ruleSet == GameRuleSet.chaos && forcedBoardIndex != null) {
        final forcedIdx = forcedBoardIndex!;
        if (!boards[forcedIdx].isGameOver) {
          final board = boards[forcedIdx];
          
          // Heuristic 1: If opponent (X) is about to win the sub-board, Hacker/Erase it
          if (board.hasThreat(Player.X)) {
            int threatCellIdx = _findThreatCellIndex(board, Player.X);
            if (threatCellIdx != -1 && !board.shields[threatCellIdx]) {
              if (hackerCardsO > 0 && _random.nextDouble() < 0.45) {
                selectedAiPowerUp = PowerUpType.hacker;
                selectedBoardIdx = forcedIdx;
                selectedCellIdx = threatCellIdx;
              } else if (eraserCardsO > 0 && _random.nextDouble() < 0.35) {
                selectedAiPowerUp = PowerUpType.eraser;
                selectedBoardIdx = forcedIdx;
                selectedCellIdx = threatCellIdx;
              }
            }
          }
          
          // Heuristic 2: If AI itself is close to a sub-board win, protect the board or shield key marks
          if (selectedAiPowerUp == null && board.hasThreat(Player.O) && shieldCardsO > 0) {
            int emptyThreatCellIdx = _findThreatCellIndex(board, Player.O);
            if (emptyThreatCellIdx != -1 && !board.shields[emptyThreatCellIdx] && _random.nextDouble() < 0.35) {
              selectedAiPowerUp = PowerUpType.shield;
              selectedBoardIdx = forcedIdx;
              selectedCellIdx = emptyThreatCellIdx;
            }
          }
        }
      }

      if (selectedAiPowerUp != null) {
        await makeMove(selectedBoardIdx, selectedCellIdx, isAiMove: true, aiPowerUp: selectedAiPowerUp);
      } else {
        final aiMove = await _aiService.getBestMove(
          boards: boards,
          aiPlayer: currentPlayer,
          difficulty: _settings.aiDifficulty,
          boardCount: _settings.boardCount,
          ruleSet: _settings.ruleSet,
          useOnlineAi: _settings.useOnlineAi,
          forcedBoardIndex: forcedBoardIndex,
        ).timeout(const Duration(seconds: 20));

        if (aiMove != null) {
          await makeMove(aiMove.boardIndex, aiMove.cellIndex, isAiMove: true);
        } else {
          _handleAiFailure("AI could not determine a valid move.");
        }
      }
    } catch (e) {
      _handleAiFailure("AI calculation error: $e");
    } finally {
      _isAiThinking = false;
      notifyListeners();
    }
  }

  int _findThreatCellIndex(GameBoard board, Player player) {
    const List<List<int>> winningCombos = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final combo in winningCombos) {
      int count = 0;
      int emptyIdx = -1;
      for (int idx in combo) {
        if (board.cells[idx] == player) {
          count++;
        } else if (board.cells[idx] == Player.none) {
          emptyIdx = idx;
        }
      }
      if (count == 2 && emptyIdx != -1) {
        return emptyIdx;
      }
    }
    return -1;
  }

  void _handleAiFailure(String reason) {
    _aiErrorController.add(reason);
  }

  @override
  void dispose() {
    _aiErrorController.close();
    super.dispose();
  }
}
