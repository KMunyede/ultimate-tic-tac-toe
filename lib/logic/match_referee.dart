enum BoardResult { playerX, playerO, draw, active }

class MatchReferee {
  /// Determines the match winner based on the state of all boards.
  static BoardResult checkMatchWinner(List<BoardResult> boardResults) {
    int boardCount = boardResults.length;

    // SCENARIO 1: ONE BOARD
    if (boardCount == 1) {
      return boardResults.first;
    }

    // SCENARIO 2: TWO BOARDS (Points System)
    // Win = 1.0, Draw = 0.5, Loss = 0.0
    if (boardCount == 2) {
      double scoreX = _calculatePoints(boardResults, BoardResult.playerX);
      double scoreO = _calculatePoints(boardResults, BoardResult.playerO);

      if (scoreX > scoreO) return BoardResult.playerX;
      if (scoreO > scoreX) return BoardResult.playerO;

      // If scores are equal (e.g., 1 win each, or 2 draws), it's a draw ONLY if both boards are finished.
      if (boardResults.every((b) => b != BoardResult.active)) {
        return BoardResult.draw;
      }
      return BoardResult.active;
    }

    // SCENARIO 3: THREE BOARDS (Majority Rule)
    if (boardCount == 3) {
      int winsX = boardResults.where((r) => r == BoardResult.playerX).length;
      int winsO = boardResults.where((r) => r == BoardResult.playerO).length;

      // Instant Win Condition: 2 wins secures the match
      if (winsX >= 2) return BoardResult.playerX;
      if (winsO >= 2) return BoardResult.playerO;

      // If all boards are finished, check who has the most wins
      bool allFinished = boardResults.every((b) => b != BoardResult.active);
      if (allFinished) {
        if (winsX > winsO) return BoardResult.playerX;
        if (winsO > winsX) return BoardResult.playerO;
        return BoardResult.draw;
      }
    }

    return BoardResult.active;
  }

  static double _calculatePoints(
      List<BoardResult> results, BoardResult player) {
    double points = 0;
    for (var result in results) {
      if (result == player) {
        points += 1.0;
      } else if (result == BoardResult.draw) {
        points += 0.5;
      }
    }
    return points;
  }
}
