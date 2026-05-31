import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/persistence_service.dart';

import '../../../models/game_enums.dart';
import '../../../models/player.dart';
import '../../../models/match_session.dart';

export '../../../models/game_enums.dart';

enum BoardLayoutType { grid, smartFlow, focused }

class BoardLayoutTemplate {
  final String name;
  final List<Offset> positions;

  const BoardLayoutTemplate({required this.name, required this.positions});
}

class SettingsController with ChangeNotifier {
  final PersistenceService _persistence = PersistenceService();

  int _layoutIndex = 0;
  int get layoutIndex => _layoutIndex;

  BoardLayoutType get boardLayout => BoardLayoutType.grid; // Keep for backward compatibility

  void toggleBoardLayout() {
    if (_boardCount <= 1) return;
    final templates = getTemplatesForCount(_boardCount);
    _layoutIndex = (_layoutIndex + 1) % templates.length;
    notifyListeners();
  }

  String get currentLayoutName {
    final templates = getTemplatesForCount(_boardCount);
    if (templates.isEmpty) return "Standard";
    return templates[_layoutIndex % templates.length].name;
  }

  static List<BoardLayoutTemplate> getTemplatesForCount(int count) {
    if (count <= 1) {
      return [const BoardLayoutTemplate(name: "Center", positions: [Offset(0.5, 0.5)])];
    }
    
    if (count == 2) {
      return [
        const BoardLayoutTemplate(name: "Letter L Shape", positions: [Offset(0.30, 0.20), Offset(0.70, 0.80)]),
        const BoardLayoutTemplate(name: "Letter T (Vertical)", positions: [Offset(0.50, 0.22), Offset(0.50, 0.78)]),
        const BoardLayoutTemplate(name: "Slanted Line (/)", positions: [Offset(0.25, 0.75), Offset(0.75, 0.25)]),
      ];
    }
    
    if (count == 3) {
      return [
        const BoardLayoutTemplate(name: "Letter V Shape", positions: [Offset(0.18, 0.18), Offset(0.50, 0.82), Offset(0.82, 0.18)]),
        const BoardLayoutTemplate(name: "Letter L Shape", positions: [Offset(0.25, 0.18), Offset(0.25, 0.82), Offset(0.75, 0.82)]),
        const BoardLayoutTemplate(name: "Letter Y Shape", positions: [Offset(0.18, 0.18), Offset(0.82, 0.18), Offset(0.50, 0.65)]),
        const BoardLayoutTemplate(name: "Triangle Shape (Δ)", positions: [Offset(0.50, 0.18), Offset(0.18, 0.82), Offset(0.82, 0.82)]),
      ];
    }
    
    if (count == 4) {
      return [
        const BoardLayoutTemplate(name: "Letter Y Shape", positions: [Offset(0.20, 0.18), Offset(0.80, 0.18), Offset(0.50, 0.48), Offset(0.50, 0.82)]),
        const BoardLayoutTemplate(name: "Letter K Shape", positions: [Offset(0.25, 0.18), Offset(0.25, 0.82), Offset(0.75, 0.20), Offset(0.75, 0.80)]),
        const BoardLayoutTemplate(name: "Letter H Shape", positions: [Offset(0.22, 0.18), Offset(0.22, 0.82), Offset(0.78, 0.18), Offset(0.78, 0.82)]),
        const BoardLayoutTemplate(name: "Letter T Shape", positions: [Offset(0.18, 0.20), Offset(0.50, 0.20), Offset(0.82, 0.20), Offset(0.50, 0.78)]),
        const BoardLayoutTemplate(name: "Diamond Shape", positions: [Offset(0.50, 0.15), Offset(0.15, 0.50), Offset(0.85, 0.50), Offset(0.50, 0.85)]),
      ];
    }
    
    if (count == 5) {
      return [
        const BoardLayoutTemplate(name: "Letter W Shape", positions: [Offset(0.15, 0.20), Offset(0.32, 0.80), Offset(0.50, 0.35), Offset(0.68, 0.80), Offset(0.85, 0.20)]),
        const BoardLayoutTemplate(name: "Letter X Shape", positions: [Offset(0.20, 0.20), Offset(0.80, 0.20), Offset(0.50, 0.50), Offset(0.20, 0.80), Offset(0.80, 0.80)]),
        const BoardLayoutTemplate(name: "Letter T Shape", positions: [Offset(0.15, 0.18), Offset(0.50, 0.18), Offset(0.85, 0.18), Offset(0.50, 0.51), Offset(0.50, 0.84)]),
        const BoardLayoutTemplate(name: "Letter H Shape", positions: [Offset(0.22, 0.18), Offset(0.22, 0.82), Offset(0.50, 0.50), Offset(0.78, 0.18), Offset(0.78, 0.82)]),
      ];
    }
    
    if (count == 6) {
      return [
        const BoardLayoutTemplate(name: "Letter S Shape", positions: [Offset(0.78, 0.16), Offset(0.35, 0.20), Offset(0.22, 0.45), Offset(0.78, 0.55), Offset(0.65, 0.80), Offset(0.22, 0.84)]),
        const BoardLayoutTemplate(name: "Letter H Shape", positions: [Offset(0.20, 0.16), Offset(0.20, 0.50), Offset(0.20, 0.84), Offset(0.50, 0.50), Offset(0.80, 0.25), Offset(0.80, 0.75)]),
        BoardLayoutTemplate(name: "Letter O Shape (Ring)", positions: List.generate(6, (i) => Offset(0.5 + 0.33 * cos(i * 2 * pi / 6), 0.5 + 0.33 * sin(i * 2 * pi / 6)))),
        const BoardLayoutTemplate(name: "Letter Y Shape", positions: [Offset(0.20, 0.15), Offset(0.80, 0.15), Offset(0.35, 0.38), Offset(0.65, 0.38), Offset(0.50, 0.61), Offset(0.50, 0.84)]),
      ];
    }
    
    if (count == 7) {
      return [
        const BoardLayoutTemplate(name: "Letter H Shape", positions: [Offset(0.20, 0.16), Offset(0.20, 0.50), Offset(0.20, 0.84), Offset(0.50, 0.50), Offset(0.80, 0.16), Offset(0.80, 0.50), Offset(0.80, 0.84)]),
        const BoardLayoutTemplate(name: "Letter V Shape", positions: [Offset(0.15, 0.15), Offset(0.26, 0.38), Offset(0.37, 0.61), Offset(0.50, 0.84), Offset(0.63, 0.61), Offset(0.74, 0.38), Offset(0.85, 0.15)]),
        const BoardLayoutTemplate(name: "Letter T Shape", positions: [Offset(0.12, 0.18), Offset(0.31, 0.18), Offset(0.50, 0.18), Offset(0.69, 0.18), Offset(0.88, 0.18), Offset(0.50, 0.51), Offset(0.50, 0.84)]),
        const BoardLayoutTemplate(name: "Flower Shape (Star)", positions: [Offset(0.50, 0.50), Offset(0.50, 0.15), Offset(0.80, 0.33), Offset(0.80, 0.67), Offset(0.50, 0.85), Offset(0.20, 0.67), Offset(0.20, 0.33)]),
      ];
    }
    
    if (count == 8) {
      return [
        BoardLayoutTemplate(name: "Letter O Shape (Ring)", positions: List.generate(8, (i) => Offset(0.5 + 0.33 * cos(i * 2 * pi / 8), 0.5 + 0.33 * sin(i * 2 * pi / 8)))),
        const BoardLayoutTemplate(name: "Letter H Shape", positions: [Offset(0.20, 0.16), Offset(0.20, 0.50), Offset(0.20, 0.84), Offset(0.40, 0.50), Offset(0.60, 0.50), Offset(0.80, 0.16), Offset(0.80, 0.50), Offset(0.80, 0.84)]),
        const BoardLayoutTemplate(name: "Letter K Shape", positions: [Offset(0.20, 0.16), Offset(0.20, 0.38), Offset(0.20, 0.60), Offset(0.20, 0.84), Offset(0.45, 0.50), Offset(0.70, 0.25), Offset(0.75, 0.75), Offset(0.90, 0.84)]),
        const BoardLayoutTemplate(name: "Double Column Shape", positions: [Offset(0.25, 0.16), Offset(0.25, 0.38), Offset(0.25, 0.60), Offset(0.25, 0.84), Offset(0.75, 0.16), Offset(0.75, 0.38), Offset(0.75, 0.60), Offset(0.75, 0.84)]),
      ];
    }
    
    if (count == 9) {
      return [
        const BoardLayoutTemplate(name: "Letter Z Shape", positions: [Offset(0.16, 0.16), Offset(0.50, 0.16), Offset(0.84, 0.16), Offset(0.68, 0.38), Offset(0.50, 0.50), Offset(0.32, 0.62), Offset(0.16, 0.84), Offset(0.50, 0.84), Offset(0.84, 0.84)]),
        const BoardLayoutTemplate(name: "Letter H Shape", positions: [Offset(0.20, 0.15), Offset(0.20, 0.38), Offset(0.20, 0.61), Offset(0.20, 0.85), Offset(0.50, 0.50), Offset(0.80, 0.15), Offset(0.80, 0.38), Offset(0.80, 0.61), Offset(0.80, 0.85)]),
        const BoardLayoutTemplate(name: "Letter E Shape", positions: [Offset(0.16, 0.16), Offset(0.50, 0.16), Offset(0.84, 0.16), Offset(0.16, 0.38), Offset(0.16, 0.50), Offset(0.50, 0.50), Offset(0.16, 0.62), Offset(0.16, 0.84), Offset(0.50, 0.84), Offset(0.84, 0.84)]),
        BoardLayoutTemplate(name: "Concentric Circle Shape", positions: [Offset(0.50, 0.50)] + List.generate(8, (i) => Offset(0.5 + 0.33 * cos(i * 2 * pi / 8), 0.5 + 0.33 * sin(i * 2 * pi / 8)))),
      ];
    }
    
    // Fallback for counts > 9: Golden angle spiral
    final List<Offset> spiralPositions = [];
    for (int i = 0; i < count; i++) {
      double angle = i * 2.39996;
      double r = sqrt(i) / sqrt(count - 1) * 0.42;
      double jitterX = sin(i * 12.0) * 0.025;
      double jitterY = cos(i * 17.0) * 0.025;
      spiralPositions.add(Offset((0.5 + cos(angle) * r + jitterX).clamp(0.08, 0.92), (0.5 + sin(angle) * r + jitterY).clamp(0.08, 0.92)));
    }
    return [BoardLayoutTemplate(name: "Concentric Cluster", positions: spiralPositions)];
  }

  AppTheme _currentTheme = appThemes.first;
  AppTheme get currentTheme => _currentTheme;
  ThemeData get themeData => generateTheme(_currentTheme);

  bool _isSoundOn = true;
  bool get isSoundOn => _isSoundOn;

  bool _lowDetailMode = false;
  bool get lowDetailMode => _lowDetailMode;

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

    _lowDetailMode = data['lowDetailMode'] ?? false;
 
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
      _layoutIndex = 0; // Reset layout index when board count changes
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

  void toggleLowDetailMode() {
    _lowDetailMode = !_lowDetailMode;
    _save('lowDetailMode', _lowDetailMode);
    notifyListeners();
  }

  void setLowDetailMode(bool value) {
    if (_lowDetailMode != value) {
      _lowDetailMode = value;
      _save('lowDetailMode', value);
      notifyListeners();
    }
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

  Future<void> syncWithSession(MatchSession session) async {
    bool changed = false;
    if (_ruleSet != session.ruleSet) {
      _ruleSet = session.ruleSet;
      await _save('ruleSet', _ruleSet.name);
      changed = true;
    }
    if (_boardCount != session.boards.length) {
      _boardCount = session.boards.length;
      await _save('boardCount', _boardCount);
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }
}
