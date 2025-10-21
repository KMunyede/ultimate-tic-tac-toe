import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/player.dart'; // This is the correct import for the Player enum.

/// Enum to represent the available themes in the application.
enum AppTheme {
  light('Light'),
  dark('Dark'),
  ocean('Ocean Blue'),
  forest('Forest Green');

  const AppTheme(this.name);
  final String name;
}

/// Enum to represent the game mode.
enum GameMode {
  playerVsPlayer('Player vs Player'),
  playerVsAi('Player vs AI');

  const GameMode(this.name);
  final String name;
}

/// Enum to represent AI difficulty.
enum AiDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const AiDifficulty(this.name);
  final String name;
}

class SettingsController with ChangeNotifier {
  late SharedPreferences _prefs;

  // Theme settings
  AppTheme _currentTheme = AppTheme.light;
  AppTheme get currentTheme => _currentTheme;

  ThemeData get themeData {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(onPrimary: Colors.black),
        );
      case AppTheme.dark:
        // A dark theme that is 10% lighter than the default pure black.
        final baseDarkTheme = ThemeData.dark();
        // Making the background color lighter as requested. 0xFF242424 is a lighter gray.
        return baseDarkTheme.copyWith(
          scaffoldBackgroundColor: const Color(0xFF242424), // Lighter dark
          colorScheme: const ColorScheme.dark(
              onPrimary: Colors.white, primary: Colors.tealAccent),
        );
      case AppTheme.ocean:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A2E40),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF0077B6),
            secondary: Color(0xFF00B4D8),
            onPrimary: Colors.white,
          ),
        );
      case AppTheme.forest:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF0F4F0),
          // Define a more complete color scheme for the forest theme
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2d6a4f),
            secondary: Color(0xFF40916c),
            surface: Color(0xFFb7e4c7), // Lighter green for cell background
            onSurface: Colors.black, // Text/icon color on surface
            onPrimary: Colors.black,
          ),
        );
    }
  }

  // Sound settings
  bool _isSoundOn = true;
  bool get isSoundOn => _isSoundOn;

  // Game Mode settings
  GameMode _gameMode = GameMode.playerVsPlayer;
  GameMode get gameMode => _gameMode;

  // AI Difficulty settings
  AiDifficulty _aiDifficulty = AiDifficulty.hard;
  AiDifficulty get aiDifficulty => _aiDifficulty;

  // Score settings
  int _scoreX = 0;
  int _scoreO = 0;
  int get scoreX => _scoreX;
  int get scoreO => _scoreO;

  bool _resetGameRequested = false;
  bool get resetGameRequested => _resetGameRequested;

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    // Load theme, default to light
    final themeName = _prefs.getString('theme') ?? AppTheme.light.name;
    _currentTheme = AppTheme.values.firstWhere(
      (theme) => theme.name == themeName,
      orElse: () => AppTheme.light,
    );

    final gameModeName = _prefs.getString('gameMode') ?? GameMode.playerVsPlayer.name;
    _gameMode = GameMode.values.firstWhere(
      (mode) => mode.name == gameModeName,
      orElse: () => GameMode.playerVsPlayer,
    );

    final aiDifficultyName = _prefs.getString('aiDifficulty') ?? AiDifficulty.hard.name;
    _aiDifficulty = AiDifficulty.values.firstWhere(
      (difficulty) => difficulty.name == aiDifficultyName,
      orElse: () => AiDifficulty.hard,
    );

    _isSoundOn = _prefs.getBool('isSoundOn') ?? true;
    _scoreX = _prefs.getInt('scoreX') ?? 0;
    _scoreO = _prefs.getInt('scoreO') ?? 0;
    notifyListeners();
  }

  Future<void> changeTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _prefs.setString('theme', theme.name);
    notifyListeners();
  }

  Future<void> setGameMode(GameMode mode) async {
    _gameMode = mode;
    await _prefs.setString('gameMode', mode.name);
    notifyListeners();
  }

  Future<void> setAiDifficulty(AiDifficulty difficulty) async {
    _aiDifficulty = difficulty;
    await _prefs.setString('aiDifficulty', difficulty.name);
    notifyListeners();
  }

  void toggleSound() {
    _isSoundOn = !_isSoundOn;
    _prefs.setBool('isSoundOn', _isSoundOn);
    notifyListeners();
  }

  Future<void> updateScore(Player winner) async {
    if (winner == Player.X) {
      _scoreX++;
      await _prefs.setInt('scoreX', _scoreX);
    } else if (winner == Player.O) {
      _scoreO++;
      await _prefs.setInt('scoreO', _scoreO);
    }
    notifyListeners();
  }

  Future<void> resetScores() async {
    _scoreX = 0;
    _scoreO = 0;
    await _prefs.setInt('scoreX', 0);
    await _prefs.setInt('scoreO', 0);
    notifyListeners();
  }

  void resetGameAndScores() {
    resetScores();
    _resetGameRequested = true;
    // We notify listeners so the ProxyProvider in main.dart can see the change.
    notifyListeners();
  }

  void consumeGameResetRequest() {
    _resetGameRequested = false;
  }
}
