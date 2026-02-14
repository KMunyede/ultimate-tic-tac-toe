import 'dart:math';

import '../models/game_board.dart';
import '../models/game_enums.dart';
import '../models/player.dart';

class AiMove {
  final int boardIndex;
  final int cellIndex;
  int score;

  AiMove(this.boardIndex, this.cellIndex, [this.score = 0]);
}

abstract class AiStrategy {
  AiMove? computeMove(List<GameBoard> boards, Player aiPlayer, int boardCount);
}

class EasyAiStrategy implements AiStrategy {
  final Random _random = Random();

  @override
  AiMove? computeMove(List<GameBoard> boards, Player aiPlayer, int boardCount) {
    List<AiMove> validMoves = _getValidMoves(boards);
    if (validMoves.isEmpty) return null;
    return validMoves[_random.nextInt(validMoves.length)];
  }
}

class MediumAiStrategy implements AiStrategy {
  final Random _random = Random();

  @override
  AiMove? computeMove(List<GameBoard> boards, Player aiPlayer, int boardCount) {
    List<AiMove> validMoves = _getValidMoves(boards);
    if (validMoves.isEmpty) return null;

    validMoves.shuffle(_random);
    AiMove? bestMove;
    int bestScore = -1000000;

    for (var move in validMoves) {
      int score = _calculateScore(boards, move, aiPlayer);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  int _calculateScore(List<GameBoard> boards, AiMove move, Player aiPlayer) {
    int score = 0;
    final opponent = aiPlayer == Player.X ? Player.O : Player.X;
    final board = boards[move.boardIndex];

    if (_simulateWin(board, move.cellIndex, aiPlayer)) score += 15000;
    if (_simulateWin(board, move.cellIndex, opponent)) score += 1000;
    if (move.cellIndex == 4) score += 100;
    if ([0, 2, 6, 8].contains(move.cellIndex)) score += 40;

    return score;
  }
}

// For now, HardAiStrategy uses the same weighted logic but can be expanded later
class HardAiStrategy extends MediumAiStrategy {
  @override
  int _calculateScore(List<GameBoard> boards, AiMove move, Player aiPlayer) {
     // Hard could include multi-board logic, minimax, etc.
     // Using the existing high-reward logic as baseline.
     return super._calculateScore(boards, move, aiPlayer);
  }
}

class AiService {
  AiMove? getBestMove(
    List<GameBoard> boards,
    Player aiPlayer,
    AiDifficulty difficulty,
    int boardCount,
  ) {
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

    return strategy.computeMove(boards, aiPlayer, boardCount);
  }
}

List<AiMove> _getValidMoves(List<GameBoard> boards) {
  List<AiMove> moves = [];
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
  board.cells[cellIndex] = player;
  bool wins = _checkWin(board, player);
  board.cells[cellIndex] = Player.none;
  return wins;
}

bool _checkWin(GameBoard board, Player player) {
  const wins = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    [0, 4, 8], [2, 4, 6]
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
