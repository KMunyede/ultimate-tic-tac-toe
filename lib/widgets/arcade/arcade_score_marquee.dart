// lib/widgets/arcade/arcade_score_marquee.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/game/logic/game_controller.dart';
import '../../features/settings/logic/settings_controller.dart';
import '../../models/player.dart';
import 'common_arcade_widgets.dart';

class ArcadeScoreMarquee extends StatelessWidget {
  const ArcadeScoreMarquee({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;

    String padScore(int score) {
      return (score * 100).toString().padLeft(6, '0');
    }

    final scoreboardBg = isLight
        ? Colors.white.withValues(alpha: 0.45)
        : currentTheme.scaffoldBg.withValues(alpha: 0.35);
    final scoreboardBorderColor = isLight
        ? currentTheme.mainColor.withValues(alpha: 0.20)
        : currentTheme.accentGlow.withValues(alpha: 0.45);
    final scoreboardGlowColor = isLight
        ? currentTheme.mainColor.withValues(alpha: 0.05)
        : currentTheme.accentGlow.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scoreboardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scoreboardBorderColor,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: scoreboardGlowColor,
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLedColumn(
            context: context,
            currentTheme: currentTheme,
            label: '1UP (X)',
            score: padScore(game.sessionWinsX),
            subLabel: 'BOARDS: ${game.boardsWonX}',
            active: game.currentPlayer == Player.X && !game.isOverallGameOver,
            glowColor: Colors.red.shade600,
          ),
          
          _buildLedColumn(
            context: context,
            currentTheme: currentTheme,
            label: 'HIGH SCORE',
            score: '999990',
            subLabel: 'V2 CABINET',
            active: false,
            glowColor: Colors.amber.shade600,
          ),

          _buildLedColumn(
            context: context,
            currentTheme: currentTheme,
            label: '2UP (O)',
            score: padScore(game.sessionWinsO),
            subLabel: 'BOARDS: ${game.boardsWonO}',
            active: game.currentPlayer == Player.O && !game.isOverallGameOver,
            glowColor: const Color(0xFF0D47A1),
          ),
        ],
      ),
    );
  }

  Widget _buildLedColumn({
    required BuildContext context,
    required AppTheme currentTheme,
    required String label,
    required String score,
    required String subLabel,
    required bool active,
    required Color glowColor,
  }) {
    final isLight = currentTheme.brightness == Brightness.light;

    Color getActiveColor(Color baseNeon) {
      if (!isLight) return baseNeon;
      if (baseNeon == Colors.red.shade600) {
        return const Color(0xFFB71C1C);
      }
      if (baseNeon == const Color(0xFF0D47A1) || baseNeon == Colors.blue.shade600) {
        return const Color(0xFF0D47A1);
      }
      if (baseNeon == Colors.amber.shade600) {
        return const Color(0xFFE65100);
      }
      return currentTheme.textColor;
    }

    final displayColor = getActiveColor(glowColor);
    final activeTextColor = active 
        ? displayColor 
        : (isLight ? currentTheme.textColor.withValues(alpha: 0.45) : Colors.grey.shade500);

    return Expanded(
      child: Column(
        children: [
          BlinkingLabel(
            label: label,
            active: active,
            color: activeTextColor,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isLight ? Colors.white.withValues(alpha: 0.95) : Colors.black,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isLight 
                    ? currentTheme.mainColor.withValues(alpha: 0.15) 
                    : Colors.white10,
              ),
            ),
            child: Text(
              score,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: displayColor,
                shadows: isLight
                    ? []
                    : [
                        Shadow(
                          color: displayColor.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              color: isLight ? currentTheme.textColor.withValues(alpha: 0.6) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
