import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/persistence_service.dart';

import '../../../models/game_enums.dart';
import '../../../models/player.dart';

export '../../../models/game_enums.dart';

class SettingsController with ChangeNotifier {
  final PersistenceService _persistence = PersistenceService();

  AppTheme _currentTheme = appThemes.first;
  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => generateTheme(_currentTheme.mainColor);

  bool _isSoundOn = true;
  bool get isSoundOn => _isSoundOn;

  GameMode _gameMode = GameMode.playerVsAi;
  GameMode get gameMode => _gameMode;

  GameRuleSet _ruleSet = GameRuleSet.standard;
  GameRuleSet get ruleSet => _ruleSet;

  AiDifficulty _aiDifficulty = AiDifficulty.hard;
  AiDifficulty get aiDifficulty => _aiDifficulty;

  int _boardCount = 1;
  int get boardCount => _boardCount;

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  bool _useOnlineAi = true;
  bool get useOnlineAi => _useOnlineAi;

  int _scoreX = 0;
  int _scoreO = 0;
  int get scoreX => _scoreX;
  int get scoreO => _scoreO;

  int _lastStartingBoardIndex = -1;
  int get lastStartingBoardIndex => _lastStartingBoardIndex;

  bool _resetGameRequested = false;
  bool get resetGameRequested => _resetGameRequested;

  bool _isFirstRun = true;
  bool get isFirstRun => _isFirstRun;

  bool _isGuest = false;
  bool get isGuest => _isGuest;

  static const String currentAppVersion = "2.0.0";

  Future<void> loadSettings({bool isGuest = false}) async {
    _isGuest = isGuest;
    final data = await _persistence.loadAll();

    _isFirstRun = data['isFirstRun'] ?? true;
    final lastVersion = data['lastVersion'] as String? ?? "0.0.0";

    // 1. Mandatory Reset for v2.0.0 Upgrade or First Run
    if (_isFirstRun || lastVersion != currentAppVersion) {
      // Force requested defaults
      _ruleSet = GameRuleSet.standard;
      _boardCount = 2; // Default to 2 boards as requested
      _gameMode = GameMode.playerVsAi;
      _isSoundOn = true;
      _useOnlineAi = false; // Online AI = Off by default
      
      // Preserve WIN scores if they exist
      _scoreX = data['scoreX'] ?? 0;
      _scoreO = data['scoreO'] ?? 0;

      // Update version tracking and mark first run handled
      await _save('lastVersion', currentAppVersion);
      if (_isFirstRun) {
        await _save('isFirstRun', false);
        _isFirstRun = false;
      }
    } else {
      // 2. Normal Loading for subsequent opens
      final gameModeName = data['gameMode'] ?? GameMode.playerVsAi.name;
      _gameMode = GameMode.values.firstWhere(
        (m) => m.name == gameModeName,
        orElse: () => GameMode.playerVsAi,
      );

      final ruleSetName = data['ruleSet'] ?? GameRuleSet.standard.name;
      _ruleSet = GameRuleSet.values.firstWhere(
        (r) => r.name == ruleSetName,
        orElse: () => GameRuleSet.standard,
      );

      _boardCount = data['boardCount'] ?? 2;
      _isSoundOn = data['isSoundOn'] ?? true;
      _useOnlineAi = data['useOnlineAi'] ?? false;
      _scoreX = data['scoreX'] ?? 0;
      _scoreO = data['scoreO'] ?? 0;
    }

    final themeName = data['theme'] ?? appThemes.first.name;
    _currentTheme = appThemes.firstWhere(
      (t) => t.name == themeName,
      orElse: () => appThemes.first,
    );

    final aiDifficultyName = data['aiDifficulty'] ?? AiDifficulty.hard.name;
    _aiDifficulty = AiDifficulty.values.firstWhere(
      (d) => d.name == aiDifficultyName,
      orElse: () => AiDifficulty.hard,
    );

    _isPremium = data['isPremium'] ?? false;
    _lastStartingBoardIndex = data['lastStartingBoardIndex'] ?? -1;

    // Reset game-specific logic state when settings are loaded to prevent stale resets
    _resetGameRequested = false;

    notifyListeners();
  }

  Future<void> _save(String key, dynamic value) async {
    // Feature Gate: Only save Settings Online/Locally for Registered users
    // Guests do not persist settings across app restarts
    if (_isGuest && key != 'isFirstRun' && key != 'lastVersion') return;
    
    await _persistence.save({key: value});
  }

  Future<void> markFirstRunComplete() async {
    _isFirstRun = false;
    await _save('isFirstRun', false);
    notifyListeners();
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

  Future<void> setRuleSet(GameRuleSet ruleSet) async {
    if (_ruleSet != ruleSet) {
      _ruleSet = ruleSet;
      
      // Enforce board count constraints on rule change
      if (ruleSet == GameRuleSet.standard) {
        _boardCount = 1;
      } else if (ruleSet == GameRuleSet.ultimate) {
        _boardCount = 9;
      } else if (ruleSet == GameRuleSet.majorityWins) {
        _boardCount = _boardCount.clamp(1, 9);
      }
      
      await _save('ruleSet', ruleSet.name);
      await _save('boardCount', _boardCount);
      await resetScores();
      _triggerGameReset();
    }
  }

  Future<void> setBoardCount(int count) async {
    int newCount = _boardCount;

    if (_ruleSet == GameRuleSet.standard) {
      // Standard: 1 or 2 boards allowed. 
      // If Guest, explicitly cap at 2.
      if (_isGuest) {
        newCount = count.clamp(1, 2);
      } else {
        if (count == 1 || count == 2) {
          newCount = count;
        }
      }
    } else if (_ruleSet == GameRuleSet.majorityWins) {
      // Majority Wins: 1 to 9 boards allowed
      newCount = count.clamp(1, 9);
    } else if (_ruleSet == GameRuleSet.ultimate) {
      // Ultimate: Locked at 9, ignore all changes
      return;
    }

    if (_boardCount != newCount) {
      _boardCount = newCount;
      await _save('boardCount', newCount);
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
    } else if (winner == Player.O) {
      _scoreO++;
    }
    
    // Feature Gate: Only save Scores Online for Registered users
    // For Guests, we only keep it in memory (across current session)
    if (!_isGuest) {
      await _save('scoreX', _scoreX);
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
