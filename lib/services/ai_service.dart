import 'dart:math';

import '../logic/match_referee.dart';
import '../models/game_board.dart';
import '../models/game_enums.dart';
import '../models/player.dart';

class AiMove {
  final int boardIndex;
  final int cellIndex;
  int score;

  AiMove(this.boardIndex, this.cellIndex, [this.score = 0]);
}

class AiService {
  final Random _random = Random();

  AiMove? getBestMove(
    List<GameBoard> boards,
    Player aiPlayer,
    AiDifficulty difficulty,
    BoardLayout layout,
  ) {
    // Gather all valid moves from all active boards
    List<AiMove> validMoves = [];
    for (int b = 0; b < boards.length; b++) {
      if (!boards[b].isGameOver) {
        for (int c = 0; c < 9; c++) {
          if (boards[b].cells[c] == Player.none) {
            validMoves.add(AiMove(b, c));
          }
        }
      }
    }

    if (validMoves.isEmpty) return null;

    // Shuffle moves initially to eliminate any inherent scanning bias (e.g. top-left)
    validMoves.shuffle(_random);

    switch (difficulty) {
      case AiDifficulty.easy:
        return _getEasyMove(validMoves);
      case AiDifficulty.medium:
        return _getMediumMove(boards, validMoves, aiPlayer);
      case AiDifficulty.hard:
        return _getHardMove(boards, validMoves, layout, aiPlayer);
    }
  }

  AiMove _getEasyMove(List<AiMove> moves) {
    return moves[_random.nextInt(moves.length)];
  }

  AiMove _getMediumMove(
      List<GameBoard> boards, List<AiMove> moves, Player aiPlayer) {
    final opponent = aiPlayer == Player.X ? Player.O : Player.X;

    // 1. Priority: Win any board
    for (var move in moves) {
      if (_simulateMove(boards[move.boardIndex], move.cellIndex, aiPlayer)) {
        return move;
      }
    }

    // 2. Priority: Block opponent from winning any board
    for (var move in moves) {
      if (_simulateMove(boards[move.boardIndex], move.cellIndex, opponent)) {
        return move;
      }
    }

    return moves[_random.nextInt(moves.length)];
  }

  AiMove _getHardMove(List<GameBoard> boards, List<AiMove> moves,
      BoardLayout layout, Player aiPlayer) {
    final opponent = aiPlayer == Player.X ? Player.O : Player.X;

    // 1. Immediate Match Win: Check if any move wins the entire game
    for (var move in moves) {
      if (_simulateMove(boards[move.boardIndex], move.cellIndex, aiPlayer)) {
        if (_willWinGame(boards, move.boardIndex, aiPlayer, layout)) {
          return move;
        }
      }
    }

    // 2. Immediate Match Save: Check if any move blocks opponent from winning the entire game
    for (var move in moves) {
      if (_simulateMove(boards[move.boardIndex], move.cellIndex, opponent)) {
        if (_willWinGame(boards, move.boardIndex, opponent, layout)) {
          return move;
        }
      }
    }

    // 3. Strategic Evaluation
    AiMove? bestMove;
    int bestScore = -9999999;

    for (var move in moves) {
      int currentScore = _evaluateMove(boards, move, layout, aiPlayer);
      if (currentScore > bestScore) {
        bestScore = currentScore;
        bestMove = move;
      } else if (currentScore == bestScore) {
        // If scores are tied, randomize to eliminate board bias
        if (_random.nextBool()) {
          bestMove = move;
        }
      }
    }

    return bestMove ?? moves[_random.nextInt(moves.length)];
  }

  int _evaluateMove(List<GameBoard> boards, AiMove move, BoardLayout layout,
      Player aiPlayer) {
    final board = boards[move.boardIndex];
    int score = 0;
    final opponent = aiPlayer == Player.X ? Player.O : Player.X;

    // A. Multi-Board Match Strategy (Highest Importance)
    if (_simulateMove(board, move.cellIndex, aiPlayer)) {
      if (_willWinGame(boards, move.boardIndex, aiPlayer, layout)) {
        score += 1000000; // Winning the match
      } else {
        score += 5000; // Winning a board
      }
    } else if (_simulateMove(board, move.cellIndex, opponent)) {
      if (_willWinGame(boards, move.boardIndex, opponent, layout)) {
        score += 800000; // Blocking match loss
      } else {
        score += 4000; // Blocking board loss
      }
    }

    // B. Board-Level Position Strategy
    if (move.cellIndex == 4) score += 100; // Center is valuable
    if ([0, 2, 6, 8].contains(move.cellIndex)) score += 40; // Corners are good

    // C. Combo Potential
    if (_hasTwoInRow(board, aiPlayer, move.cellIndex)) score += 200;
    if (_hasTwoInRow(board, opponent, move.cellIndex)) score += 150;

    // D. Aggression/Board Control
    final piecesPlayed = board.cells.where((c) => c != Player.none).length;
    score += (9 - piecesPlayed) * 10;

    return score;
  }

  bool _hasTwoInRow(GameBoard board, Player player, int cellIndex) {
    board.cells[cellIndex] = player;
    bool threatCreated = false;

    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    for (var line in lines) {
      if (!line.contains(cellIndex)) continue;

      int myCount = 0;
      int emptyCount = 0;
      for (var idx in line) {
        if (board.cells[idx] == player) myCount++;
        else if (board.cells[idx] == Player.none) emptyCount++;
      }

      if (myCount == 2 && emptyCount == 1) {
        threatCreated = true;
        break;
      }
    }

    board.cells[cellIndex] = Player.none;
    return threatCreated;
  }

  bool _simulateMove(GameBoard board, int cellIndex, Player player) {
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

  bool _willWinGame(List<GameBoard> boards, int targetBoardIndex, Player player,
      BoardLayout layout) {
    final numberOfBoards = boards.length;
    final requiredWins = MatchReferee.getRequiredWins(numberOfBoards);

    int currentWins = 0;

    for (int i = 0; i < boards.length; i++) {
      if (i == targetBoardIndex) {
        currentWins++;
        continue;
      }
      if (boards[i].winner == player) {
        currentWins++;
      }
    }

    return currentWins >= requiredWins;
  }
}
