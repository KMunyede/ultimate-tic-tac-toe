// lib/widgets/arcade/arcade_turn_marquee.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../features/game/logic/game_controller.dart';
import '../../features/settings/logic/settings_controller.dart';
import '../../models/player.dart';
import '../../utils/responsive_layout.dart';

class ArcadeTurnMarquee extends StatefulWidget {
  const ArcadeTurnMarquee({super.key});

  @override
  State<ArcadeTurnMarquee> createState() => _ArcadeTurnMarqueeState();
}

class _ArcadeTurnMarqueeState extends State<ArcadeTurnMarquee>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    final isLight = activeTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    final String statusText = _getTurnText(game, activeTheme);
    final Color color = _getTurnColor(game, activeTheme);

    final double fontSize = res.isLessThan7Inch ? 9.5 : 11.5;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isLight 
                  ? Colors.white.withValues(alpha: 0.15) 
                  : const Color(0xFF0C100B).withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: isLight
                  ? []
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: _pulseController.value * 0.7 + 0.3),
                        boxShadow: isLight
                            ? []
                            : [
                                BoxShadow(
                                  color: color.withValues(alpha: _pulseController.value * 0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1.5,
                                )
                              ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: color,
                    shadows: isLight
                        ? []
                        : [
                            Shadow(
                              color: color.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTurnText(GameController game, AppTheme theme) {
    final isCandy = theme.name.contains('Candy Meadow');
    final isWood = theme.name.contains('Woodville Carve');

    if (game.isOverallGameOver) {
      if (game.matchWinner != null) {
        final String winnerName = game.matchWinner == Player.X 
            ? (isCandy ? 'LADYBUGS' : (isWood ? 'SLATE X' : 'PLAYER X'))
            : (isCandy ? 'DONUTS' : (isWood ? 'STONE O' : 'PLAYER O'));
        return 'MATCH OVER • $winnerName WIN';
      }
      return 'MATCH OVER • DRAW MATCH';
    }
    if (game.isAiThinking) {
      return 'AI COMPUTER THINKING • STAND BY';
    }
    
    final String activePlayerName = game.currentPlayer == Player.X 
        ? (isCandy ? 'LADYBUG' : (isWood ? 'SLATE X' : 'PLAYER X'))
        : (isCandy ? 'DONUT' : (isWood ? 'STONE O' : 'PLAYER O'));
    return '$activePlayerName TURN • READY';
  }

  Color _getTurnColor(GameController game, AppTheme theme) {
    final isLight = theme.brightness == Brightness.light;
    if (game.isOverallGameOver) {
      return isLight ? const Color(0xFFE65100) : Colors.amber.shade500;
    }
    if (game.isAiThinking) {
      return isLight ? const Color(0xFF006064) : Colors.teal.shade400;
    }
    return game.currentPlayer == Player.X 
        ? (isLight ? const Color(0xFFB71C1C) : Colors.red.shade500) 
        : (isLight ? const Color(0xFF0D47A1) : const Color(0xFF00FFCC));
  }
}
