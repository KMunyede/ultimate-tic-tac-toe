enum BoardResult { playerX, playerO, draw, active }

class MatchReferee {
  /// Determines how many board wins are needed for an instant match victory.
  static int getRequiredWins(int boardCount) {
    if (boardCount <= 1) return 1;
    switch (boardCount) {
      case 2:
        return 2; 
      case 3:
        return 2; // Must win at least 2 boards (2 or 3 wins = WIN)
      case 4:
        return 3; // Must win at least 3 boards (3 or 4 wins = WIN)
      default:
        return (boardCount / 2).floor() + 1;
    }
  }

  /// Determines the match winner based on the state of all boards.
  static BoardResult checkMatchWinner(List<BoardResult> boardResults) {
    final boardCount = boardResults.length;
    if (boardCount == 0) return BoardResult.active;
    if (boardCount == 1) return boardResults.first;

    final requiredWins = getRequiredWins(boardCount);

    final winsX = boardResults.where((r) => r == BoardResult.playerX).length;
    final winsO = boardResults.where((r) => r == BoardResult.playerO).length;
    final activeBoards = boardResults.where((b) => b == BoardResult.active).length;

    // 1. Instant Win: If someone reaches the required number of wins, they win the match.
    if (winsX >= requiredWins) return BoardResult.playerX;
    if (winsO >= requiredWins) return BoardResult.playerO;

    // 2. Early Draw Detection (Multi-board Strategy):
    // If no moves are possible on other boards, OR if it is impossible for either 
    // player to reach the required win threshold with the remaining boards.
    bool xCanStillWin = (winsX + activeBoards) >= requiredWins;
    bool oCanStillWin = (winsO + activeBoards) >= requiredWins;

    if (!xCanStillWin && !oCanStillWin) {
      // If no one can reach the threshold, the match is a DRAW.
      return BoardResult.draw;
    }

    // 3. Continue playing as long as there are active boards and someone can still win.
    if (activeBoards > 0) {
      return BoardResult.active;
    }

    // 4. Final Conclusion: All boards are finished and no one hit the threshold.
    return BoardResult.draw;
  }
}
