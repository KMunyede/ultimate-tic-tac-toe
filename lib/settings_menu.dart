import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'settings_controller.dart';
import 'sound_manager.dart';
import 'widgets/gradient_button.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final soundManager = context.read<SoundManager>();
    final theme = settings.currentTheme;

    return AlertDialog(
      title: const Text('Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeSelector(context, settings),
            const SizedBox(height: 16),
            _buildGameModeSelector(context, settings),
            if (settings.gameMode == GameMode.playerVsAi) ...[
              _buildAiDifficultySelector(context, settings),
              const SizedBox(height: 8),
              SwitchListTile(
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
                Navigator.of(context).pop();
              },
              gradient: LinearGradient(
                colors: [theme.gradientStart, theme.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              textColor: theme.textColor,
              child: const Text('Reset Game & Scores'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(
      BuildContext context, SettingsController settings) {
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

  Widget _buildGameModeSelector(
      BuildContext context, SettingsController settings) {
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
          child: Text(mode.name),
        );
      },
    );
  }

  Widget _buildAiDifficultySelector(
      BuildContext context, SettingsController settings) {
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
          child: Text(difficulty.name),
        );
      },
    );
  }

  Widget _buildBoardCountSelector(
      BuildContext context, SettingsController settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Boards: ${settings.boardCount}'),
        Slider(
          value: settings.boardCount.toDouble(),
          min: 1,
          max: 9,
          divisions: 8,
          label: settings.boardCount.toString(),
          onChanged: (double value) {
            settings.setBoardCount(value.toInt());
          },
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
