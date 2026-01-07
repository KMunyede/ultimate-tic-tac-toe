import 'dart:math';

import '../models/game_board.dart';
import '../models/game_enums.dart';
import '../models/player.dart';

/// Helper class to encapsulate a potential move.
class AiMove {
  final int boardIndex;
  final int cellIndex;
  final int score;

  AiMove(this.boardIndex, this.cellIndex, [this.score = 0]);
}

class AiService {
  final Random _random = Random();

  /// Main entry point for getting an AI move.
  AiMove? getBestMove(
    List<GameBoard> boards,
    Player aiPlayer,
    AiDifficulty difficulty,
    BoardLayout layout,
  ) {
    // 1. Gather all valid moves
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

    // 2. Dispatch based on difficulty
    switch (difficulty) {
      case AiDifficulty.easy:
        return _getEasyMove(validMoves);
      case AiDifficulty.medium:
        return _getMediumMove(boards, validMoves, aiPlayer);
      case AiDifficulty.hard:
        return _getHardMove(boards, validMoves, layout, aiPlayer);
    }
  }

  // --- EASY MODE ---
  // Pure random selection from valid moves.
  AiMove _getEasyMove(List<AiMove> moves) {
    return moves[_random.nextInt(moves.length)];
  }

  // --- MEDIUM MODE ---
  // 50% chance to play optimally (Win or Block), 50% random.
  AiMove _getMediumMove(
      List<GameBoard> boards, List<AiMove> moves, Player aiPlayer) {
    // 50% chance to just be random
    if (_random.nextBool()) {
      return moves[_random.nextInt(moves.length)];
    }

    final opponent = aiPlayer == Player.X ? Player.O : Player.X;

    // Otherwise, try to be smart:
    // 1. Check for immediate win
    for (var move in moves) {
      if (_simulateMove(boards[move.boardIndex], move.cellIndex, aiPlayer)) {
        return move;
      }
    }

    // 2. Check for blocking opponent win
    for (var move in moves) {
      if (_simulateMove(boards[move.boardIndex], move.cellIndex, opponent)) {
        return move;
      }
    }

    // 3. Default to random if no immediate threats/wins
    return moves[_random.nextInt(moves.length)];
  }

  // --- HARD MODE ---
  // Evaluates moves strategically considering the multi-board layout.
  AiMove _getHardMove(List<GameBoard> boards, List<AiMove> moves,
      BoardLayout layout, Player aiPlayer) {
    AiMove? bestMove;
    int bestScore = -999999;

    for (var move in moves) {
      int score = _evaluateMove(boards, move, layout, aiPlayer);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      } else if (score == bestScore) {
        // Randomly pick between equal moves to avoid repetitive patterns
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

    // --- 1. LOCAL BOARD HEURISTICS ---

    // Can we win this board now?
    if (_simulateMove(board, move.cellIndex, aiPlayer)) {
      // Base score for winning a board
      // INCREASED: Makes winning a board ALWAYS better than defending one (unless game over)
      int winBonus = 20000;

      // CRITICAL: In Duo/Trio, winning a board is GAME WIN if we already have others.
      // If winning this board achieves the Global Victory, prioritize it absolutely.
      if (_willWinGame(boards, move.boardIndex, aiPlayer, layout)) {
        winBonus = 100000;
      }
      score += winBonus;
    }
    // Must we block an opponent win on this board?
    else if (_simulateMove(board, move.cellIndex, opponent)) {
      // Blocking is critical.
      // Defending score must be lower than Local Win score to prioritize Winning over Defending
      int blockBonus = 15000;

      // If opponent winning this board causes them to win the GAME, blocking is absolute priority.
      if (_willWinGame(boards, move.boardIndex, opponent, layout)) {
        blockBonus = 80000;
      }
      score += blockBonus;
    } else {
      // Normal positional scoring
      if (move.cellIndex == 4) score += 5; // Center
      if ([0, 2, 6, 8].contains(move.cellIndex)) score += 3; // Corners
    }

    // --- 2. GLOBAL STRATEGIC WEIGHTS ---
    // Increase aggression: Prioritize winning moves on ANY board over passive blocking
    // unless the block saves the entire game.

    // Check if we are close to winning this specific board (e.g. 2 in a row)
    // This makes the AI "build" towards a win even if it's not immediate.
    if (_hasTwoInRow(board, aiPlayer, move.cellIndex)) {
      score += 50;
    }

    // Decrease opponent's advantage
    if (_hasTwoInRow(board, opponent, move.cellIndex)) {
      score += 40; // Block setup
    }

    return score;
  }

  // Checks if placing a piece at cellIndex creates 2-in-a-row (setup for win)
  bool _hasTwoInRow(GameBoard board, Player player, int cellIndex) {
    board.cells[cellIndex] = player; // Temporarily place
    bool threatCreated = false;

    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];

    for (var line in lines) {
      if (!line.contains(cellIndex)) continue;

      int myCount = 0;
      int emptyCount = 0;
      for (var idx in line) {
        if (board.cells[idx] == player) {
          myCount++;
        } else if (board.cells[idx] == Player.none) {
          emptyCount++;
        }
      }

      if (myCount == 2 && emptyCount == 1) {
        threatCreated = true;
        break;
      }
    }

    board.cells[cellIndex] = Player.none; // Revert
    return threatCreated;
  }

  // Returns true if placing [player] at [cellIndex] wins the board.
  bool _simulateMove(GameBoard board, int cellIndex, Player player) {
    if (board.cells[cellIndex] != Player.none) {
      return false; // Should not happen given validMoves
    }

    board.cells[cellIndex] = player;
    bool wins = _checkWin(board, player);
    board.cells[cellIndex] = Player.none; // Revert
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
      [2, 4, 6]
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

  // Checks if winning [targetBoardIndex] results in a Global Victory for [player].
  bool _willWinGame(List<GameBoard> boards, int targetBoardIndex, Player player,
      BoardLayout layout) {
    int requiredWins = (layout == BoardLayout.single)
        ? 1
        : (layout == BoardLayout.dual ? 2 : 3);
    int currentWins = 0;

    for (int i = 0; i < boards.length; i++) {
      if (i == targetBoardIndex) continue; // We are simulating winning this one
      if (boards[i].winner == player) {
        currentWins++;
      }
    }

    // If current wins + this new win == required, then yes.
    return (currentWins + 1) == requiredWins;
  }
}
