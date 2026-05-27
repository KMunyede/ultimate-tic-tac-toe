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
  int? forcedBoardIndex; // For Ultimate/Chaos mode

  // [NEW] Power-up Card inventories
  int shieldCardsX;
  int eraserCardsX;
  int hackerCardsX;

  int shieldCardsO;
  int eraserCardsO;
  int hackerCardsO;

  MatchSession({
    required this.boards,
    required this.ruleSet,
    this.currentPlayer = Player.X,
    this.matchWinner,
    this.isMatchDraw = false,
    this.forcedBoardIndex,
    this.outcome = MatchOutcome.active,
    this.shieldCardsX = 1,
    this.eraserCardsX = 1,
    this.hackerCardsX = 1,
    this.shieldCardsO = 1,
    this.eraserCardsO = 1,
    this.hackerCardsO = 1,
  });

  bool get isGameOver => outcome != MatchOutcome.active;

  /// Count of boards won by each player within this match session
  int get boardsWonX => boards.where((b) => b.winner == Player.X).length;

  int get boardsWonO => boards.where((b) => b.winner == Player.O).length;

  /// Attempts to apply a standard move to the session.
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

    // Shield check: Standard moves cannot overwrite shielded cells (though standard moves only target empty cells, this is safe)
    if (boards[boardIndex].shields[cellIndex]) {
      return false;
    }

    // Ultimate/Chaos mode forcing mechanic check
    if ((ruleSet == GameRuleSet.ultimate || ruleSet == GameRuleSet.chaos) && forcedBoardIndex != null) {
      if (boardIndex != forcedBoardIndex) {
        return false;
      }
    }

    // Apply move
    boards[boardIndex].cells[cellIndex] = currentPlayer;

    // Check board status
    boards[boardIndex].checkWinner(currentPlayer);
    boards[boardIndex].checkForDraw();

    // Determine next forced board for Ultimate/Chaos mode
    if (ruleSet == GameRuleSet.ultimate || ruleSet == GameRuleSet.chaos) {
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

  /// [NEW] Attempts to apply a power-up move to the session.
  /// Returns true if the move was valid and applied.
  bool applyPowerUp(int boardIndex, int cellIndex, PowerUpType type) {
    if (isGameOver ||
        boardIndex < 0 ||
        boardIndex >= boards.length ||
        cellIndex < 0 ||
        cellIndex >= 9 ||
        boards[boardIndex].isGameOver) {
      return false;
    }

    // Ultimate/Chaos mode forcing mechanic check
    if ((ruleSet == GameRuleSet.ultimate || ruleSet == GameRuleSet.chaos) && forcedBoardIndex != null) {
      if (boardIndex != forcedBoardIndex) {
        return false;
      }
    }

    final targetCell = boards[boardIndex].cells[cellIndex];
    final isCellShielded = boards[boardIndex].shields[cellIndex];

    // Validate inventory and apply card logic
    if (currentPlayer == Player.X) {
      if (type == PowerUpType.shield) {
        if (shieldCardsX <= 0 || isCellShielded) return false;
        // Shields can only be cast on empty cells or player's own marks
        if (targetCell != Player.none && targetCell != Player.X) return false;
        boards[boardIndex].shields[cellIndex] = true;
        shieldCardsX--;
      } else if (type == PowerUpType.eraser) {
        if (eraserCardsX <= 0 || isCellShielded || targetCell == Player.none) return false;
        boards[boardIndex].cells[cellIndex] = Player.none;
        eraserCardsX--;
      } else if (type == PowerUpType.hacker) {
        if (hackerCardsX <= 0 || isCellShielded || targetCell != Player.O) return false;
        boards[boardIndex].cells[cellIndex] = Player.X;
        hackerCardsX--;
      }
    } else {
      // Player O
      if (type == PowerUpType.shield) {
        if (shieldCardsO <= 0 || isCellShielded) return false;
        if (targetCell != Player.none && targetCell != Player.O) return false;
        boards[boardIndex].shields[cellIndex] = true;
        shieldCardsO--;
      } else if (type == PowerUpType.eraser) {
        if (eraserCardsO <= 0 || isCellShielded || targetCell == Player.none) return false;
        boards[boardIndex].cells[cellIndex] = Player.none;
        eraserCardsO--;
      } else if (type == PowerUpType.hacker) {
        if (hackerCardsO <= 0 || isCellShielded || targetCell != Player.X) return false;
        boards[boardIndex].cells[cellIndex] = Player.O;
        hackerCardsO--;
      }
    }

    // Re-check sub-board outcome state (Hacker or Eraser could trigger/affect outcomes)
    boards[boardIndex].checkWinner(currentPlayer);
    boards[boardIndex].checkForDraw();

    // Determine next forced board for Ultimate/Chaos mode
    if (ruleSet == GameRuleSet.ultimate || ruleSet == GameRuleSet.chaos) {
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
    'shieldCardsX': shieldCardsX,
    'eraserCardsX': eraserCardsX,
    'hackerCardsX': hackerCardsX,
    'shieldCardsO': shieldCardsO,
    'eraserCardsO': eraserCardsO,
    'hackerCardsO': hackerCardsO,
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
      shieldCardsX: json['shieldCardsX'] as int? ?? 1,
      eraserCardsX: json['eraserCardsX'] as int? ?? 1,
      hackerCardsX: json['hackerCardsX'] as int? ?? 1,
      shieldCardsO: json['shieldCardsO'] as int? ?? 1,
      eraserCardsO: json['eraserCardsO'] as int? ?? 1,
      hackerCardsO: json['hackerCardsO'] as int? ?? 1,
    );
  }
}

