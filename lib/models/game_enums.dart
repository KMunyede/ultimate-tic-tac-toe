enum GameRuleSet {
  standard,
  majorityWins,
  ultimate,
  chaos;

  String get displayName {
    switch (this) {
      case GameRuleSet.standard:
        return 'Standard';
      case GameRuleSet.majorityWins:
        return 'Majority Wins';
      case GameRuleSet.ultimate:
        return 'Ultimate';
      case GameRuleSet.chaos:
        return 'Chaos Mode';
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

enum PowerUpType {
  shield,
  eraser,
  hacker;

  String get displayName {
    switch (this) {
      case PowerUpType.shield:
        return 'Shield';
      case PowerUpType.eraser:
        return 'Eraser';
      case PowerUpType.hacker:
        return 'Hacker';
    }
  }
}
