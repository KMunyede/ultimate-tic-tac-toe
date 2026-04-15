import '../models/game_enums.dart';

enum BoardResult { playerX, playerO, draw, active }

abstract class MatchRules {
  BoardResult checkWinner(List<BoardResult> results);
}

class StandardMatchRules implements MatchRules {
  @override
  BoardResult checkWinner(List<BoardResult> results) {
    if (results.isEmpty) return BoardResult.active;

    // 1 Board: Original logic (return the only result)
    if (results.length == 1) return results.first;

    // 2 Boards: Win condition = player wins BOTH boards
    if (results.length == 2) {
      final winsX = results.where((r) => r == BoardResult.playerX).length;
      final winsO = results.where((r) => r == BoardResult.playerO).length;
      final activeBoards = results.where((b) => b == BoardResult.active).length;

      if (winsX == 2) return BoardResult.playerX;
      if (winsO == 2) return BoardResult.playerO;

      // If no one can win both anymore (due to draws or opponent wins)
      // and no active boards remain, it's a draw.
      if (activeBoards == 0) {
        return BoardResult.draw;
      }
      
      // If one board is won by X and the other by O, it's a draw immediately
      if (winsX == 1 && winsO == 1) {
        return BoardResult.draw;
      }
      
      // If one board is a draw, then NO ONE can win both.
      if (results.any((r) => r == BoardResult.draw)) {
         return BoardResult.draw;
      }

      return BoardResult.active;
    }

    return results.first;
  }
}

class MajorityMatchRules implements MatchRules {
  @override
  BoardResult checkWinner(List<BoardResult> results) {
    final boardCount = results.length;

    // Special Case: 2 Boards (Follows Standard Rule Set: Win BOTH to win match)
    if (boardCount == 2) {
      final winsX = results.where((r) => r == BoardResult.playerX).length;
      final winsO = results.where((r) => r == BoardResult.playerO).length;
      final activeBoards = results.where((b) => b == BoardResult.active).length;

      if (winsX == 2) return BoardResult.playerX;
      if (winsO == 2) return BoardResult.playerO;

      if (activeBoards == 0) return BoardResult.draw;
      if (winsX == 1 && winsO == 1) return BoardResult.draw;
      if (results.any((r) => r == BoardResult.draw)) return BoardResult.draw;
      
      return BoardResult.active;
    }

    // Standard Majority Logic (for 1, 3-9 boards)
    final requiredWins = (boardCount / 2).floor() + 1;
    
    final winsX = results.where((r) => r == BoardResult.playerX).length;
    final winsO = results.where((r) => r == BoardResult.playerO).length;
    final activeBoards = results.where((b) => b == BoardResult.active).length;

    // 1. Majority Win (reached the threshold)
    if (winsX >= requiredWins) return BoardResult.playerX;
    if (winsO >= requiredWins) return BoardResult.playerO;

    // 2. Mathematical Elimination
    bool xCanReachThreshold = (winsX + activeBoards) >= requiredWins;
    bool oCanReachThreshold = (winsO + activeBoards) >= requiredWins;

    if (activeBoards > 0) {
      if (!xCanReachThreshold && !oCanReachThreshold) {
        // No one can reach majority anymore
        return BoardResult.draw;
      }
      return BoardResult.active;
    }

    // 3. Final Result (All boards finished, no one hit majority threshold)
    return BoardResult.draw;
  }
}

class UltimateMatchRules implements MatchRules {
  @override
  BoardResult checkWinner(List<BoardResult> results) {
    if (results.length != 9) return BoardResult.active;

    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Columns
      [0, 4, 8], [2, 4, 6],           // Diagonals
    ];

    for (var pattern in winPatterns) {
      final a = results[pattern[0]];
      final b = results[pattern[1]];
      final c = results[pattern[2]];

      if (a != BoardResult.active && a != BoardResult.draw && a == b && a == c) {
        return a;
      }
    }

    if (!results.any((r) => r == BoardResult.active)) {
      return BoardResult.draw;
    }

    return BoardResult.active;
  }
}

class MatchReferee {
  static BoardResult checkMatchWinner(List<BoardResult> boardResults, GameRuleSet ruleSet) {
    if (boardResults.isEmpty) return BoardResult.active;

    MatchRules rules;
    switch (ruleSet) {
      case GameRuleSet.standard:
        rules = StandardMatchRules();
        break;
      case GameRuleSet.majorityWins:
        rules = MajorityMatchRules();
        break;
      case GameRuleSet.ultimate:
        rules = UltimateMatchRules();
        break;
    }

    return rules.checkWinner(boardResults);
  }
}
