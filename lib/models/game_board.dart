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
}
