import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictactoe/app_theme.dart';
import 'models/player.dart';

// ARCHITECTURAL ADDITION: Enums for new premium game modes.

/// Enum to represent the game board layout.
enum BoardLayout {
  single('1 Board'),
  double('2 Boards (Premium)'),
  triple('3 Boards (Premium)');

  const BoardLayout(this.name);
  final String name;
}

enum GameMode {
  playerVsPlayer('Player vs Player'),
  playerVsAi('Player vs AI');

  const GameMode(this.name);
  final String name;
}

enum AiDifficulty {
  easy('Easy'),
  medium('Medium'),
  hard('Hard');

  const AiDifficulty(this.name);
  final String name;
}

class SettingsController with ChangeNotifier {
  late SharedPreferences _prefs;

  // --- Existing Settings ---
  AppTheme _currentTheme = appThemes.first;
  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => generateTheme(_currentTheme.mainColor);

  bool _isSoundOn = true;
  bool get isSoundOn => _isSoundOn;

  GameMode _gameMode = GameMode.playerVsPlayer;
  GameMode get gameMode => _gameMode;

  AiDifficulty _aiDifficulty = AiDifficulty.hard;
  AiDifficulty get aiDifficulty => _aiDifficulty;

  int _scoreX = 0;
  int _scoreO = 0;
  int get scoreX => _scoreX;
  int get scoreO => _scoreO;

  bool _resetGameRequested = false;
  bool get resetGameRequested => _resetGameRequested;

  // --- ARCHITECTURAL ADDITION: Premium Features State ---
  BoardLayout _boardLayout = BoardLayout.single;
  BoardLayout get boardLayout => _boardLayout;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  // --- Methods ---

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load existing settings
    final themeName = _prefs.getString('theme') ?? appThemes.first.name;
    _currentTheme = appThemes.firstWhere((t) => t.name == themeName, orElse: () => appThemes.first);

    final gameModeName = _prefs.getString('gameMode') ?? GameMode.playerVsPlayer.name;
    _gameMode = GameMode.values.firstWhere((m) => m.name == gameModeName, orElse: () => GameMode.playerVsPlayer);

    final aiDifficultyName = _prefs.getString('aiDifficulty') ?? AiDifficulty.hard.name;
    _aiDifficulty = AiDifficulty.values.firstWhere((d) => d.name == aiDifficultyName, orElse: () => AiDifficulty.hard);
    
    _isSoundOn = _prefs.getBool('isSoundOn') ?? true;
    _scoreX = _prefs.getInt('scoreX') ?? 0;
    _scoreO = _prefs.getInt('scoreO') ?? 0;

    // Load new premium settings
    _isPremium = _prefs.getBool('isPremium') ?? false;
    final boardLayoutName = _prefs.getString('boardLayout') ?? BoardLayout.single.name;
    _boardLayout = BoardLayout.values.firstWhere((l) => l.name == boardLayoutName, orElse: () => BoardLayout.single);

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

  // ARCHITECTURAL ADDITION: Method to change board layout.
  Future<void> setBoardLayout(BoardLayout layout) async {
    // In a real app, you might show a paywall here.
    if (!_isPremium && (layout == BoardLayout.double || layout == BoardLayout.triple)) {
      print("This is a premium feature!");
      return; // Don't allow setting premium layout if not premium.
    }
    _boardLayout = layout;
    await _prefs.setString('boardLayout', layout.name);
    notifyListeners();
  }

  // ARCHITECTURAL ADDITION: Simulate a purchase by toggling premium status.
  Future<void> togglePremium() async {
    _isPremium = !_isPremium;
    await _prefs.setBool('isPremium', _isPremium);

    // If premium is turned off, revert to a non-premium board layout.
    if (!_isPremium && _boardLayout != BoardLayout.single) {
      _boardLayout = BoardLayout.single;
      await _prefs.setString('boardLayout', _boardLayout.name);
    }
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
    notifyListeners();
  }

  void consumeGameResetRequest() {
    _resetGameRequested = false;
  }
}
