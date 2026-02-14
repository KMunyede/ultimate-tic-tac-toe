enum BoardResult { playerX, playerO, draw, active }

abstract class MatchRules {
  int getRequiredWins(int boardCount);
  BoardResult checkWinner(List<BoardResult> results, int requiredWins);
}

class MajorityMatchRules implements MatchRules {
  @override
  int getRequiredWins(int boardCount) {
    if (boardCount <= 1) return 1;
    return (boardCount / 2).floor() + 1;
  }

  @override
  BoardResult checkWinner(List<BoardResult> results, int requiredWins) {
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

class MatchReferee {
  // Strategy Pattern for Match Rules
  static final MatchRules _rules = MajorityMatchRules();

  static int getRequiredWins(int boardCount) {
    return _rules.getRequiredWins(boardCount);
  }

  static BoardResult checkMatchWinner(List<BoardResult> boardResults) {
    if (boardResults.isEmpty) return BoardResult.active;
    if (boardResults.length == 1) return boardResults.first;

    final requiredWins = _rules.getRequiredWins(boardResults.length);
    return _rules.checkWinner(boardResults, requiredWins);
  }
}
