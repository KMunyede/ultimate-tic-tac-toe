import 'player.dart';

// Represents a single Tic-Tac-Toe board
class GameBoard {
  List<Player> cells;
  Player? winner;
  List<int>? winningLine;
  bool isDraw;

  GameBoard()
      : cells = List.filled(9, Player.none),
        winner = null,
        winningLine = null,
        isDraw = false;

  bool get isGameOver => winner != null || isDraw;

  void reset() {
    cells = List.filled(9, Player.none);
    winner = null;
    winningLine = null;
    isDraw = false;
  }

  bool checkWinner(Player player) {
    const List<List<int>> winningCombos = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (final line in winningCombos) {
      if (cells[line[0]] == player &&
          cells[line[1]] == player &&
          cells[line[2]] == player) {
        winningLine = line;
        winner = player;
        return true;
      }
    }
    return false;
  }
  
  bool checkForDraw() {
    if (winner == null && !cells.contains(Player.none)) {
      isDraw = true;
      return true;
    }
    return false;
  }
}
