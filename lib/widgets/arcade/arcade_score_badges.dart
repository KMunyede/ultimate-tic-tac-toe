// lib/widgets/arcade/arcade_score_badges.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/game/logic/game_controller.dart';
import '../../features/settings/logic/settings_controller.dart';
import '../../models/player.dart';
import '../../utils/responsive_layout.dart';
import 'common_arcade_widgets.dart';
import 'arcade_misc_widgets.dart';

class PlayerXScoreBadge extends StatelessWidget {
  const PlayerXScoreBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    final isCandy = currentTheme.name.contains('Candy Meadow');
    final isWood = currentTheme.name.contains('Woodville Carve');

    final isActive = game.currentPlayer == Player.X && !game.isOverallGameOver;
    final dullCrimson = isLight ? const Color(0xFFB71C1C) : currentTheme.colorX;

    String padScore(int score) {
      return (score * 100).toString().padLeft(6, '0');
    }

    final double width = res.isLessThan7Inch ? 110.0 : (res.is7To8Inch ? 122.0 : (res.is8To10Inch ? 135.0 : 145.0));
    final double paddingHorizontal = res.isLessThan7Inch ? 6.0 : 10.0;
    final double paddingVertical = res.isLessThan7Inch ? 4.0 : 6.0;
    final double blinkLabelFontSize = res.isLessThan7Inch ? 8.0 : 9.5;
    final double scoreFontSize = res.isLessThan7Inch ? 11.0 : 13.0;
    final double boardsWonFontSize = res.isLessThan7Inch ? 6.5 : 7.0;

    final BoxDecoration containerDeco = isCandy
        ? BoxDecoration(
            color: const Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? const Color(0xFFFFB74D) : const Color(0xFF5D4037),
              width: isActive ? 2.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : (isWood
            ? BoxDecoration(
                color: const Color(0xFF4E342E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? const Color(0xFFFFB300) : const Color(0xFF3E2723),
                  width: isActive ? 2.0 : 1.0,
                ),
              )
            : BoxDecoration(
                color: isLight ? Colors.white.withValues(alpha: 0.15) : currentTheme.scaffoldBg.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(
                  color: isActive ? dullCrimson.withValues(alpha: 0.8) : dullCrimson.withValues(alpha: 0.25),
                  width: isActive ? 2.0 : 1.2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: dullCrimson.withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : [],
              ));

    return ClipRRect(
      borderRadius: isCandy || isWood
          ? BorderRadius.circular(14)
          : const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
          decoration: containerDeco,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCandy) ...[
                    const LadybugIcon(size: 11),
                    const SizedBox(width: 4),
                  ],
                  BlinkingLabel(
                    label: isCandy ? 'LADYBUG' : (isWood ? 'SLATE X' : '1UP (X)'),
                    active: isActive,
                    color: isCandy
                        ? (isActive ? Colors.redAccent.shade100 : Colors.grey.shade400)
                        : (isWood
                            ? (isActive ? const Color(0xFFFFB300) : Colors.grey.shade500)
                            : (isActive ? dullCrimson : currentTheme.textColor.withValues(alpha: 0.45))),
                    fontSize: blinkLabelFontSize,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  padScore(game.sessionWinsX),
                  style: TextStyle(
                    fontSize: scoreFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: isActive ? dullCrimson : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'BOARDS: ${game.boardsWonX}',
                style: TextStyle(
                  fontSize: boardsWonFontSize,
                  fontWeight: FontWeight.w900,
                  color: isLight ? currentTheme.textColor.withValues(alpha: 0.6) : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayerOScoreBadge extends StatelessWidget {
  const PlayerOScoreBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    final isCandy = currentTheme.name.contains('Candy Meadow');
    final isWood = currentTheme.name.contains('Woodville Carve');

    final isActive = game.currentPlayer == Player.O && !game.isOverallGameOver;
    final neonCyan = isLight ? const Color(0xFF0D47A1) : const Color(0xFF00FFCC);

    String padScore(int score) {
      return (score * 100).toString().padLeft(6, '0');
    }

    final double width = res.isLessThan7Inch ? 110.0 : (res.is7To8Inch ? 122.0 : (res.is8To10Inch ? 135.0 : 145.0));
    final double paddingHorizontal = res.isLessThan7Inch ? 6.0 : 10.0;
    final double paddingVertical = res.isLessThan7Inch ? 4.0 : 6.0;
    final double blinkLabelFontSize = res.isLessThan7Inch ? 8.0 : 9.5;
    final double scoreFontSize = res.isLessThan7Inch ? 11.0 : 13.0;
    final double boardsWonFontSize = res.isLessThan7Inch ? 6.5 : 7.0;

    final BoxDecoration containerDeco = isCandy
        ? BoxDecoration(
            color: const Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? const Color(0xFFFFB74D) : const Color(0xFF5D4037),
              width: isActive ? 2.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : (isWood
            ? BoxDecoration(
                color: const Color(0xFF4E342E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? const Color(0xFFFFB300) : const Color(0xFF3E2723),
                  width: isActive ? 2.0 : 1.0,
                ),
              )
            : BoxDecoration(
                color: isLight ? Colors.white.withValues(alpha: 0.15) : currentTheme.scaffoldBg.withValues(alpha: 0.25),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  topLeft: Radius.circular(6),
                  bottomLeft: Radius.circular(6),
                ),
                border: Border.all(
                  color: isActive ? neonCyan.withValues(alpha: 0.8) : neonCyan.withValues(alpha: 0.25),
                  width: isActive ? 2.0 : 1.2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: neonCyan.withValues(alpha: 0.15),
                          blurRadius: 8,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : [],
              ));

    return ClipRRect(
      borderRadius: isCandy || isWood
          ? BorderRadius.circular(14)
          : const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
          decoration: containerDeco,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCandy) ...[
                    const DonutIcon(size: 11),
                    const SizedBox(width: 4),
                  ],
                  BlinkingLabel(
                    label: isCandy ? 'DONUT' : (isWood ? 'STONE O' : '2UP (O)'),
                    active: isActive,
                    color: isCandy
                        ? (isActive ? Colors.blueAccent.shade100 : Colors.grey.shade400)
                        : (isWood
                            ? (isActive ? const Color(0xFFFFB300) : Colors.grey.shade500)
                            : (isActive ? neonCyan : currentTheme.textColor.withValues(alpha: 0.45))),
                    fontSize: blinkLabelFontSize,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  padScore(game.sessionWinsO),
                  style: TextStyle(
                    fontSize: scoreFontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: isActive ? neonCyan : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'BOARDS: ${game.boardsWonO}',
                style: TextStyle(
                  fontSize: boardsWonFontSize,
                  fontWeight: FontWeight.w900,
                  color: isLight ? currentTheme.textColor.withValues(alpha: 0.6) : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HighScoreBadge extends StatelessWidget {
  const HighScoreBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);
    final isCandy = currentTheme.name.contains('Candy Meadow');
    final isWood = currentTheme.name.contains('Woodville Carve');

    final double width = res.isLessThan7Inch ? 100.0 : (res.is7To8Inch ? 110.0 : (res.is8To10Inch ? 120.0 : 130.0));
    final double paddingHorizontal = res.isLessThan7Inch ? 6.0 : 8.0;
    final double paddingVertical = res.isLessThan7Inch ? 4.0 : 6.0;

    final BoxDecoration containerDeco = isCandy
        ? BoxDecoration(
            color: const Color(0xFF8D6E63),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF5D4037), width: 1.2),
          )
        : (isWood
            ? BoxDecoration(
                color: const Color(0xFF4E342E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF3E2723), width: 1.0),
              )
            : BoxDecoration(
                color: isLight ? Colors.white.withValues(alpha: 0.15) : currentTheme.scaffoldBg.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isLight ? Colors.black12 : Colors.white12,
                  width: 1.2,
                ),
              ));

    return ClipRRect(
      borderRadius: BorderRadius.circular(isCandy || isWood ? 14 : 8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: width,
          padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
          decoration: containerDeco,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HIGH SCORE',
                style: TextStyle(
                  fontSize: res.isLessThan7Inch ? 7.5 : 8.5,
                  fontWeight: FontWeight.w900,
                  color: isCandy || isWood ? const Color(0xFFFFD54F) : Colors.amber.shade600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '999990',
                style: TextStyle(
                  fontSize: res.isLessThan7Inch ? 10.0 : 12.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: isLight ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCandy ? 'SWEETEST' : (isWood ? 'CARVED V1' : 'V2 CABINET'),
                style: TextStyle(
                  fontSize: res.isLessThan7Inch ? 6.0 : 7.0,
                  fontWeight: FontWeight.w900,
                  color: isLight ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
