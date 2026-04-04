enum GameRuleSet {
  standard,
  majorityWins,
  ultimate;

  String get displayName {
    switch (this) {
      case GameRuleSet.standard:
        return 'Standard';
      case GameRuleSet.majorityWins:
        return 'Majority Wins';
      case GameRuleSet.ultimate:
        return 'Ultimate';
    }
  }
}

enum GameMode {
  playerVsPlayer,
  playerVsAi;

  String get displayName {
    switch (this) {
      case GameMode.playerVsPlayer:
        return 'Player VS Player';
      case GameMode.playerVsAi:
        return 'Player VS AI';
    }
  }
}

enum AiDifficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case AiDifficulty.easy:
        return 'Easy';
      case AiDifficulty.medium:
        return 'Medium';
      case AiDifficulty.hard:
        return 'Hard';
    }
  }
}

enum BoardLayout {
  single,
  dual,
  trio,
  quad, // Added 4-board layout
}
