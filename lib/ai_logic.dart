import 'dart:math';
import 'package:tictactoe/models/game_board.dart';
import 'package:tictactoe/models/player.dart';
import 'package:tictactoe/settings_controller.dart';

/// Helper class to encapsulate a potential move.
class AiMove {
  final int boardIndex;
  final int cellIndex;
  final int score;

  AiMove(this.boardIndex, this.cellIndex, [this.score = 0]);
}

/// Provides AI logic for Easy, Medium, and Hard difficulties.
class AiLogic {
  static final Random _random = Random();

  /// Main entry point for getting an AI move.
  static AiMove? getBestMove(
    List<GameBoard> boards,
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
        return _getMediumMove(boards, validMoves);
      case AiDifficulty.hard:
        return _getHardMove(boards, validMoves, layout);
    }
  }

  // --- EASY MODE ---
  // Pure random selection from valid moves.
  static AiMove _getEasyMove(List<AiMove> moves) {
    return moves[_random.nextInt(moves.length)];
  }

  // --- MEDIUM MODE ---
  // 50% chance to play optimally (Win or Block), 50% random.
  static AiMove _getMediumMove(List<GameBoard> boards, List<AiMove> moves) {
    // 50% chance to just be random
    if (_random.nextBool()) {
      return moves[_random.nextInt(moves.length)];
    }

    // Otherwise, try to be smart:
    // 1. Check for immediate win
    for (var move in moves) {
      if (_simulateMove(boards[move.boardIndex], move.cellIndex, Player.O)) {
        return move;
      }
    }

    // 2. Check for blocking opponent win
    for (var move in moves) {
      if (_simulateMove(boards[move.boardIndex], move.cellIndex, Player.X)) {
        return move;
      }
    }

    // 3. Default to random if no immediate threats/wins
    return moves[_random.nextInt(moves.length)];
  }

  // --- HARD MODE ---
  // Evaluates moves strategically considering the multi-board layout.
  static AiMove _getHardMove(
      List<GameBoard> boards, List<AiMove> moves, BoardLayout layout) {
    AiMove? bestMove;
    int bestScore = -999999;

    // We use a simplified evaluation function for efficiency.
    // Instead of full Minimax, we score each move based on heuristics:
    // - Immediate Win (High Score)
    // - Blocking Loss (High Score)
    // - Creating Forks (Medium Score)
    // - Center/Corners (Low Score)
    // 
    // AND we weigh boards differently based on the "Total Domination" rule.

    for (var move in moves) {
      int score = _evaluateMove(boards, move, layout);
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

  static int _evaluateMove(List<GameBoard> boards, AiMove move, BoardLayout layout) {
    final board = boards[move.boardIndex];
    int score = 0;

    // --- 1. LOCAL BOARD HEURISTICS ---

    // Can we win this board now?
    if (_simulateMove(board, move.cellIndex, Player.O)) {
      // Base score for winning a board
      int winBonus = 1000;
      
      // CRITICAL: In Duo/Trio, winning a board is GAME WIN if we already have others.
      // If winning this board achieves the Global Victory, prioritize it absolutely.
      if (_willWinGame(boards, move.boardIndex, Player.O, layout)) {
        winBonus = 100000;
      }
      score += winBonus;
    } 
    // Must we block an opponent win on this board?
    else if (_simulateMove(board, move.cellIndex, Player.X)) {
      // Blocking is critical.
      int blockBonus = 900;
      
      // If opponent winning this board causes them to win the GAME, blocking is absolute priority.
      if (_willWinGame(boards, move.boardIndex, Player.X, layout)) {
        blockBonus = 50000; 
      }
      score += blockBonus;
    } else {
      // Normal positional scoring
      if (move.cellIndex == 4) score += 5; // Center
      if ([0, 2, 6, 8].contains(move.cellIndex)) score += 3; // Corners
    }

    // --- 2. GLOBAL STRATEGIC WEIGHTS ---
    // If we are playing Duo/Trio, we shouldn't waste moves on boards that are already "dead" 
    // (e.g., if a Draw makes the whole game a Draw, maybe we play for a Draw? 
    //  Actually, rules say "Winning 1 or 2 boards = draw" in Trio. 
    //  So winning ANY board is good, but winning ALL is best).
    
    // In "Total Domination":
    // If I lose ONE board, I cannot win. 
    // Therefore, saving a board from loss is more important than winning another one, 
    // UNLESS I can win the game right now.
    
    // Check if this specific board is currently empty vs cluttered? 
    // (Not implemented for simplicity, but we could add weights here).

    return score;
  }

  // Returns true if placing [player] at [cellIndex] wins the board.
  static bool _simulateMove(GameBoard board, int cellIndex, Player player) {
    if (board.cells[cellIndex] != Player.none) return false; // Should not happen given validMoves

    board.cells[cellIndex] = player;
    bool wins = _checkWin(board, player);
    board.cells[cellIndex] = Player.none; // Revert
    return wins;
  }

  static bool _checkWin(GameBoard board, Player player) {
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

  // Checks if winning [targetBoardIndex] results in a Global Victory for [player].
  static bool _willWinGame(List<GameBoard> boards, int targetBoardIndex, Player player, BoardLayout layout) {
    int requiredWins = (layout == BoardLayout.single) ? 1 : (layout == BoardLayout.dual ? 2 : 3);
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
