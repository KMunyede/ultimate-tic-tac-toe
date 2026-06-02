// lib/core/theme/jungle_quotes_database.dart
import 'dart:math';
import '../../features/game/logic/game_controller.dart';
import '../../models/player.dart';

enum JungleGameState {
  opening,
  winningLead,
  losingDeficit,
  impendingThreat,
  tacticalOpportunity,
  aiThinking,
  postWinLure,
  postLossLure,
  encouragingIdle,
}

class JungleQuotesDatabase {
  // Database of short, sweet 1-2 word game phrases mapped to states
  static const Map<JungleGameState, List<String>> _quotes = {
    JungleGameState.opening: [
      "Welcome!",
      "Let's go!",
      "Strike first",
      "Fresh hunt",
      "Your move",
    ],
    JungleGameState.winningLead: [
      "Outstanding!",
      "Mega moves!",
      "Almost there!",
      "Great!",
      "Brilliant!",
      "Dominating!",
      "Superb!",
    ],
    JungleGameState.losingDeficit: [
      "Almost there",
      "Rise up",
      "Strike back",
      "Stay focused",
      "You got this!",
    ],
    JungleGameState.impendingThreat: [
      "Careful!",
      "Watch out!",
      "Alert!",
      "Block now!",
      "Danger!",
    ],
    JungleGameState.tacticalOpportunity: [
      "Opportunity!",
      "Strike now!",
      "Conquer!",
      "Finish it!",
      "Leap ahead!",
    ],
    JungleGameState.aiThinking: [
      "AI thinking...",
      "AI sweating...",
      "Puzzling...",
      "Calculating...",
    ],
    JungleGameState.postWinLure: [
      "Outstanding!",
      "You won!",
      "Replay?",
      "Play again!",
      "Masterclass!",
    ],
    JungleGameState.postLossLure: [
      "So close!",
      "Rematch?",
      "Try again!",
      "Revenge!",
    ],
    JungleGameState.encouragingIdle: [
      "Breathe...",
      "Take aim",
      "Focus",
      "Stay sharp",
      "Plan ahead",
    ],
  };

  /// Evaluates the current game state and retrieves a sweet, concise phrase.
  static String analyzeStateAndGetQuote(GameController game) {
    final random = Random();

    // 1. Check for Game Over (Win / Loss) Lures
    if (game.isOverallGameOver) {
      final winner = game.matchWinner;
      if (winner == Player.X) {
        final list = _quotes[JungleGameState.postWinLure]!;
        return list[random.nextInt(list.length)];
      } else {
        final list = _quotes[JungleGameState.postLossLure]!;
        return list[random.nextInt(list.length)];
      }
    }

    // 2. Check if Pristine Opening State (No moves played yet)
    final bool isPristine = game.boards.every((b) => b.cells.every((c) => c == Player.none));
    if (isPristine) {
      final list = _quotes[JungleGameState.opening]!;
      return list[random.nextInt(list.length)];
    }

    // 3. Check if AI is currently thinking
    if (game.isAiThinking) {
      final list = _quotes[JungleGameState.aiThinking]!;
      return list[random.nextInt(list.length)];
    }

    // 4. Check for Impending Threats (Player O has 2 in a row on a playable board)
    int? activeBoardIdx = game.forcedBoardIndex;
    if (activeBoardIdx != null && activeBoardIdx >= 0 && activeBoardIdx < 9) {
      if (game.boards[activeBoardIdx].hasThreat(Player.O)) {
        final list = _quotes[JungleGameState.impendingThreat]!;
        return list[random.nextInt(list.length)];
      }
    } else {
      for (int i = 0; i < game.boards.length; i++) {
        if (!game.boards[i].isGameOver && game.boards[i].hasThreat(Player.O)) {
          final list = _quotes[JungleGameState.impendingThreat]!;
          return list[random.nextInt(list.length)];
        }
      }
    }

    // 5. Check for Tactical Opportunities (Player X has 2 in a row on a playable board)
    if (activeBoardIdx != null && activeBoardIdx >= 0 && activeBoardIdx < 9) {
      if (game.boards[activeBoardIdx].hasThreat(Player.X)) {
        final list = _quotes[JungleGameState.tacticalOpportunity]!;
        return list[random.nextInt(list.length)];
      }
    } else {
      for (int i = 0; i < game.boards.length; i++) {
        if (!game.boards[i].isGameOver && game.boards[i].hasThreat(Player.X)) {
          final list = _quotes[JungleGameState.tacticalOpportunity]!;
          return list[random.nextInt(list.length)];
        }
      }
    }

    // 6. Check for Deficit / Lead states
    if (game.boardsWonX > game.boardsWonO) {
      final list = _quotes[JungleGameState.winningLead]!;
      return list[random.nextInt(list.length)];
    } else if (game.boardsWonO > game.boardsWonX) {
      final list = _quotes[JungleGameState.losingDeficit]!;
      return list[random.nextInt(list.length)];
    }

    // 7. Default fallback: idle encouraging thoughts
    final list = _quotes[JungleGameState.encouragingIdle]!;
    return list[random.nextInt(list.length)];
  }
}
