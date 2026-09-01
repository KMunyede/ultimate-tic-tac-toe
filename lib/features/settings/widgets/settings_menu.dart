import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/audio/sound_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/animations/ocean_float.dart';
import '../../../widgets/gradient_button.dart';
import '../../game/screens/animation_demo_screen.dart';
import '../logic/settings_controller.dart';
import 'setting_row.dart';
import 'setting_toggles.dart';

class SettingsMenu extends StatefulWidget {
  final bool isPersistent;

  const SettingsMenu({super.key, this.isPersistent = false});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
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
            child: Text('Settings',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          Expanded(
              child:
                  _buildSettingsList(context, settings, soundManager, theme)),
        ],
      );
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isLandscape = screenWidth > screenHeight;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 40.0 : 20.0,
          vertical: isLandscape ? 12.0 : 24.0),
      child: _buildDialogFrame(context, settings, theme, soundManager,
          screenHeight, screenWidth, isLandscape),
    );
  }

  Widget _buildDialogFrame(
      BuildContext context,
      SettingsController settings,
      AppTheme theme,
      SoundManager soundManager,
      double h,
      double w,
      bool isLandscape) {
    final double dialogWidth = (w * 0.92).clamp(320.0, 560.0);
    final double maxDialogHeight = isLandscape ? h * 0.94 : h * 0.96;

    // CARTOON CONTRAST: Sharp black borders, high-contrast text
    final bool isPacific = theme.name == 'Pacific Waves';
    final Color dialogBg = isPacific ? theme.boardBg : theme.scaffoldBg;
    final Color headerTextColor = theme.textColor;
    final Color borderColor = Colors.black;

    return OceanFloat(
      drift: 4.0,
      swell: 6.0,
      rotation: 0.01,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        decoration: BoxDecoration(
          color: dialogBg.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 3.0),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(8, 8), blurRadius: 0)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Settings',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: headerTextColor,
                          letterSpacing: 1.2)),
                  IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: headerTextColor, size: 28),
                      onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Divider(
                height: 1,
                color: borderColor.withValues(alpha: 0.2),
                thickness: 2),
            Expanded(
                child:
                    _buildSettingsList(context, settings, soundManager, theme)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('DONE',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: theme.mainColor)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, SettingsController settings,
      SoundManager soundManager, AppTheme theme) {
    final Color labelColor = theme.textColor;
    final Color itemTextColor = theme.textColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          SettingRow<AppTheme>(
            label: 'Theme',
            value: settings.currentTheme,
            items: appThemes,
            theme: theme,
            onChanged: (t) => t != null ? settings.changeTheme(t) : null,
            itemBuilder: (t) => DropdownMenuItem(
                value: t,
                child: Text(t.name,
                    style: TextStyle(
                        color: itemTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700))),
          ),
          SettingRow<GameRuleSet>(
            label: 'Rule Set',
            value: settings.ruleSet,
            items: GameRuleSet.values,
            theme: theme,
            onChanged: (r) => r != null ? settings.setRuleSet(r) : null,
            itemBuilder: (r) => DropdownMenuItem(
                value: r,
                child: Text(r.displayName,
                    style: TextStyle(
                        color: itemTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700))),
          ),
          SettingRow<GameMode>(
            label: 'Game Mode',
            value: settings.gameMode,
            items: GameMode.values,
            theme: theme,
            onChanged: (m) => m != null ? settings.setGameMode(m) : null,
            itemBuilder: (m) => DropdownMenuItem(
                value: m,
                child: Text(m.displayName,
                    style: TextStyle(
                        color: itemTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700))),
          ),
          if (settings.gameMode == GameMode.playerVsAi)
            SettingRow<AiDifficulty>(
              label: 'AI Difficulty',
              value: settings.aiDifficulty,
              items: AiDifficulty.values,
              theme: theme,
              onChanged: (d) => d != null ? settings.setAiDifficulty(d) : null,
              itemBuilder: (d) => DropdownMenuItem(
                  value: d,
                  child: Text(d.displayName,
                      style: TextStyle(
                          color: itemTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700))),
            ),
          _buildBoardCountRow(settings, theme),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconToggle(
                icon: settings.isSoundOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                label: 'Sound',
                isActive: settings.isSoundOn,
                theme: theme,
                onTap: () {
                  settings.toggleSound();
                  if (settings.isSoundOn) soundManager.playMoveSound();
                },
              ),
              IconToggle(
                icon: settings.lowDetailMode
                    ? Icons.bolt_rounded
                    : Icons.offline_bolt_outlined,
                label: 'Lite Mode',
                isActive: settings.lowDetailMode,
                theme: theme,
                onTap: () => settings.setLowDetailMode(!settings.lowDetailMode),
              ),
              IconToggle(
                icon: settings.useOnlineAi
                    ? Icons.cloud_queue_rounded
                    : Icons.cloud_off_rounded,
                label: 'Online AI',
                isActive: settings.useOnlineAi,
                theme: theme,
                onTap: () => settings.setUseOnlineAi(!settings.useOnlineAi),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (!widget.isPersistent) Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AnimationDemoScreen()));
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 2),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    foregroundColor: labelColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon:
                      Icon(Icons.palette_outlined, size: 18, color: labelColor),
                  label: Text('Graphics Lab',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: labelColor)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final Color btnTextColor = theme.mainColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
                    return GradientButton(
                      onPressed: () {
                        settings.resetGameAndScores();
                        if (!widget.isPersistent) Navigator.pop(context);
                      },
                      gradient: LinearGradient(colors: [
                        theme.mainColor,
                        theme.mainColor.withValues(alpha: 0.8)
                      ]),
                      textColor: btnTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('Reset Match',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: btnTextColor)),
                    );
                  }
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoardCountRow(SettingsController settings, AppTheme theme) {
    final ruleSet = settings.ruleSet;
    final Color itemTextColor = theme.textColor;

    List<int> counts = ruleSet == GameRuleSet.standard
        ? [1, 2]
        : (ruleSet == GameRuleSet.ultimate ? [9] : [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    return SettingRow<int>(
      label: 'Board Count',
      value: settings.boardCount.clamp(counts.first, counts.last),
      items: counts,
      theme: theme,
      onChanged: ruleSet == GameRuleSet.ultimate
          ? null
          : (v) => v != null ? settings.setBoardCount(v) : null,
      itemBuilder: (v) => DropdownMenuItem(
          value: v,
          child: Text(v.toString(),
              style: TextStyle(
                  color: itemTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700))),
    );
  }
}
