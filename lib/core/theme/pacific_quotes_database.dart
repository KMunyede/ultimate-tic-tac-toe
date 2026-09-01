// lib/core/theme/pacific_quotes_database.dart
import 'dart:math';
import '../../features/game/logic/game_controller.dart';
import '../../models/player.dart';

class PacificQuotesDatabase {
  static final Random _random = Random();

  static final List<String> _genericQuotes = [
    "Ride the wave to victory!",
    "The ocean is calm... for now.",
    "Deep sea secrets await your move.",
    "Smooth sailing ahead!",
    "Don't get caught in the riptide.",
    "The tide is turning in your favor.",
    "A sea of possibilities opens up.",
    "Make a splash with that move!",
    "Steady as she goes, Captain.",
    "Lost at sea? Follow the stars.",
  ];

  static final List<String> _winningQuotes = [
    "You're the master of the Seven Seas!",
    "A tidal wave of success!",
    "Sunken treasure found!",
    "Ruling the waves like a legend.",
  ];

  static final List<String> _losingQuotes = [
    "Walking the plank, are we?",
    "Man overboard! Stay focused.",
    "Sinking fast... need a lifeboat?",
    "Rough seas today, matey.",
  ];

  static final List<String> _thinkingQuotes = [
    "Calculating the currents...",
    "Diving deep for the best move.",
    "Sonar sweep in progress...",
    "Consulting the Ancient Whale.",
  ];

  static String analyzeStateAndGetQuote(GameController game) {
    if (game.isAiThinking) {
      return _thinkingQuotes[_random.nextInt(_thinkingQuotes.length)];
    }

    if (game.isOverallGameOver) {
      if (game.matchWinner == Player.X) {
        return _winningQuotes[_random.nextInt(_winningQuotes.length)];
      } else if (game.matchWinner == Player.O) {
        return _losingQuotes[_random.nextInt(_losingQuotes.length)];
      }
    }

    return _genericQuotes[_random.nextInt(_genericQuotes.length)];
  }
}
