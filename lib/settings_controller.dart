import 'package:flutter/material.dart';
import 'package:tictactoe/app_theme.dart';
import 'services/persistence_service.dart';

import 'models/game_enums.dart';
import 'models/player.dart';

export 'models/game_enums.dart';

class SettingsController with ChangeNotifier {
  final PersistenceService _persistence = PersistenceService();

  AppTheme _currentTheme = appThemes.first;
  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => generateTheme(_currentTheme.mainColor);

  bool _isSoundOn = true;
  bool get isSoundOn => _isSoundOn;

  GameMode _gameMode = GameMode.playerVsPlayer;
  GameMode get gameMode => _gameMode;

  AiDifficulty _aiDifficulty = AiDifficulty.hard;
  AiDifficulty get aiDifficulty => _aiDifficulty;

  int _boardCount = 1;
  int get boardCount => _boardCount;

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
    final data = await _persistence.loadAll();

    final themeName = data['theme'] ?? appThemes.first.name;
    _currentTheme = appThemes.firstWhere(
      (t) => t.name == themeName,
      orElse: () => appThemes.first,
    );

    final gameModeName = data['gameMode'] ?? GameMode.playerVsPlayer.name;
    _gameMode = GameMode.values.firstWhere(
      (m) => m.name == gameModeName,
      orElse: () => GameMode.playerVsPlayer,
    );

    final aiDifficultyName = data['aiDifficulty'] ?? AiDifficulty.hard.name;
    _aiDifficulty = AiDifficulty.values.firstWhere(
      (d) => d.name == aiDifficultyName,
      orElse: () => AiDifficulty.hard,
    );

    _boardCount = data['boardCount'] ?? 1;
    _isSoundOn = data['isSoundOn'] ?? true;
    _isPremium = data['isPremium'] ?? false;
    _useOnlineAi = data['useOnlineAi'] ?? false;
    _scoreX = data['scoreX'] ?? 0;
    _scoreO = data['scoreO'] ?? 0;
    _lastStartingBoardIndex = data['lastStartingBoardIndex'] ?? -1;

    notifyListeners();
  }

  Future<void> _save(String key, dynamic value) async {
    await _persistence.save({key: value});
  }

  Future<void> changeTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _save('theme', theme.name);
    notifyListeners();
  }

  void _triggerGameReset() {
    _resetGameRequested = true;
    notifyListeners();
  }

  Future<void> setGameMode(GameMode mode) async {
    if (_gameMode != mode) {
      _gameMode = mode;
      await _save('gameMode', mode.name);
      // Reset Games Won scores when switching modes
      await resetScores();
      _triggerGameReset();
    }
  }

  Future<void> setAiDifficulty(AiDifficulty difficulty) async {
    if (_aiDifficulty != difficulty) {
      _aiDifficulty = difficulty;
      await _save('aiDifficulty', difficulty.name);
      _triggerGameReset();
    }
  }

  Future<void> setBoardCount(int count) async {
    if (_boardCount != count && count > 0) {
      _boardCount = count;
      await _save('boardCount', count);
      _triggerGameReset();
    }
  }

  void toggleSound() {
    _isSoundOn = !_isSoundOn;
    _save('isSoundOn', _isSoundOn);
    notifyListeners();
  }

  void togglePremium() {
    _isPremium = !_isPremium;
    _save('isPremium', _isPremium);
    notifyListeners();
  }

  Future<void> setUseOnlineAi(bool value) async {
    if (_useOnlineAi != value) {
      _useOnlineAi = value;
      await _save('useOnlineAi', value);
      _triggerGameReset();
      notifyListeners();
    }
  }

  Future<void> updateScore(Player winner) async {
    if (winner == Player.X) {
      _scoreX++;
      await _save('scoreX', _scoreX);
    } else if (winner == Player.O) {
      _scoreO++;
      await _save('scoreO', _scoreO);
    }
    notifyListeners();
  }

  Future<void> setLastStartingBoardIndex(int index) async {
    _lastStartingBoardIndex = index;
    await _save('lastStartingBoardIndex', index);
    notifyListeners();
  }

  Future<void> resetScores() async {
    _scoreX = 0;
    _scoreO = 0;
    await _persistence.save({'scoreX': 0, 'scoreO': 0});
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
