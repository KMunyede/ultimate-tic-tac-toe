import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../logic/settings_controller.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/help_dialog.dart';

class SettingsMenu extends StatefulWidget {
  final bool isPersistent;
  const SettingsMenu({super.key, this.isPersistent = false});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final soundManager = context.read<SoundManager>();
    final theme = settings.currentTheme;

    if (widget.isPersistent) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: _buildSettingsList(context, settings, soundManager, theme),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Settings'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      content: SizedBox(
        width: (MediaQuery.of(context).size.width * 0.8).clamp(280, 500) + 10,
        child: _buildSettingsList(context, settings, soundManager, theme),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    SettingsController settings,
    SoundManager soundManager,
    AppTheme theme,
  ) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeSelector(context, settings),
            const SizedBox(height: 16),
            _buildRuleSetSelector(context, settings),
            const SizedBox(height: 16),
            _buildGameModeSelector(context, settings),
            if (settings.gameMode == GameMode.playerVsAi) ...[
              _buildAiDifficultySelector(context, settings),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use Online AI'),
                subtitle: const Text('Call Firebase for moves'),
                value: settings.useOnlineAi,
                onChanged: (value) {
                  settings.setUseOnlineAi(value);
                },
              ),
            ],
            const SizedBox(height: 16),
            _buildBoardCountSelector(context, settings),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sound'),
              value: settings.isSoundOn,
              onChanged: (value) {
                settings.toggleSound();
                if (value) {
                  soundManager.playMoveSound();
                }
              },
            ),
            const SizedBox(height: 20),
            GradientButton(
              onPressed: () {
                settings.resetGameAndScores();
                if (!widget.isPersistent) {
                  Navigator.of(context).pop();
                }
              },
              gradient: LinearGradient(
                colors: [theme.gradientStart, theme.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              textColor: theme.textColor,
              child: const Text('Reset Game & Scores'),
            ),
            if (widget.isPersistent) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  soundManager.playMoveSound();
                  showDialog(
                    context: context,
                    builder: (context) => const HelpDialog(),
                  );
                },
                icon: const Icon(Icons.help_outline, size: 20),
                label: const Text('Help & About'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    SettingsController settings,
  ) {
    return _buildDropdown(
      context: context,
      label: 'Theme',
      value: settings.currentTheme,
      items: appThemes,
      onChanged: (AppTheme? theme) {
        if (theme != null) {
          settings.changeTheme(theme);
        }
      },
      itemBuilder: (AppTheme theme) {
        return DropdownMenuItem<AppTheme>(
          value: theme,
          child: Text(theme.name),
        );
      },
    );
  }

  Widget _buildRuleSetSelector(
    BuildContext context,
    SettingsController settings,
  ) {
    return _buildDropdown(
      context: context,
      label: 'Rule Set',
      value: settings.ruleSet,
      items: GameRuleSet.values,
      onChanged: (GameRuleSet? ruleSet) {
        if (ruleSet != null) {
          settings.setRuleSet(ruleSet);
        }
      },
      itemBuilder: (GameRuleSet ruleSet) {
        return DropdownMenuItem<GameRuleSet>(
          value: ruleSet,
          child: Text(ruleSet.displayName),
        );
      },
    );
  }

  Widget _buildGameModeSelector(
    BuildContext context,
    SettingsController settings,
  ) {
    return _buildDropdown(
      context: context,
      label: 'Game Mode',
      value: settings.gameMode,
      items: GameMode.values,
      onChanged: (GameMode? mode) {
        if (mode != null) {
          settings.setGameMode(mode);
        }
      },
      itemBuilder: (GameMode mode) {
        return DropdownMenuItem<GameMode>(
          value: mode,
          child: Text(mode.displayName),
        );
      },
    );
  }

  Widget _buildAiDifficultySelector(
    BuildContext context,
    SettingsController settings,
  ) {
    return _buildDropdown(
      context: context,
      label: 'AI Difficulty',
      value: settings.aiDifficulty,
      items: AiDifficulty.values,
      onChanged: (AiDifficulty? difficulty) {
        if (difficulty != null) {
          settings.setAiDifficulty(difficulty);
        }
      },
      itemBuilder: (AiDifficulty difficulty) {
        return DropdownMenuItem<AiDifficulty>(
          value: difficulty,
          child: Text(difficulty.displayName),
        );
      },
    );
  }

  Widget _buildBoardCountSelector(
    BuildContext context,
    SettingsController settings,
  ) {
    final ruleSet = settings.ruleSet;
    final bool isUltimate = ruleSet == GameRuleSet.ultimate;
    final bool isStandard = ruleSet == GameRuleSet.standard;
    final bool isMajority = ruleSet == GameRuleSet.majorityWins;

    double min = 1;
    double max = 9;
    int? divisions = 8;
    String helpText = '';

    if (isStandard) {
      min = 1;
      max = 2;
      divisions = 1;
      helpText = 'Standard mode: 1 or 2 boards';
    } else if (isUltimate) {
      min = 9;
      max = 9;
      divisions = null;
      helpText = 'Ultimate mode: Fixed at 9 boards';
    } else if (isMajority) {
      min = 1;
      max = 9;
      divisions = 8;
      helpText = 'Majority Wins: 1 to 9 boards';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Boards: ${settings.boardCount}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUltimate ? Theme.of(context).disabledColor : null,
              ),
            ),
            if (isUltimate)
              const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
          ],
        ),
        Slider(
          value: settings.boardCount.toDouble().clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: settings.boardCount.toString(),
          onChanged: isUltimate
              ? null
              : (double value) {
                  settings.setBoardCount(value.toInt());
                },
        ),
        Text(
          helpText,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).disabledColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required DropdownMenuItem<T> Function(T item) itemBuilder,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        DropdownButton<T>(
          value: value,
          items: items.map(itemBuilder).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
