import '../models/game_enums.dart';

enum BoardResult { playerX, playerO, draw, active }

abstract class MatchRules {
  BoardResult checkWinner(List<BoardResult> results);
}

class StandardMatchRules implements MatchRules {
  @override
  BoardResult checkWinner(List<BoardResult> results) {
    // Only 1 board, so just return its result
    if (results.isEmpty) return BoardResult.active;
    return results.first;
  }
}

class MajorityMatchRules implements MatchRules {
  @override
  BoardResult checkWinner(List<BoardResult> results) {
    final boardCount = results.length;
    final requiredWins = (boardCount / 2).floor() + 1;
    
    final winsX = results.where((r) => r == BoardResult.playerX).length;
    final winsO = results.where((r) => r == BoardResult.playerO).length;
    final activeBoards = results.where((b) => b == BoardResult.active).length;

    if (winsX >= requiredWins) return BoardResult.playerX;
    if (winsO >= requiredWins) return BoardResult.playerO;

    bool xCanStillWin = (winsX + activeBoards) >= requiredWins;
    bool oCanStillWin = (winsO + activeBoards) >= requiredWins;

    if (!xCanStillWin && !oCanStillWin) return BoardResult.draw;
    if (activeBoards > 0) return BoardResult.active;

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
