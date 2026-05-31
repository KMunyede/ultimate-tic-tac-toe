import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../logic/settings_controller.dart';
import '../../../core/audio/sound_manager.dart';
import '../../../widgets/gradient_button.dart';
import '../../../widgets/help_dialog.dart';
import '../../game/screens/animation_demo_screen.dart';
import '../../../widgets/board_widget.dart';

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

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLandscape = screenWidth > screenHeight;

    final double dialogWidth = (screenWidth * 0.92).clamp(320.0, 560.0);
    final double maxDialogHeight = isLandscape ? screenHeight * 0.94 : screenHeight * 0.96;

    Widget doneBtn;
    if (theme.name == 'Rushing Wind') {
      doneBtn = TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          foregroundColor: theme.textColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        child: const Text('DONE'),
      );
    } else {
      doneBtn = TextButton(
        onPressed: () => Navigator.of(context).pop(),
        style: TextButton.styleFrom(
          foregroundColor: theme.mainColor,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        child: const Text('DONE'),
      );
    }

    Widget dialogContent = Container(
      width: dialogWidth,
      constraints: BoxConstraints(
        maxHeight: maxDialogHeight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Theme-Styled Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: theme.textColor),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Container(
            height: 1.0,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            color: theme.textColor.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          // Scrollable Settings List
          Expanded(
            child: _buildSettingsList(context, settings, soundManager, theme),
          ),
          const SizedBox(height: 8),
          // Done Button Row
          Padding(
            padding: const EdgeInsets.only(right: 12.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                doneBtn,
              ],
            ),
          ),
        ],
      ),
    );

    Widget dialogFrame;
    BorderRadius dialogRadius = BorderRadius.circular(18);

    if (theme.name == 'Rushing Wind') {
      dialogRadius = BorderRadius.circular(24);
      dialogFrame = Container(
        decoration: BoxDecoration(
          color: theme.boardBg,
          borderRadius: dialogRadius,
          boxShadow: [
            BoxShadow(
              color: NeumorphicColors.getDarkShadow(theme.boardBg),
              offset: const Offset(8, 8),
              blurRadius: 18,
            ),
            BoxShadow(
              color: NeumorphicColors.getLightShadow(theme.boardBg),
              offset: const Offset(-8, -8),
              blurRadius: 18,
            ),
          ],
        ),
        child: CustomPaint(
          painter: ClayBevelPainter(
            borderRadius: 24.0,
            baseColor: theme.boardBg,
            themeName: theme.name,
          ),
          child: dialogContent,
        ),
      );
    } else if (theme.name == 'Floating Feather') {
      dialogRadius = BorderRadius.circular(16);
      dialogFrame = Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBg,
          borderRadius: dialogRadius,
          border: Border.all(color: const Color(0xFFB5937E).withValues(alpha: 0.3), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB5937E).withValues(alpha: 0.08),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: dialogContent,
      );
    } else if (theme.name == 'Rising Moon') {
      dialogRadius = BorderRadius.circular(20);
      dialogFrame = ClipRRect(
        borderRadius: dialogRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF453D4D).withValues(alpha: 0.85),
              borderRadius: dialogRadius,
              border: Border.all(color: theme.mainColor.withValues(alpha: 0.5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                ),
              ],
            ),
            child: dialogContent,
          ),
        ),
      );
    } else if (theme.name == 'Drifting Cloud') {
      dialogRadius = BorderRadius.circular(8);
      dialogFrame = Container(
        decoration: BoxDecoration(
          color: theme.boardBg,
          borderRadius: dialogRadius,
          border: Border.all(color: theme.textColor, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: theme.textColor,
              offset: const Offset(5, 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: dialogContent,
      );
    } else if (theme.name == 'Crimson Leaf') {
      dialogRadius = BorderRadius.circular(14);
      dialogFrame = Container(
        decoration: BoxDecoration(
          color: theme.boardBg,
          borderRadius: dialogRadius,
          border: Border.all(color: const Color(0xFFCCA67C), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 6),
              blurRadius: 18,
            ),
          ],
        ),
        child: dialogContent,
      );
    } else {
      dialogFrame = Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBg,
          borderRadius: dialogRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(0, 10),
              blurRadius: 20,
            ),
          ],
        ),
        child: dialogContent,
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 40.0 : 20.0,
        vertical: isLandscape ? 12.0 : 24.0,
      ),
      child: dialogFrame,
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    SettingsController settings,
    SoundManager soundManager,
    AppTheme theme,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isLandscape = screenWidth > screenHeight;

    final Widget settingsContent = isLandscape
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThemeSelector(context, settings, theme),
                    const SizedBox(height: 8),
                    _buildRuleSetSelector(context, settings, theme),
                    const SizedBox(height: 8),
                    _buildGameModeSelector(context, settings, theme),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (settings.gameMode == GameMode.playerVsAi) ...[
                      _buildAiDifficultySelector(context, settings, theme),
                      const SizedBox(height: 8),
                    ],
                    _buildBoardCountSelector(context, settings, theme),
                    const SizedBox(height: 8),
                    _buildCompactTogglesRow(context, settings, soundManager, theme),
                  ],
                ),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeSelector(context, settings, theme),
              const SizedBox(height: 8),
              _buildRuleSetSelector(context, settings, theme),
              const SizedBox(height: 8),
              _buildGameModeSelector(context, settings, theme),
              const SizedBox(height: 8),
              if (settings.gameMode == GameMode.playerVsAi) ...[
                _buildAiDifficultySelector(context, settings, theme),
                const SizedBox(height: 8),
              ],
              _buildBoardCountSelector(context, settings, theme),
              const SizedBox(height: 10),
              _buildCompactTogglesRow(context, settings, soundManager, theme),
            ],
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          settingsContent,
          const SizedBox(height: 16),
          // Action Buttons Row (placed side-by-side)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    soundManager.playMoveSound();
                    if (!widget.isPersistent) {
                      Navigator.of(context).pop();
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AnimationDemoScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.mainColor.withValues(alpha: 0.5)),
                    foregroundColor: theme.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.palette_outlined, size: 18, color: theme.mainColor),
                  label: const Text(
                    'Graphics Lab',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  onPressed: () {
                    settings.resetGameAndScores();
                    if (!widget.isPersistent) {
                      Navigator.of(context).pop();
                    }
                  },
                  gradient: LinearGradient(
                    colors: [theme.mainColor, theme.accentGlow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  textColor: theme.textColor,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: const Text(
                    'Reset Game & Scores',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
          if (widget.isPersistent) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                soundManager.playMoveSound();
                showDialog(
                  context: context,
                  builder: (context) => const HelpDialog(),
                );
              },
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Help & About', style: TextStyle(fontSize: 12.5)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactTogglesRow(
    BuildContext context,
    SettingsController settings,
    SoundManager soundManager,
    AppTheme theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIconToggle(
          context: context,
          icon: settings.isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          label: 'Sound',
          isActive: settings.isSoundOn,
          theme: theme,
          onTap: () {
            settings.toggleSound();
            if (settings.isSoundOn) {
              soundManager.playMoveSound();
            }
          },
        ),
        if (settings.gameMode == GameMode.playerVsAi)
          _buildIconToggle(
            context: context,
            icon: settings.useOnlineAi ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            label: 'Online AI',
            isActive: settings.useOnlineAi,
            theme: theme,
            onTap: () {
              settings.setUseOnlineAi(!settings.useOnlineAi);
            },
          ),
        _buildIconToggle(
          context: context,
          icon: settings.lowDetailMode ? Icons.bolt_rounded : Icons.offline_bolt_outlined,
          label: 'Lite Mode',
          isActive: settings.lowDetailMode,
          theme: theme,
          onTap: () {
            settings.setLowDetailMode(!settings.lowDetailMode);
          },
        ),
      ],
    );
  }

  Widget _buildIconToggle({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required AppTheme theme,
    required VoidCallback onTap,
  }) {
    final activeColor = theme.mainColor;
    final iconColor = isActive ? Colors.white : theme.textColor.withValues(alpha: 0.6);
    final bool isRushingWind = theme.name == 'Rushing Wind';

    final Color activeBgColor = isRushingWind ? theme.mainColor : theme.mainColor;
    final Color inactiveBgColor = isRushingWind 
        ? theme.scaffoldBg.withValues(alpha: 0.4) 
        : theme.boardBg.withValues(alpha: 0.5);

    final boxDecoration = isRushingWind
        ? BoxDecoration(
            color: isActive ? activeBgColor : inactiveBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? theme.mainColor : theme.textColor.withValues(alpha: 0.10),
              width: 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: NeumorphicColors.getDarkShadow(theme.boardBg).withValues(alpha: 0.45),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                    BoxShadow(
                      color: NeumorphicColors.getLightShadow(theme.boardBg).withValues(alpha: 0.45),
                      offset: const Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          )
        : BoxDecoration(
            color: isActive ? activeColor : theme.boardBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? activeColor : theme.textColor.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.25),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(7.0),
            decoration: boxDecoration,
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: theme.textColor.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    SettingsController settings,
    AppTheme theme,
  ) {
    return _buildDropdown<AppTheme>(
      context: context,
      label: 'Theme',
      value: settings.currentTheme,
      items: appThemes,
      theme: theme,
      onChanged: (AppTheme? selectedTheme) {
        if (selectedTheme != null) {
          settings.changeTheme(selectedTheme);
        }
      },
      itemBuilder: (AppTheme itemTheme) {
        return DropdownMenuItem<AppTheme>(
          value: itemTheme,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              itemTheme.name,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuleSetSelector(
    BuildContext context,
    SettingsController settings,
    AppTheme theme,
  ) {
    return _buildDropdown<GameRuleSet>(
      context: context,
      label: 'Rule Set',
      value: settings.ruleSet,
      items: GameRuleSet.values,
      theme: theme,
      onChanged: (GameRuleSet? ruleSet) {
        if (ruleSet != null) {
          settings.setRuleSet(ruleSet);
        }
      },
      itemBuilder: (GameRuleSet ruleSet) {
        return DropdownMenuItem<GameRuleSet>(
          value: ruleSet,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              ruleSet.displayName,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameModeSelector(
    BuildContext context,
    SettingsController settings,
    AppTheme theme,
  ) {
    return _buildDropdown<GameMode>(
      context: context,
      label: 'Game Mode',
      value: settings.gameMode,
      items: GameMode.values,
      theme: theme,
      onChanged: (GameMode? mode) {
        if (mode != null) {
          settings.setGameMode(mode);
        }
      },
      itemBuilder: (GameMode mode) {
        return DropdownMenuItem<GameMode>(
          value: mode,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              mode.displayName,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiDifficultySelector(
    BuildContext context,
    SettingsController settings,
    AppTheme theme,
  ) {
    return _buildDropdown<AiDifficulty>(
      context: context,
      label: 'AI Diff',
      value: settings.aiDifficulty,
      items: AiDifficulty.values,
      theme: theme,
      onChanged: (AiDifficulty? difficulty) {
        if (difficulty != null) {
          settings.setAiDifficulty(difficulty);
        }
      },
      itemBuilder: (AiDifficulty difficulty) {
        return DropdownMenuItem<AiDifficulty>(
          value: difficulty,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              difficulty.displayName,
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoardCountSelector(
    BuildContext context,
    SettingsController settings,
    AppTheme theme,
  ) {
    final ruleSet = settings.ruleSet;
    final bool isUltimate = ruleSet == GameRuleSet.ultimate;
    final bool isStandard = ruleSet == GameRuleSet.standard;
    final bool isMajority = ruleSet == GameRuleSet.majorityWins;

    List<int> counts = [];
    if (isStandard) {
      counts = [1, 2];
    } else if (isUltimate) {
      counts = [9];
    } else if (isMajority) {
      counts = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    }

    final int selectedCount = counts.isEmpty ? 1 : settings.boardCount.clamp(counts.first, counts.last);

    return _buildDropdown<int>(
      context: context,
      label: 'Boards',
      value: selectedCount,
      items: counts,
      theme: theme,
      onChanged: isUltimate
          ? null
          : (int? value) {
              if (value != null) {
                settings.setBoardCount(value);
              }
            },
      itemBuilder: (int count) {
        return DropdownMenuItem<int>(
          value: count,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              count.toString(),
              style: TextStyle(
                color: theme.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?>? onChanged,
    required DropdownMenuItem<T> Function(T item) itemBuilder,
    required AppTheme theme,
  }) {
    final bool isRushingWind = theme.name == 'Rushing Wind';

    final Widget content = Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: theme.textColor.withValues(alpha: 0.85),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, color: theme.mainColor, size: 20),
                dropdownColor: theme.boardBg,
                alignment: Alignment.centerRight,
                borderRadius: BorderRadius.circular(12),
                items: items.map(itemBuilder).toList(),
                onChanged: onChanged,
                style: TextStyle(
                  color: theme.textColor,
                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (isRushingWind) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBg.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.textColor.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        child: content,
      );
    }

    return content;
  }
}
