import '../models/game_enums.dart';

enum BoardResult { playerX, playerO, draw, active }

enum MatchOutcome { winX, winO, draw, noWinner, active }

abstract class MatchRules {
  MatchOutcome checkMatchOutcome(List<BoardResult> results);
}

class StandardMatchRules implements MatchRules {
  @override
  MatchOutcome checkMatchOutcome(List<BoardResult> results) {
    if (results.isEmpty) return MatchOutcome.active;

    final count = results.length;
    final winsX = results.where((r) => r == BoardResult.playerX).length;
    final winsO = results.where((r) => r == BoardResult.playerO).length;
    final activeBoards = results.where((b) => b == BoardResult.active).length;

    // 1 Board: Classic logic
    if (count == 1) {
      if (results.first == BoardResult.playerX) return MatchOutcome.winX;
      if (results.first == BoardResult.playerO) return MatchOutcome.winO;
      if (results.first == BoardResult.draw) return MatchOutcome.draw;
      return MatchOutcome.active;
    }

    // 2 Boards: Win condition = BOTH boards
    if (count == 2) {
      if (winsX == 2) return MatchOutcome.winX;
      if (winsO == 2) return MatchOutcome.winO;
      if (activeBoards > 0) return MatchOutcome.active;
      
      // Draw: 1st Player wins 1 board && opponent wins 2nd board equally (1-1)
      if (winsX == 1 && winsO == 1) return MatchOutcome.draw;
      
      // No Winner: 1st Player wins 1 board only && fails to win the second (1-0)
      return MatchOutcome.noWinner;
    }

    return MatchOutcome.active;
  }
}

class MajorityMatchRules implements MatchRules {
  @override
  MatchOutcome checkMatchOutcome(List<BoardResult> results) {
    final count = results.length;
    final winsX = results.where((r) => r == BoardResult.playerX).length;
    final winsO = results.where((r) => r == BoardResult.playerO).length;
    final activeBoards = results.where((b) => b == BoardResult.active).length;

    // Custom Win Thresholds
    int requiredWins;
    switch (count) {
      case 2: requiredWins = 2; break;
      case 3: requiredWins = 2; break;
      case 4: requiredWins = 3; break;
      case 5: requiredWins = 4; break;
      case 6: requiredWins = 4; break;
      case 7: requiredWins = 5; break;
      case 8: requiredWins = 5; break;
      case 9: requiredWins = 5; break;
      default: requiredWins = (count / 2).floor() + 1;
    }

    // 1. Check for Absolute Win
    if (winsX >= requiredWins) return MatchOutcome.winX;
    if (winsO >= requiredWins) return MatchOutcome.winO;

    // 2. Continue until all moves exhausted
    if (activeBoards > 0) return MatchOutcome.active;

    // 3. Mathematical Parity check at end of game
    // A "Draw" requires perfect balance in board victories.
    if (winsX > 0 && winsX == winsO) {
      return MatchOutcome.draw;
    }

    // A "No Winner" is any other non-winning terminal state (stalemate or asymmetric tie)
    return MatchOutcome.noWinner;
  }
}

class UltimateMatchRules implements MatchRules {
  @override
  MatchOutcome checkMatchOutcome(List<BoardResult> results) {
    if (results.length != 9) return MatchOutcome.active;

    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    for (var pattern in winPatterns) {
      final a = results[pattern[0]];
      final b = results[pattern[1]];
      final c = results[pattern[2]];

      if (a != BoardResult.active && a != BoardResult.draw && a == b && a == c) {
        return a == BoardResult.playerX ? MatchOutcome.winX : MatchOutcome.winO;
      }
    }

    if (!results.any((r) => r == BoardResult.active)) {
      // If macro-board is full and no one has 3-in-a-row, check for parity
      final winsX = results.where((r) => r == BoardResult.playerX).length;
      final winsO = results.where((r) => r == BoardResult.playerO).length;
      
      if (winsX == winsO && winsX > 0) return MatchOutcome.draw;
      return MatchOutcome.noWinner;
    }

    return MatchOutcome.active;
  }
}

class MatchReferee {
  static MatchOutcome checkMatchOutcome(List<BoardResult> boardResults, GameRuleSet ruleSet) {
    if (boardResults.isEmpty) return MatchOutcome.active;

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

    return rules.checkMatchOutcome(boardResults);
  }
}
