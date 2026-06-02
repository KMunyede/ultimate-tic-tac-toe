// lib/features/game/logic/end_game_hooks.dart

import '../../../models/player.dart';

class EndGameHook {
  final String title;
  final String description;
  const EndGameHook(this.title, this.description);
}

class EndGameHooks {
  static const List<EndGameHook> xWinHooks = [
    EndGameHook("🏆 YOU WON THE GAME!", "Superb moves! You played perfectly and claimed the victory."),
    EndGameHook("🎉 AMAZING VICTORY!", "Fantastic game! You found the winning spots and won the match."),
    EndGameHook("🌟 BRILLIANT PLAY!", "You played wonderfully and took over the board. Excellent job!"),
    EndGameHook("🎯 YOU CRACKED THE GRID!", "Every single move was spot on. What a spectacular win!"),
  ];

  static const List<EndGameHook> oWinHooks = [
    EndGameHook("🤖 THE COMPUTER WON THIS ROUND", "The computer made some clever moves. Let's try again!"),
    EndGameHook("🔋 NICE TRY!", "That was a tough match! Reset the board and see if you can win next time."),
    EndGameHook("👾 THE COMPUTER SCORED", "The AI got the winning line first. Challenge it to another game!"),
    EndGameHook("💡 GOOD GAME!", "You played well, but the computer was just one step ahead. Try again!"),
  ];

  static const List<EndGameHook> drawHooks = [
    EndGameHook("🤝 IT'S A TIE!", "An exceptionally even game! Both players matched each other move for move."),
    EndGameHook("⚡ EVEN MATCH!", "No one gave up an inch! A perfectly balanced game from start to finish."),
    EndGameHook("🌈 GREAT GAME TO BOTH!", "You both played brilliantly and finished in a perfect draw. Ready for a tiebreaker?"),
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
