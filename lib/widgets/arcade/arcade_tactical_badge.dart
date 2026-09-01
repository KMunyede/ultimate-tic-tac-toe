// lib/widgets/arcade/arcade_tactical_badge.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/game/logic/game_controller.dart';
import '../../features/settings/logic/settings_controller.dart';
import '../../models/player.dart';
import '../../services/stats_service.dart';
import '../../utils/responsive_layout.dart';

class TacticalTelemetryBadge extends StatelessWidget {
  const TacticalTelemetryBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final statsService = context.watch<StatsService>();
    
    final currentTheme = settings.currentTheme;
    final isLight = currentTheme.brightness == Brightness.light;
    final res = ResponsiveLayout(context);

    final isCandy = currentTheme.name.contains('Candy Meadow');
    final isWood = currentTheme.name.contains('Woodville Carve');

    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;

    final currentStats = statsService.stats;
    final int totalXp = isGuest ? 0 : currentStats.totalXp;
    
    final int level = isGuest ? 1 : ((totalXp / 500).floor() + 1);
    final int xpInLevel = isGuest ? 0 : (totalXp % 500);
    final double xpProgress = isGuest ? 0.0 : ((xpInLevel / 500.0).clamp(0.0, 1.0));

    String suggestion = isGuest ? "SIGN UP TO SAVE YOUR LEVEL & STATS" : "READY PLAYER ONE • PLAN YOUR NEXT MOVE";
    Color telemetryColor = isGuest
        ? (isLight ? const Color(0xFFD84315) : const Color(0xFFFF7043))
        : (isLight ? const Color(0xFFE65100) : const Color(0xFFFFB300));

    if (game.isOverallGameOver) {
      suggestion = "GAME OVER • GREAT MATCH!";
      telemetryColor = isLight ? Colors.green.shade700 : Colors.greenAccent;
    } else if (game.isAiThinking) {
      suggestion = "THE COMPUTER IS PLANNING A MOVE...";
      telemetryColor = isLight ? Colors.purple.shade700 : Colors.purpleAccent;
    } else if (game.currentPlayer == Player.O) {
      suggestion = "WAITING FOR OPPONENT'S TURN...";
      telemetryColor = isLight ? Colors.red.shade700 : Colors.redAccent;
    } else if (!isGuest) {
      bool boardThreat = false;
      int forcedIdx = game.forcedBoardIndex ?? -1;
      if (forcedIdx != -1 && forcedIdx < game.boards.length && !game.boards[forcedIdx].isGameOver) {
        if (game.boards[forcedIdx].hasThreat(Player.O)) {
          suggestion = "CAREFUL • OPPONENT MIGHT WIN BOARD ${forcedIdx + 1}!";
          telemetryColor = isLight ? Colors.red.shade700 : Colors.redAccent;
          boardThreat = true;
        }
      }
      if (!boardThreat) {
        if (settings.ruleSet == GameRuleSet.ultimate && forcedIdx != -1) {
          suggestion = "NOTICE • YOU MUST PLAY ON BOARD ${forcedIdx + 1}";
        } else if (settings.ruleSet == GameRuleSet.chaos && (game.shieldCardsX > 0 || game.eraserCardsX > 0)) {
          suggestion = "POWER-UP AVAILABLE • USE A CARD NOW!";
          telemetryColor = isLight ? Colors.blue.shade700 : Colors.cyanAccent;
        } else {
          suggestion = "YOUR TURN • TAP ANY OPEN CELL TO PLAY!";
        }
      }
    }

    final double width = res.isLessThan7Inch ? 230.0 : 280.0;
    final double titleFontSize = res.isLessThan7Inch ? 8.0 : 9.5;
    final double progressHeight = res.isLessThan7Inch ? 4.0 : 6.0;

    final BoxDecoration containerDeco = isCandy
        ? BoxDecoration(
            color: const Color(0xFFF5F5DC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD7CCC8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : (isWood
            ? BoxDecoration(
                color: const Color(0xFF3E2723).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF271510), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : BoxDecoration(
                color: isLight ? Colors.white.withValues(alpha: 0.2) : currentTheme.scaffoldBg.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: currentTheme.mainColor.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.mainColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: containerDeco,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isGuest ? 'GUEST MODE (STATS LOCKED)' : 'LVL $level PROGRESSION',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                      color: isGuest
                          ? (isLight ? const Color(0xFFD84315) : const Color(0xFFFF7043))
                          : (isCandy
                              ? const Color(0xFF5D4037)
                              : (isWood ? const Color(0xFFFFB74D) : currentTheme.textColor.withValues(alpha: 0.7))),
                    ),
                  ),
                  Text(
                    '$xpInLevel/500 XP',
                    style: TextStyle(
                      fontSize: titleFontSize - 1.0,
                      fontWeight: FontWeight.w900,
                      color: isCandy
                          ? const Color(0xFF8D6E63)
                          : (isWood ? const Color(0xFFFFB74D).withValues(alpha: 0.8) : currentTheme.textColor.withValues(alpha: 0.5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                height: progressHeight,
                decoration: BoxDecoration(
                  color: isCandy || isWood
                      ? Colors.black12
                      : currentTheme.textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: xpProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCandy
                            ? [const Color(0xFFFF4081), const Color(0xFFFF80AB)]
                            : (isWood
                                ? [const Color(0xFFFFB300), const Color(0xFFFFE082)]
                                : [currentTheme.mainColor, currentTheme.accentGlow]),
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isLight ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isCandy || isWood ? Colors.black12 : (isLight ? Colors.black.withValues(alpha: 0.05) : Colors.white10),
                  ),
                ),
                child: Row(
                  children: [
                    _LiveBeacon(color: telemetryColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          fontSize: titleFontSize - 1.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: telemetryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

class _LiveBeacon extends StatefulWidget {
  final Color color;
  const _LiveBeacon({required this.color});

  @override
  State<_LiveBeacon> createState() => _LiveBeaconState();
}

class _LiveBeaconState extends State<_LiveBeacon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.6),
                  blurRadius: 3,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
