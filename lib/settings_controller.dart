import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictactoe/app_theme.dart';

import 'models/game_enums.dart';
import 'models/player.dart';

export 'models/game_enums.dart';

class SettingsController with ChangeNotifier {
  late SharedPreferences _prefs;

  AppTheme _currentTheme = appThemes.first;
  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => generateTheme(_currentTheme.mainColor);

  bool _isSoundOn = true;
  bool get isSoundOn => _isSoundOn;

  GameMode _gameMode = GameMode.playerVsPlayer;
  GameMode get gameMode => _gameMode;

  AiDifficulty _aiDifficulty = AiDifficulty.hard;
  AiDifficulty get aiDifficulty => _aiDifficulty;

  BoardLayout _boardLayout = BoardLayout.single;
  BoardLayout get boardLayout => _boardLayout;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  bool _useOnlineAi = false;
  bool get useOnlineAi => _useOnlineAi;

  int _scoreX = 0;
  int _scoreO = 0;
  int get scoreX => _scoreX;
  int get scoreO => _scoreO;

  int _lastStartingBoardIndex = -1;
  int get lastStartingBoardIndex => _lastStartingBoardIndex;

  bool _resetGameRequested = false;
  bool get resetGameRequested => _resetGameRequested;

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    final themeName = _prefs.getString('theme') ?? appThemes.first.name;
    _currentTheme = appThemes.firstWhere((t) => t.name == themeName,
        orElse: () => appThemes.first);

    final gameModeName =
        _prefs.getString('gameMode') ?? GameMode.playerVsPlayer.name;
    _gameMode = GameMode.values.firstWhere((m) => m.name == gameModeName,
        orElse: () => GameMode.playerVsPlayer);

    final aiDifficultyName =
        _prefs.getString('aiDifficulty') ?? AiDifficulty.hard.name;
    _aiDifficulty = AiDifficulty.values.firstWhere(
        (d) => d.name == aiDifficultyName,
        orElse: () => AiDifficulty.hard);

    final boardLayoutName =
        _prefs.getString('boardLayout') ?? BoardLayout.single.name;
    _boardLayout = BoardLayout.values.firstWhere(
        (l) => l.name == boardLayoutName,
        orElse: () => BoardLayout.single);

    _isSoundOn = _prefs.getBool('isSoundOn') ?? true;
    _isPremium = _prefs.getBool('isPremium') ?? false;
    _useOnlineAi = _prefs.getBool('useOnlineAi') ?? false;
    _scoreX = _prefs.getInt('scoreX') ?? 0;
    _scoreO = _prefs.getInt('scoreO') ?? 0;
    _lastStartingBoardIndex = _prefs.getInt('lastStartingBoardIndex') ?? -1;

    notifyListeners();
  }

  Future<void> changeTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _prefs.setString('theme', theme.name);
    notifyListeners();
  }

  void _triggerGameReset() {
    _resetGameRequested = true;
    notifyListeners();
  }

  Future<void> setGameMode(GameMode mode) async {
    if (_gameMode != mode) {
      _gameMode = mode;
      await _prefs.setString('gameMode', mode.name);
      _triggerGameReset();
    }
  }

  Future<void> setAiDifficulty(AiDifficulty difficulty) async {
    if (_aiDifficulty != difficulty) {
      _aiDifficulty = difficulty;
      await _prefs.setString('aiDifficulty', difficulty.name);
      _triggerGameReset();
    }
  }

  Future<void> setBoardLayout(BoardLayout layout) async {
    if (_boardLayout != layout) {
      _boardLayout = layout;
      await _prefs.setString('boardLayout', layout.name);
      _triggerGameReset();
    }
  }

  void toggleSound() {
    _isSoundOn = !_isSoundOn;
    _prefs.setBool('isSoundOn', _isSoundOn);
    notifyListeners();
  }

  void togglePremium() {
    _isPremium = !_isPremium;
    _prefs.setBool('isPremium', _isPremium);
    notifyListeners();
  }

  Future<void> setUseOnlineAi(bool value) async {
    if (_useOnlineAi != value) {
      _useOnlineAi = value;
      await _prefs.setBool('useOnlineAi', value);
      _triggerGameReset(); // This will now start a new game
      notifyListeners();
    }
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

  Future<void> setLastStartingBoardIndex(int index) async {
    _lastStartingBoardIndex = index;
    await _prefs.setInt('lastStartingBoardIndex', index);
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
    _triggerGameReset();
  }

  void consumeGameResetRequest() {
    _resetGameRequested = false;
  }
}
