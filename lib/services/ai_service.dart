import 'dart:math';
import 'dart:isolate';

import '../models/game_board.dart';
import '../models/game_enums.dart';
import '../models/player.dart';
import '../logic/ultimate_engine.dart';

class AiMove {
  final int boardIndex;
  final int cellIndex;
  int score;

  AiMove(this.boardIndex, this.cellIndex, [this.score = 0]);
}

abstract class AiStrategy {
  AiMove? computeMove(
    List<GameBoard> boards,
    Player aiPlayer,
    int boardCount,
    GameRuleSet ruleSet, [
    int? forcedBoardIndex,
  ]);
}

class EasyAiStrategy implements AiStrategy {
  final Random _random = Random();

  @override
  AiMove? computeMove(
    List<GameBoard> boards,
    Player aiPlayer,
    int boardCount,
    GameRuleSet ruleSet, [
    int? forcedBoardIndex,
  ]) {
    List<AiMove> validMoves = _getValidMoves(boards, forcedBoardIndex);
    if (validMoves.isEmpty) return null;
    return validMoves[_random.nextInt(validMoves.length)];
  }
}

class MediumAiStrategy implements AiStrategy {
  final Random _random = Random();

  @override
  AiMove? computeMove(
    List<GameBoard> boards,
    Player aiPlayer,
    int boardCount,
    GameRuleSet ruleSet, [
    int? forcedBoardIndex,
  ]) {
    List<AiMove> validMoves = _getValidMoves(boards, forcedBoardIndex);
    if (validMoves.isEmpty) return null;

    validMoves.shuffle(_random);
    AiMove? bestMove;
    int bestScore = -2000000;

    for (var move in validMoves) {
      int score = _calculateScore(boards, move, aiPlayer, boardCount, ruleSet);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  int _calculateScore(List<GameBoard> boards, AiMove move, Player aiPlayer, int boardCount, GameRuleSet ruleSet) {
    int score = 0;
    final opponent = aiPlayer == Player.X ? Player.O : Player.X;
    final board = boards[move.boardIndex];

    // 1. Basic board-level tactics (Immediate wins/blocks)
    if (_simulateWin(board, move.cellIndex, aiPlayer)) score += 20000;
    if (_simulateWin(board, move.cellIndex, opponent)) score += 15000;
    
    // Positional value within the small board
    if (move.cellIndex == 4) score += 1000;
    if ([0, 2, 6, 8].contains(move.cellIndex)) score += 400;

    // 2. Meta-board tactics (for Ultimate mode)
    if (ruleSet == GameRuleSet.ultimate && boards.length == 9) {
      // Winning/Blocking the entire Match
      if (_simulateBoardWinWinsMatch(boards, move, aiPlayer)) {
        score += 2000000; 
      }
      if (_simulateBoardWinWinsMatch(boards, move, opponent)) {
        score += 1000000; 
      }

      // Meta-Positional Scoring: Board importance on the 3x3 meta-grid
      if (move.boardIndex == 4) score += 8000; // Center board is king
      if ([0, 2, 6, 8].contains(move.boardIndex)) score += 3000; // Corners

      // Meta-Line Advancement: Does winning this board help complete a line on the big grid?
      score += _evaluateMetaAdvantage(boards, move.boardIndex, aiPlayer) * 5000;
      score += _evaluateMetaAdvantage(boards, move.boardIndex, opponent) * 4000;

      // Forced Board Management: Avoid giving a free move
      int nextForcedBoard = move.cellIndex;
      if (boards[nextForcedBoard].isGameOver) {
        score -= 10000; // Penalty for granting a free move
      }
    }

    return score;
  }

  /// Calculates how many meta-lines are influenced by winning this board.
  int _evaluateMetaAdvantage(List<GameBoard> boards, int boardIndex, Player player) {
    int advantage = 0;
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6],           // Diags
    ];

    for (var line in wins) {
      if (line.contains(boardIndex)) {
        int playerCount = 0;
        int opponentCount = 0;
        for (int idx in line) {
          if (boards[idx].winner == player) {
            playerCount++;
          } else if (boards[idx].winner != null) {
            opponentCount++;
          }
        }
        
        // If line is still winnable for 'player'
        if (opponentCount == 0) {
          if (playerCount == 1) {
            advantage += 2; // Creating a 2-in-a-row on meta-grid
          } else if (playerCount == 0) {
            advantage += 1; // Starting a new line
          }
        }
      }
    }
    return advantage;
  }

  bool _simulateBoardWinWinsMatch(List<GameBoard> boards, AiMove move, Player player) {
    final board = boards[move.boardIndex];
    if (!_simulateWin(board, move.cellIndex, player)) return false;

    // Fast check without re-mapping the whole list if possible
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    return wins.any((line) {
      return line.every((idx) {
        if (idx == move.boardIndex) return true; // We just simulated this win
        final b = boards[idx];
        return b.winner == player;
      });
    });
  }
}

class HardAiStrategy extends MediumAiStrategy {
  @override
  AiMove? computeMove(
    List<GameBoard> boards,
    Player aiPlayer,
    int boardCount,
    GameRuleSet ruleSet, [
    int? forcedBoardIndex,
  ]) {
    if (ruleSet == GameRuleSet.ultimate && boards.length == 9) {
      final engine = UltimateEngine.fromState(boards, forcedBoardIndex);
      final int aiVal = aiPlayer == Player.X ? 1 : -1;
      
      // Depth 5 as requested for memory efficiency/performance
      final result = engine.minimax(5, -2000000, 2000000, aiVal, aiVal);
      final int bestMoveIndex = result[1];
      
      if (bestMoveIndex != -1) {
        return AiMove(bestMoveIndex ~/ 9, bestMoveIndex % 9, result[0]);
      }
    }
    
    return super.computeMove(boards, aiPlayer, boardCount, ruleSet, forcedBoardIndex);
  }

  @override
  int _calculateScore(List<GameBoard> boards, AiMove move, Player aiPlayer, int boardCount, GameRuleSet ruleSet) {
    // ... existing implementation remains as fallback for non-ultimate or if minimax fails
    int score = super._calculateScore(boards, move, aiPlayer, boardCount, ruleSet);
    
    if (ruleSet == GameRuleSet.ultimate) {
      final opponent = aiPlayer == Player.X ? Player.O : Player.X;
      int nextForcedBoardIndex = move.cellIndex;
      final nextBoard = boards[nextForcedBoardIndex];

      if (nextBoard.isGameOver) {
        if (score < 1000000) {
          score -= 15000;
        }
      } else {
        if (_canOpponentWinMatchInBoard(boards, nextForcedBoardIndex, opponent)) {
          score -= 800000;
        }
        if (_canPlayerWinBoard(nextBoard, opponent)) {
          score -= 30000;
        } else if (nextBoard.hasThreat(opponent)) {
          score -= 10000;
        }
      }
    }

    return score;
  }

  bool _canOpponentWinMatchInBoard(List<GameBoard> boards, int boardIndex, Player opponent) {
    final board = boards[boardIndex];
    for (int i = 0; i < 9; i++) {
      if (board.cells[i] == Player.none) {
        if (_simulateBoardWinWinsMatch(boards, AiMove(boardIndex, i), opponent)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _canPlayerWinBoard(GameBoard board, Player player) {
    for (int i = 0; i < 9; i++) {
      if (board.cells[i] == Player.none) {
        if (_simulateWin(board, i, player)) return true;
      }
    }
    return false;
  }
}

class AiService {
  Future<AiMove?> getBestMove(
    List<GameBoard> boards,
    Player aiPlayer,
    AiDifficulty difficulty,
    int boardCount,
    GameRuleSet ruleSet, [
    int? forcedBoardIndex,
  ]) async {
    return await Isolate.run(() {
      AiStrategy strategy;
      switch (difficulty) {
        case AiDifficulty.easy:
          strategy = EasyAiStrategy();
          break;
        case AiDifficulty.medium:
          strategy = MediumAiStrategy();
          break;
        case AiDifficulty.hard:
          strategy = HardAiStrategy();
          break;
      }

      return strategy.computeMove(
        boards,
        aiPlayer,
        boardCount,
        ruleSet,
        forcedBoardIndex,
      );
    });
  }
}

List<AiMove> _getValidMoves(List<GameBoard> boards, [int? forcedBoardIndex]) {
  List<AiMove> moves = [];

  // If there's a forced board, we must play there if it's not full/won
  if (forcedBoardIndex != null &&
      forcedBoardIndex < boards.length &&
      !boards[forcedBoardIndex].isGameOver) {
    for (int c = 0; c < 9; c++) {
      if (boards[forcedBoardIndex].cells[c] == Player.none) {
        moves.add(AiMove(forcedBoardIndex, c));
      }
    }
    if (moves.isNotEmpty) return moves;
  }

  // Otherwise, all available cells on all non-finished boards are valid
  for (int b = 0; b < boards.length; b++) {
    if (!boards[b].isGameOver) {
      for (int c = 0; c < 9; c++) {
        if (boards[b].cells[c] == Player.none) {
          moves.add(AiMove(b, c));
        }
      }
    }
  }
  return moves;
}

bool _simulateWin(GameBoard board, int cellIndex, Player player) {
    if (board.cells[cellIndex] != Player.none) {
      return false;
    }
    board.cells[cellIndex] = player;
    bool wins = _checkWin(board, player);
    board.cells[cellIndex] = Player.none;
    return wins;
}

bool _checkWin(GameBoard board, Player player) {
  const wins = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];
  for (var line in wins) {
    if (board.cells[line[0]] == player &&
        board.cells[line[1]] == player &&
        board.cells[line[2]] == player) {
      return true;
    }
  }
  return false;
}
