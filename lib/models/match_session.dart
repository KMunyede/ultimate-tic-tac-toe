import 'game_board.dart';
import 'player.dart';
import '../logic/match_referee.dart';
import 'game_enums.dart';

class MatchSession {
  final List<GameBoard> boards;
  final GameRuleSet ruleSet;
  Player currentPlayer;
  Player? matchWinner;
  MatchOutcome outcome = MatchOutcome.active;
  bool isMatchDraw;
  int? forcedBoardIndex; // [NEW] For Ultimate mode

  MatchSession({
    required this.boards,
    required this.ruleSet,
    this.currentPlayer = Player.X,
    this.matchWinner,
    this.isMatchDraw = false,
    this.forcedBoardIndex,
    this.outcome = MatchOutcome.active,
  });

  bool get isGameOver => outcome != MatchOutcome.active;

  /// [NEW] Count of boards won by each player within this match session
  int get boardsWonX => boards.where((b) => b.winner == Player.X).length;

  int get boardsWonO => boards.where((b) => b.winner == Player.O).length;

  /// Attempts to apply a move to the session.
  /// Returns true if the move was valid and applied.
  bool applyMove(int boardIndex, int cellIndex) {
    // Basic validation
    if (isGameOver ||
        boardIndex < 0 ||
        boardIndex >= boards.length ||
        cellIndex < 0 ||
        cellIndex >= 9 ||
        boards[boardIndex].cells[cellIndex] != Player.none ||
        boards[boardIndex].isGameOver) {
      return false;
    }

    // [NEW] Ultimate mode forcing mechanic check
    if (ruleSet == GameRuleSet.ultimate && forcedBoardIndex != null) {
      if (boardIndex != forcedBoardIndex) {
        return false;
      }
    }

    // Apply move
    boards[boardIndex].cells[cellIndex] = currentPlayer;

    // Check board status
    boards[boardIndex].checkWinner(currentPlayer);
    boards[boardIndex].checkForDraw();

    // [NEW] Determine next forced board for Ultimate mode
    if (ruleSet == GameRuleSet.ultimate) {
      int nextBoardIndex = cellIndex;
      if (boards[nextBoardIndex].isGameOver) {
        forcedBoardIndex = null; // Free move
      } else {
        forcedBoardIndex = nextBoardIndex;
      }
    }

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

    outcome = MatchReferee.checkMatchOutcome(results, ruleSet);

    if (outcome == MatchOutcome.winX) {
      matchWinner = Player.X;
    } else if (outcome == MatchOutcome.winO) {
      matchWinner = Player.O;
    } else if (outcome == MatchOutcome.draw) {
      isMatchDraw = true;
    } else if (outcome == MatchOutcome.noWinner) {
      // In a "No Winner" scenario, we set isMatchDraw to true 
      // so the GameController knows the match is technically over 
      // but without a winner.
      isMatchDraw = true;
    }
  }

  Map<String, dynamic> toJson() => {
    'boards': boards.map((b) => b.toJson()).toList(),
    'ruleSet': ruleSet.name,
    'currentPlayer': currentPlayer.name,
    'matchWinner': matchWinner?.name,
    'isMatchDraw': isMatchDraw,
    'forcedBoardIndex': forcedBoardIndex,
    'outcome': outcome.name,
  };

  factory MatchSession.fromJson(Map<String, dynamic> json) {
    return MatchSession(
      boards: (json['boards'] as List)
          .map((b) => GameBoard.fromJson(Map<String, dynamic>.from(b as Map)))
          .toList(),
      ruleSet: GameRuleSet.values.byName(json['ruleSet'] as String? ?? 'majorityWins'),
      currentPlayer: Player.values.byName(json['currentPlayer'] as String),
      matchWinner: json['matchWinner'] != null
          ? Player.values.byName(json['matchWinner'] as String)
          : null,
      isMatchDraw: json['isMatchDraw'] as bool? ?? false,
      forcedBoardIndex: json['forcedBoardIndex'] as int?,
      outcome: MatchOutcome.values.byName(json['outcome'] as String? ?? 'active'),
    );
  }
}
