import 'dart:math';
import '../models/game_board.dart';
import '../models/player.dart';

/// A memory-efficient engine for Ultimate Tic-Tac-Toe.
/// Optimized for Minimax with Alpha-Beta Pruning using a single-state approach.
class UltimateEngine {
  // Global board: 81 squares. 0: Empty, 1: Player 1, -1: Player 2
  final List<int> board = List.filled(81, 0);

  // Macro board: 9 local boards. Caches won local boards.
  final List<int> macroBoard = List.filled(9, 0);

  // -1 allows free play, 0-8 restricts move
  int activeBoardIndex = -1;

  UltimateEngine();

  /// Initialize from the existing game state models.
  UltimateEngine.fromState(List<GameBoard> boards, int? forcedBoardIndex) {
    for (int b = 0; b < 9; b++) {
      if (b >= boards.length) continue;
      final boardState = boards[b];
      for (int c = 0; c < 9; c++) {
        final p = boardState.cells[c];
        board[b * 9 + c] = p == Player.X ? 1 : (p == Player.O ? -1 : 0);
      }
      if (boardState.winner == Player.X) {
        macroBoard[b] = 1;
      } else if (boardState.winner == Player.O) {
        macroBoard[b] = -1;
      } else if (boardState.isDraw) {
        macroBoard[b] = 2;
      } else {
        macroBoard[b] = 0;
      }
    }
    activeBoardIndex = forcedBoardIndex ?? -1;
  }

  /// Executes a move and updates the state.
  /// Exactly follows the requested sequence.
  bool makeMove(int moveIndex, int player) {
    // Map Coordinates
    final int localBoard = moveIndex ~/ 9;
    final int localSquare = moveIndex % 9;

    // Validate Move
    if (board[moveIndex] != 0) return false;
    if (activeBoardIndex != -1 && localBoard != activeBoardIndex) return false;

    // Apply State
    board[moveIndex] = player;

    // Evaluate Local Win
    final int localWinner = _checkLocalWin(localBoard);
    if (localWinner != 0) {
      macroBoard[localBoard] = localWinner;
    } else if (_isLocalFull(localBoard)) {
      macroBoard[localBoard] = 2; // Cache draw as 2 for efficiency
    }

    // Set Next Constraint
    activeBoardIndex = localSquare;

    // Apply Override
    // Check if the macro-board at the new activeBoardIndex is already won (!= 0) or completely full.
    if (macroBoard[activeBoardIndex] != 0 || _isLocalFull(activeBoardIndex)) {
      activeBoardIndex = -1;
    }

    // Evaluate Global Win is checked externally via checkGlobalWin()
    return true;
  }

  /// Reverts a move to restore the previous state.
  /// Uses a specialized version that also restores macroBoard to allow for local win resets.
  void undoMove(int moveIndex, int previousActiveBoardIndex, int previousMacroValue) {
    board[moveIndex] = 0;
    macroBoard[moveIndex ~/ 9] = previousMacroValue;
    activeBoardIndex = previousActiveBoardIndex;
  }

  /// Minimax with Alpha-Beta Pruning.
  List<int> minimax(int depth, int alpha, int beta, int player, int aiPlayer) {
    final int status = checkGlobalWin();
    if (status != 0) {
      if (status == aiPlayer) return [1000000 + depth, -1];
      if (status == -aiPlayer) return [-1000000 - depth, -1];
      return [0, -1];
    }
    if (depth == 0) {
      return [evaluate(aiPlayer), -1];
    }

    final List<int> moves = getValidMoves();
    if (moves.isEmpty) return [0, -1];

    // Move ordering for alpha-beta efficiency
    _sortMoves(moves, player);

    int bestMove = -1;

    if (player == aiPlayer) {
      int maxEval = -2000000;
      for (final move in moves) {
        final int prevActive = activeBoardIndex;
        final int prevMacro = macroBoard[move ~/ 9];
        
        if (makeMove(move, player)) {
          final int eval = minimax(depth - 1, alpha, beta, -player, aiPlayer)[0];
          undoMove(move, prevActive, prevMacro);

          if (eval > maxEval) {
            maxEval = eval;
            bestMove = move;
          }
          alpha = max(alpha, eval);
          if (beta <= alpha) break;
        }
      }
      return [maxEval, bestMove];
    } else {
      int minEval = 2000000;
      for (final move in moves) {
        final int prevActive = activeBoardIndex;
        final int prevMacro = macroBoard[move ~/ 9];
        
        if (makeMove(move, player)) {
          final int eval = minimax(depth - 1, alpha, beta, -player, aiPlayer)[0];
          undoMove(move, prevActive, prevMacro);

          if (eval < minEval) {
            minEval = eval;
            bestMove = move;
          }
          beta = min(beta, eval);
          if (beta <= alpha) break;
        }
      }
      return [minEval, bestMove];
    }
  }

  void _sortMoves(List<int> moves, int player) {
    moves.sort((a, b) {
      int scoreA = _quickEvaluateMove(a, player);
      int scoreB = _quickEvaluateMove(b, player);
      return scoreB.compareTo(scoreA);
    });
  }

  int _quickEvaluateMove(int moveIndex, int player) {
    int score = 0;
    int localSquare = moveIndex % 9;
    if (localSquare == 4) score += 10;
    if (const [0, 2, 6, 8].contains(localSquare)) score += 5;
    return score;
  }

  int _checkLocalWin(int boardIdx) {
    final int start = boardIdx * 9;
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];
    for (final w in wins) {
      final int a = board[start + w[0]];
      if (a != 0 && a == board[start + w[1]] && a == board[start + w[2]]) {
        return a;
      }
    }
    return 0;
  }

  bool _isLocalFull(int boardIdx) {
    final int start = boardIdx * 9;
    for (int i = 0; i < 9; i++) {
      if (board[start + i] == 0) return false;
    }
    return true;
  }

  /// Checks macroBoard for a 3-in-a-row global win.
  int checkGlobalWin() {
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];
    for (final w in wins) {
      final int a = macroBoard[w[0]];
      if (a != 0 && a != 2 && a == macroBoard[w[1]] && a == macroBoard[w[2]]) {
        return a;
      }
    }
    if (!macroBoard.contains(0)) return 2; // Draw
    return 0;
  }

  int evaluate(int aiPlayer) {
    final int status = checkGlobalWin();
    if (status == aiPlayer) return 1000000;
    if (status == -aiPlayer) return -1000000;
    if (status == 2) return 0;

    int score = 0;
    const macroWeights = [30, 20, 30, 20, 50, 20, 30, 20, 30];
    for (int i = 0; i < 9; i++) {
      if (macroBoard[i] == aiPlayer) {
        score += macroWeights[i] * 500;
      } else if (macroBoard[i] == -aiPlayer) {
        score -= macroWeights[i] * 500;
      } else if (macroBoard[i] == 0) {
        score += _countLocalThreats(i, aiPlayer) * 50;
        score -= _countLocalThreats(i, -aiPlayer) * 50;
      }
    }
    return score;
  }

  int _countLocalThreats(int boardIdx, int player) {
    final int start = boardIdx * 9;
    int threats = 0;
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];
    for (final line in lines) {
      int count = 0;
      int empty = 0;
      for (final i in line) {
        if (board[start + i] == player) {
          count++;
        } else if (board[start + i] == 0) {
          empty++;
        }
      }
      if (count == 2 && empty == 1) threats++;
    }
    return threats;
  }

  List<int> getValidMoves() {
    final List<int> moves = [];
    if (activeBoardIndex != -1) {
      final int start = activeBoardIndex * 9;
      for (int i = 0; i < 9; i++) {
        if (board[start + i] == 0) moves.add(start + i);
      }
      if (moves.isNotEmpty) return moves;
    }
    for (int b = 0; b < 9; b++) {
      if (macroBoard[b] == 0) {
        final int start = b * 9;
        for (int i = 0; i < 9; i++) {
          if (board[start + i] == 0) moves.add(start + i);
        }
      }
    }
    return moves;
  }
}
