import 'dart:isolate';
import '../models/game_board.dart';
import '../models/game_enums.dart';
import '../models/player.dart';
import '../logic/ultimate_engine.dart';
import 'firebase_service.dart';

class AiMove {
  final int boardIndex;
  final int cellIndex;
  int score;

  AiMove(this.boardIndex, this.cellIndex, [this.score = 0]);
}

class AiService {
  final FirebaseService _firebaseService;

  AiService(this._firebaseService);

  /// Gets the best move, trying Cloud AI first if requested, with a local fallback.
  Future<AiMove?> getBestMove({
    required List<GameBoard> boards,
    required Player aiPlayer,
    required AiDifficulty difficulty,
    required int boardCount,
    required GameRuleSet ruleSet,
    required bool useOnlineAi,
    int? forcedBoardIndex,
  }) async {
    if (useOnlineAi) {
      try {
        final response = await _firebaseService.getAiMove(
          boards: boards,
          player: aiPlayer,
          difficulty: difficulty,
          ruleSet: ruleSet,
          boardCount: boardCount,
          forcedBoardIndex: forcedBoardIndex,
        );

        if (response != null) {
          int boardIdx = response.boardIndex ?? (forcedBoardIndex ?? -1);
          // Validate cloud move
          if (boardIdx != -1 && 
              boardIdx < boards.length && 
              !boards[boardIdx].isGameOver &&
              boards[boardIdx].cells[response.cellIndex] == Player.none) {
            return AiMove(boardIdx, response.cellIndex);
          }
        }
      } catch (e) {
        // Fall through to local AI
      }
    }

    // Local AI Fallback (Runs in Isolate to prevent UI jank)
    return await Isolate.run(() {
      if (ruleSet == GameRuleSet.ultimate && boards.length == 9) {
        final engine = UltimateEngine.fromState(boards, forcedBoardIndex);
        final int aiVal = aiPlayer == Player.X ? 1 : -1;
        
        // Hard: Depth 6, Medium: Depth 4, Easy: Depth 2
        int depth = 2;
        if (difficulty == AiDifficulty.hard) depth = 6;
        if (difficulty == AiDifficulty.medium) depth = 4;

        final result = engine.minimax(depth, -2000000, 2000000, aiVal, aiVal);
        if (result[1] != -1) {
          return AiMove(result[1] ~/ 9, result[1] % 9, result[0]);
        }
      }
      
      // Basic heuristic fallback if engine fails or for simple modes
      return _computeHeuristicMove(boards, aiPlayer, forcedBoardIndex, difficulty);
    });
  }

  AiMove? _computeHeuristicMove(List<GameBoard> boards, Player player, int? forcedIdx, AiDifficulty difficulty) {
    List<AiMove> moves = [];
    if (forcedIdx != null && !boards[forcedIdx].isGameOver) {
      for (int i = 0; i < 9; i++) {
        if (boards[forcedIdx].cells[i] == Player.none) moves.add(AiMove(forcedIdx, i));
      }
    }
    if (moves.isEmpty) {
      for (int b = 0; b < boards.length; b++) {
        if (!boards[b].isGameOver) {
          for (int c = 0; c < 9; c++) {
            if (boards[b].cells[c] == Player.none) moves.add(AiMove(b, c));
          }
        }
      }
    }
    if (moves.isEmpty) return null;
    
    // For simplicity in this helper, just return random for Easy/Medium fallback
    moves.shuffle();
    return moves.first;
  }
}
