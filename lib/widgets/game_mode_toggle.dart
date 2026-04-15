import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/settings/logic/settings_controller.dart';
import '../models/game_enums.dart';
import '../utils/responsive_layout.dart';

class GameModeToggle extends StatelessWidget {
  const GameModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);
    final res = ResponsiveLayout(context);

    // Header label common to both layouts
    Widget header = Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        'GAME MODE',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontSize: 10,
        ),
      ),
    );

    if (res.isSmallLandscape) {
      return Container(
        // Match the sidebar width exactly by using double.infinity within the sidebar's constraints
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 4), // Minimal padding to maximize button width
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            _StackedModeButton(
              label: 'PLAYER VS PLAYER',
              isSelected: settings.gameMode == GameMode.playerVsPlayer,
              onTap: () => settings.setGameMode(GameMode.playerVsPlayer),
              icon: Icons.people,
              theme: theme,
            ),
            const SizedBox(height: 6),
            _StackedModeButton(
              label: 'PLAYER VS AI',
              isSelected: settings.gameMode == GameMode.playerVsAi,
              onTap: () => settings.setGameMode(GameMode.playerVsAi),
              icon: Icons.smart_toy,
              theme: theme,
            ),
            if (settings.gameMode == GameMode.playerVsAi) ...[
              const SizedBox(height: 8),
              _OnlineAiToggle(settings: settings, theme: theme, isCompact: true),
            ],
          ],
        ),
      );
    }

    // Standard Horizontal Segmented Layout
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          SegmentedButton<GameMode>(
            segments: const [
              ButtonSegment<GameMode>(
                value: GameMode.playerVsPlayer,
                label: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('PLAYER VS PLAYER'),
                ),
                icon: Icon(Icons.people, size: 16),
              ),
              ButtonSegment<GameMode>(
                value: GameMode.playerVsAi,
                label: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('PLAYER VS AI'),
                ),
                icon: Icon(Icons.smart_toy, size: 16),
              ),
            ],
            selected: {settings.gameMode},
            onSelectionChanged: (Set<GameMode> newSelection) {
              settings.setGameMode(newSelection.first);
            },
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              selectedBackgroundColor: theme.colorScheme.primaryContainer,
              selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (settings.gameMode == GameMode.playerVsAi) ...[
            const SizedBox(height: 12),
            _OnlineAiToggle(settings: settings, theme: theme, isCompact: false),
          ],
        ],
      ),
    );
  }
}

class _OnlineAiToggle extends StatelessWidget {
  final SettingsController settings;
  final ThemeData theme;
  final bool isCompact;

  const _OnlineAiToggle({
    required this.settings,
    required this.theme,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: settings.useOnlineAi 
              ? theme.colorScheme.primary.withValues(alpha: 0.3) 
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            settings.useOnlineAi ? Icons.cloud_done : Icons.cloud_off,
            size: isCompact ? 14 : 18,
            color: settings.useOnlineAi ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: isCompact ? 6 : 8),
          Flexible(
            child: Text(
              'PLAY VS ONLINE AI',
              style: TextStyle(
                fontSize: isCompact ? 8 : 10,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 4 : 8),
          Transform.scale(
            scale: isCompact ? 0.7 : 0.85,
            child: Switch(
              value: settings.useOnlineAi,
              onChanged: (val) => settings.setUseOnlineAi(val),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final ThemeData theme;

  const _StackedModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: isSelected ? 2 : 0,
          backgroundColor: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
          foregroundColor: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
