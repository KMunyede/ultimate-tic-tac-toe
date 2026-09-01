// lib/features/game/logic/end_game_hooks.dart

import '../../../models/player.dart';

class EndGameHook {
  final String title;
  final String description;
  const EndGameHook(this.title, this.description);
}

class EndGameHooks {
  static const List<EndGameHook> xWinHooks = [
    EndGameHook("🏆 YOU ARE THE BEST!", "Superb moves! You completely dominated the grid."),
    EndGameHook("🔥 FLAWLESS VICTORY!", "Nobody saw that coming. You outplayed them!"),
    EndGameHook("🌟 ABSOLUTE LEGEND!", "A masterclass in Tic-Tac-Toe strategy. Outstanding win!"),
    EndGameHook("🚀 UNSTOPPABLE!", "They didn't stand a chance. You absolutely crushed it!"),
  ];

  static const List<EndGameHook> oWinHooks = [
    EndGameHook("🤖 Ouch... YOU LOST!", "The AI pulled a fast one on you. Get back in there!"),
    EndGameHook("🔋 SO CLOSE!", "You almost had it, but the AI snatched the victory."),
    EndGameHook("👾 OUTSMARTED!", "The computer was one step ahead this time. Rematch?"),
    EndGameHook("💡 NOT THIS TIME!", "A valiant effort, but the AI takes the crown today."),
  ];

  static const List<EndGameHook> drawHooks = [
    EndGameHook("🤝 IT'S A TIE!", "A total gridlock! You both fought to a standstill."),
    EndGameHook("⚖️ NO WINNERS HERE!", "Nobody could break the defense. A perfectly even match!"),
    EndGameHook("🛡️ STALEMATE!", "You both played brilliantly, but the board ran out of space."),
  ];

  static EndGameHook getHook(Player? winner, bool isDraw, int matchId) {
    if (winner == Player.X) {
      return xWinHooks[matchId % xWinHooks.length];
    } else if (winner == Player.O) {
      return oWinHooks[matchId % oWinHooks.length];
    } else {
      return drawHooks[matchId % drawHooks.length];
    }
  }
}
