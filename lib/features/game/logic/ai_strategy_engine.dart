// lib/features/game/logic/ai_strategy_engine.dart

import 'dart:math';
import '../../../models/player.dart';
import '../../../models/game_board.dart';
import '../../../models/game_enums.dart';
import '../../../services/ai_service.dart';

class AiStrategyEngine {
  final Random _random = Random();
  final AiService _aiService;

  AiStrategyEngine(this._aiService);

  Future<Map<String, dynamic>?> getBestMove({
    required List<GameBoard> boards,
    required Player currentPlayer,
    required GameRuleSet ruleSet,
    required AiDifficulty difficulty,
    required int boardCount,
    required bool useOnlineAi,
    int? forcedBoardIndex,
    required int hackerCards,
    required int eraserCards,
    required int shieldCards,
  }) async {
    PowerUpType? selectedAiPowerUp;
    int selectedBoardIdx = -1;
    int selectedCellIdx = -1;

    // 1. Chaos Mode Smart Heuristics
    if (ruleSet == GameRuleSet.chaos && forcedBoardIndex != null) {
      final forcedIdx = forcedBoardIndex;
      if (!boards[forcedIdx].isGameOver) {
        final board = boards[forcedIdx];

        // Heuristic 1: Counter opponent threat
        if (board.hasThreat(Player.X)) {
          int threatCellIdx = _findThreatCellIndex(board, Player.X);
          if (threatCellIdx != -1 && !board.shields[threatCellIdx]) {
            if (hackerCards > 0 && _random.nextDouble() < 0.45) {
              selectedAiPowerUp = PowerUpType.hacker;
              selectedBoardIdx = forcedIdx;
              selectedCellIdx = threatCellIdx;
            } else if (eraserCards > 0 && _random.nextDouble() < 0.35) {
              selectedAiPowerUp = PowerUpType.eraser;
              selectedBoardIdx = forcedIdx;
              selectedCellIdx = threatCellIdx;
            }
          }
        }

        // Heuristic 2: Protect own threat
        if (selectedAiPowerUp == null && board.hasThreat(Player.O) && shieldCards > 0) {
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
      return {
        'boardIndex': selectedBoardIdx,
        'cellIndex': selectedCellIdx,
        'powerUp': selectedAiPowerUp,
      };
    }

    // 2. Standard Move Search
    final aiMove = await _aiService.getBestMove(
      boards: boards,
      aiPlayer: currentPlayer,
      difficulty: difficulty,
      boardCount: boardCount,
      ruleSet: ruleSet,
      useOnlineAi: useOnlineAi,
      forcedBoardIndex: forcedBoardIndex,
    );

    if (aiMove != null) {
      return {
        'boardIndex': aiMove.boardIndex,
        'cellIndex': aiMove.cellIndex,
        'powerUp': null,
      };
    }

    return null;
  }

  AiMove? calculateFailsafeMove(List<GameBoard> boards, int? forcedBoardIndex) {
    // 1. Try forced board first
    if (forcedBoardIndex != null && forcedBoardIndex < boards.length) {
      final forcedIdx = forcedBoardIndex;
      if (!boards[forcedIdx].isGameOver) {
        for (int i = 0; i < 9; i++) {
          if (boards[forcedIdx].cells[i] == Player.none) {
            return AiMove(forcedIdx, i);
          }
        }
      }
    }
    // 2. Try any non-won board
    for (int b = 0; b < boards.length; b++) {
      if (!boards[b].isGameOver) {
        for (int c = 0; c < 9; c++) {
          if (boards[b].cells[c] == Player.none) {
            return AiMove(b, c);
          }
        }
      }
    }
    // 3. Last resort fallback
    for (int b = 0; b < boards.length; b++) {
      for (int c = 0; c < 9; c++) {
        if (boards[b].cells[c] == Player.none) {
          return AiMove(b, c);
        }
      }
    }
    return null;
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
}
