import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/logic/settings_controller.dart';
import '../utils/responsive_layout.dart';

class GameModeToggle extends StatelessWidget {
  const GameModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    // Accent colors based on current theme highlight, lerped with neutral slate for tactical dull tones
    final baseGlowColor = isLight ? currentTheme.mainColor : currentTheme.accentGlow;
    final activeGlowColor = Color.lerp(
      baseGlowColor,
      isLight ? Colors.grey.shade500 : Colors.grey.shade700,
      0.35,
    )!;
    final glassBgColor = isLight
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.25);
    final glassBorderColor = isLight
        ? currentTheme.mainColor.withValues(alpha: 0.20)
        : currentTheme.accentGlow.withValues(alpha: 0.35);

    // Header label common to both layouts
    Widget header = res.isLandscape
        ? Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'GAME MODE',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isLight
                    ? currentTheme.textColor.withValues(alpha: 0.7)
                    : currentTheme.textColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 9,
                shadows: isLight
                    ? []
                    : [
                        Shadow(
                          color: activeGlowColor.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
              ),
            ),
          )
        : const SizedBox.shrink();

    // Use Stacked layout for all Landscape sidebars (Phone and Tablet) to match layout
    if (res.isLandscape && res.deviceType != DeviceType.desktop) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: glassBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: glassBorderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeGlowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                _CustomTabButton(
                  label: 'PLAYER VS PLAYER',
                  isSelected: settings.gameMode == GameMode.playerVsPlayer,
                  onTap: () => settings.setGameMode(GameMode.playerVsPlayer),
                  icon: Icons.people,
                  currentTheme: currentTheme,
                  isStacked: true,
                ),
                const SizedBox(height: 8),
                _CustomTabButton(
                  label: 'PLAYER VS AI',
                  isSelected: settings.gameMode == GameMode.playerVsAi,
                  onTap: () => settings.setGameMode(GameMode.playerVsAi),
                  icon: Icons.smart_toy,
                  currentTheme: currentTheme,
                  isStacked: true,
                ),
                if (settings.gameMode == GameMode.playerVsAi) ...[
                  const SizedBox(height: 10),
                  _OnlineAiToggle(settings: settings, currentTheme: currentTheme, isCompact: true),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Standard Horizontal Segmented Layout in Portrait
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: glassBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: glassBorderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: activeGlowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              Row(
                children: [
                  Expanded(
                    child: _CustomTabButton(
                      label: 'PLAYER VS PLAYER',
                      isSelected: settings.gameMode == GameMode.playerVsPlayer,
                      onTap: () => settings.setGameMode(GameMode.playerVsPlayer),
                      icon: Icons.people,
                      currentTheme: currentTheme,
                      isStacked: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CustomTabButton(
                      label: 'PLAYER VS AI',
                      isSelected: settings.gameMode == GameMode.playerVsAi,
                      onTap: () => settings.setGameMode(GameMode.playerVsAi),
                      icon: Icons.smart_toy,
                      currentTheme: currentTheme,
                      isStacked: false,
                    ),
                  ),
                ],
              ),
              if (settings.gameMode == GameMode.playerVsAi) ...[
                const SizedBox(height: 10),
                _OnlineAiToggle(settings: settings, currentTheme: currentTheme, isCompact: false),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final AppTheme currentTheme;
  final bool isStacked;

  const _CustomTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.currentTheme,
    required this.isStacked,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = currentTheme.brightness == Brightness.light;
    final activeColor = isLight ? currentTheme.mainColor : currentTheme.accentGlow;
    final themeName = currentTheme.name;
    final isCandy = themeName.contains('Candy Meadow');
    final isWood = themeName.contains('Woodville Carve');

    Color buttonBg;
    Color buttonBorder;
    Color iconColor;
    Color textColor;
    List<BoxShadow> buttonShadow = [];

    if (isSelected) {
      iconColor = activeColor;
      if (isCandy) {
        // Ladybug Sugar Candy Meadow: tactile sweet-cream white card
        buttonBg = Colors.white;
        buttonBorder = currentTheme.mainColor.withValues(alpha: 0.50);
        textColor = currentTheme.textColor; // Rich cocoa brown
        buttonShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          )
        ];
      } else if (isWood) {
        // Woodville Carve: polished gold-carved mahogany wood plank
        buttonBg = const Color(0xFFD84315).withValues(alpha: 0.35);
        buttonBorder = const Color(0xFFFFB300);
        textColor = const Color(0xFFFFE0B2); // light amber text
        buttonShadow = [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.15),
            blurRadius: 6,
          )
        ];
      } else {
        // Neon Cyberpulse: glowing cyber capsule
        buttonBg = currentTheme.mainColor.withValues(alpha: 0.20);
        buttonBorder = currentTheme.mainColor;
        textColor = Colors.white;
        buttonShadow = [
          BoxShadow(
            color: currentTheme.mainColor.withValues(alpha: 0.30),
            blurRadius: 8,
          )
        ];
      }
    } else {
      // Inactive states: transparent button with clean readable text
      buttonBg = Colors.transparent;
      buttonBorder = isLight 
          ? Colors.black.withValues(alpha: 0.08) 
          : Colors.white.withValues(alpha: 0.12);
      iconColor = isLight 
          ? currentTheme.textColor.withValues(alpha: 0.6) 
          : Colors.white.withValues(alpha: 0.55);
      textColor = isLight 
          ? currentTheme.textColor.withValues(alpha: 0.75) 
          : Colors.white.withValues(alpha: 0.65);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 32,
      decoration: BoxDecoration(
        color: buttonBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: buttonBorder,
          width: isSelected ? 1.8 : 1.2,
        ),
        boxShadow: buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: iconColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnlineAiToggle extends StatelessWidget {
  final SettingsController settings;
  final AppTheme currentTheme;
  final bool isCompact;

  const _OnlineAiToggle({
    required this.settings,
    required this.currentTheme,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = currentTheme.brightness == Brightness.light;
    final activeColor = isLight ? currentTheme.mainColor : currentTheme.accentGlow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: settings.useOnlineAi
              ? activeColor.withValues(alpha: 0.6)
              : (isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12)),
          width: 1.2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              settings.useOnlineAi ? Icons.cloud_done : Icons.cloud_off,
              size: isCompact ? 13 : 16,
              color: settings.useOnlineAi 
                  ? activeColor 
                  : (isLight ? currentTheme.textColor.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.5)),
            ),
            SizedBox(width: isCompact ? 6 : 8),
            Text(
              'PLAY VS ONLINE AI',
              style: TextStyle(
                fontSize: isCompact ? 8 : 9,
                fontWeight: FontWeight.w900,
                color: settings.useOnlineAi
                    ? (isLight ? currentTheme.textColor : Colors.white)
                    : (isLight ? currentTheme.textColor.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.55)),
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: isCompact ? 6 : 10),
            Transform.scale(
              scale: isCompact ? 0.7 : 0.82,
              child: Switch(
                value: settings.useOnlineAi,
                onChanged: (val) => settings.setUseOnlineAi(val),
                activeThumbColor: activeColor,
                activeTrackColor: activeColor.withValues(alpha: 0.35),
                inactiveThumbColor: isLight ? Colors.grey.shade400 : Colors.grey.shade600,
                inactiveTrackColor: isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
