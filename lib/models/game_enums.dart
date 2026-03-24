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

enum AiDifficulty { easy, medium, hard }

enum BoardLayout {
  single,
  dual,
  trio,
  quad, // Added 4-board layout
}
