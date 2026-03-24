import 'game_board.dart';
import 'player.dart';
import '../logic/match_referee.dart';

class MatchSession {
  final List<GameBoard> boards;
  Player currentPlayer;
  Player? matchWinner;
  bool isMatchDraw;

  MatchSession({
    required this.boards,
    this.currentPlayer = Player.X,
    this.matchWinner,
    this.isMatchDraw = false,
  });

  bool get isGameOver => matchWinner != null || isMatchDraw;

  /// [NEW] Count of boards won by each player within this match session
  int get boardsWonX => boards.where((b) => b.winner == Player.X).length;

  int get boardsWonO => boards.where((b) => b.winner == Player.O).length;

  /// Attempts to apply a move to the session.
  /// Returns true if the move was valid and applied.
  bool applyMove(int boardIndex, int cellIndex) {
    if (isGameOver ||
        boardIndex < 0 ||
        boardIndex >= boards.length ||
        cellIndex < 0 ||
        cellIndex >= 9 ||
        boards[boardIndex].cells[cellIndex] != Player.none ||
        boards[boardIndex].isGameOver) {
      return false;
    }

    // Apply move
    boards[boardIndex].cells[cellIndex] = currentPlayer;

    // Check board status
    boards[boardIndex].checkWinner(currentPlayer);
    boards[boardIndex].checkForDraw();

    // Check match status
    _updateMatchStatus();

    if (!isGameOver) {
      _switchPlayer();
    }

    return true;
  }

  void _switchPlayer() {
    currentPlayer = (currentPlayer == Player.X) ? Player.O : Player.X;
  }

  void _updateMatchStatus() {
    List<BoardResult> results = boards.map((b) {
      if (b.winner == Player.X) return BoardResult.playerX;
      if (b.winner == Player.O) return BoardResult.playerO;
      if (b.isDraw) return BoardResult.draw;
      return BoardResult.active;
    }).toList();

    BoardResult matchResult = MatchReferee.checkMatchWinner(results);

    if (matchResult == BoardResult.playerX) {
      matchWinner = Player.X;
    } else if (matchResult == BoardResult.playerO) {
      matchWinner = Player.O;
    } else if (matchResult == BoardResult.draw) {
      isMatchDraw = true;
    }
  }

  Map<String, dynamic> toJson() => {
    'boards': boards.map((b) => b.toJson()).toList(),
    'currentPlayer': currentPlayer.name,
    'matchWinner': matchWinner?.name,
    'isMatchDraw': isMatchDraw,
  };

  factory MatchSession.fromJson(Map<String, dynamic> json) {
    return MatchSession(
      boards: (json['boards'] as List)
          .map((b) => GameBoard.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList(),
      currentPlayer: Player.values.byName(json['currentPlayer'] as String),
      matchWinner: json['matchWinner'] != null
          ? Player.values.byName(json['matchWinner'] as String)
          : null,
      isMatchDraw: json['isMatchDraw'] as bool? ?? false,
    );
  }
}
