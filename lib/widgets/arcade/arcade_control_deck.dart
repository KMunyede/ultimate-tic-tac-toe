// lib/widgets/arcade/arcade_control_deck.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/game/logic/game_controller.dart';
import '../../features/settings/logic/settings_controller.dart';
import 'arcade_push_button.dart';
import 'arcade_interactive_joystick.dart';
import 'arcade_misc_widgets.dart';

class ArcadeControlDeck extends StatelessWidget {
  final Widget? cardHandWidget;
  final VoidCallback onNewGame;
  final VoidCallback onHelp;
  final VoidCallback onSettings;

  const ArcadeControlDeck({
    super.key,
    required this.onNewGame,
    required this.onHelp,
    required this.onSettings,
    this.cardHandWidget,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    final themeName = activeTheme.name;
    final isLight = activeTheme.brightness == Brightness.light;

    final isCandy = themeName.contains('Candy Meadow');
    final isWood = themeName.contains('Woodville Carve');

    final deckGradientColors = isCandy
        ? [const Color(0xFF8D6E63), const Color(0xFF5D4037)]
        : (isWood
            ? [const Color(0xFF3E2723), const Color(0xFF271A15)]
            : [const Color(0xFF131317), const Color(0xFF070709)]);

    final deckBorderColor = isCandy
        ? const Color(0xFF5D4037).withValues(alpha: 0.5)
        : (isWood ? const Color(0xFF3E2723) : Colors.white10);

    final deckShadowColor = isLight
        ? activeTheme.textColor.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.5);

    final int boardsCount = game.boards.length;
    final double baseButtonSize;
    if (boardsCount <= 1) {
      baseButtonSize = 62.0;
    } else if (boardsCount <= 4) {
      baseButtonSize = 52.0;
    } else if (boardsCount <= 9) {
      baseButtonSize = 44.0;
    } else {
      baseButtonSize = 38.0;
    }

    final double startButtonSize = baseButtonSize * 1.15;
    final double otherButtonSize = baseButtonSize;
    
    final double joystickSize = boardsCount <= 1 
        ? 80.0 
        : (boardsCount <= 4 ? 70.0 : (boardsCount <= 9 ? 60.0 : 52.0));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: deckGradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: deckBorderColor,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: deckShadowColor,
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: ArcadeScrewWidget(isLight: isLight, size: 10.0),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: ArcadeScrewWidget(isLight: isLight, size: 10.0),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cardHandWidget != null) ...[
                      cardHandWidget!,
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InteractiveJoystickWidget(size: joystickSize),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ArcadePushButton(
                                label: 'SETTINGS',
                                actionText: 'SETTINGS',
                                buttonColor: isCandy 
                                    ? const Color(0xFF00B0FF) 
                                    : (isWood ? const Color(0xFF8D6E63) : Colors.blue.shade600),
                                size: otherButtonSize,
                                onTap: onSettings,
                              ),
                              ArcadePushButton(
                                label: 'PLAYER 1',
                                actionText: 'START',
                                buttonColor: isCandy 
                                    ? const Color(0xFFFF4081) 
                                    : (isWood ? const Color(0xFFD84315) : Colors.red.shade700),
                                size: startButtonSize,
                                onTap: onNewGame,
                              ),
                              ArcadePushButton(
                                label: 'HELP',
                                actionText: 'INFO',
                                buttonColor: isCandy 
                                    ? const Color(0xFFFFD54F) 
                                    : (isWood ? const Color(0xFFFFB300) : Colors.amber.shade600),
                                size: otherButtonSize,
                                onTap: onHelp,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const GlowingCoinSlotWidget(),
                        const SizedBox(width: 16),
                        Text(
                          'CREDIT 99',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: isLight ? Colors.grey.shade700 : Colors.amber.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
