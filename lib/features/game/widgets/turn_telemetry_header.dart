// lib/features/game/widgets/turn_telemetry_header.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import '../logic/game_controller.dart';
import '../../settings/logic/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/player.dart';
import 'mini_turn_board.dart';
import '../../../widgets/board/clay_bevel_painter.dart';

import 'dart:math';

class TurnTelemetryHeader extends StatefulWidget {
  final GameController game;
  final SettingsController settings;

  const TurnTelemetryHeader({
    super.key,
    required this.game,
    required this.settings,
  });

  @override
  State<TurnTelemetryHeader> createState() => _TurnTelemetryHeaderState();
}

class _TurnTelemetryHeaderState extends State<TurnTelemetryHeader> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.settings.currentTheme;
    final activePlayer = widget.game.currentPlayer;
    final isThinking = widget.game.isAiThinking;
    
    // Theme-specific styles matching FloatingCloudButton
    BorderRadius headerRadius = BorderRadius.circular(20.0);
    Decoration headerDec;
    Color contentColor = theme.mainColor;

    if (theme.name == 'Rushing Wind') {
      headerRadius = BorderRadius.circular(20.0);
      headerDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: headerRadius,
        boxShadow: [
          BoxShadow(
            color: NeumorphicColors.getDarkShadow(theme.boardBg),
            offset: const Offset(3, 3),
            blurRadius: 8,
          ),
          BoxShadow(
            color: NeumorphicColors.getLightShadow(theme.boardBg),
            offset: const Offset(-3, -3),
            blurRadius: 8,
          ),
        ],
      );
    } else if (theme.name == 'Amazon Jungle') {
      // Mahogany bark wood card with warm gold trim
      headerRadius = BorderRadius.circular(14.0);
      headerDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: headerRadius,
        border: Border.all(color: theme.accentGlow.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 8.0,
          ),
        ],
      );
    } else if (theme.name == 'Pacific Waves') {
      headerRadius = BorderRadius.circular(20.0);
      headerDec = BoxDecoration(
        color: theme.mainColor.withValues(alpha: 0.25),
        borderRadius: headerRadius,
        border: Border.all(color: theme.accentGlow.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: theme.mainColor.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      );
      contentColor = theme.textColor;
    } else if (theme.name == 'Drifting Cloud') {
      headerRadius = BorderRadius.circular(8.0);
      headerDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: headerRadius,
        border: Border.all(color: theme.textColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: theme.textColor,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      );
    } else if (theme.name == 'Crimson Leaf') {
      headerRadius = BorderRadius.circular(12.0);
      headerDec = BoxDecoration(
        color: theme.mainColor,
        borderRadius: headerRadius,
        border: Border.all(color: theme.accentGlow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
      contentColor = theme.accentGlow;
    } else {
      headerDec = BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: headerRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 10),
            blurRadius: 18.0,
          ),
        ],
      );
    }

    Widget headerBody = Container(
      decoration: headerDec,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        children: [
          // 1. MiniTurnBoard
          MiniTurnBoard(
            player: activePlayer,
            isThinking: isThinking,
            theme: theme,
          ),
          const SizedBox(width: 14.0),
          // 2. Active Player / AI Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isThinking ? "AI THINKING" : "ACTIVE PLAYER",
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: contentColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  isThinking 
                      ? "Thinking of a clever move..." 
                      : (widget.settings.gameMode == GameMode.playerVsAi && activePlayer == Player.O
                          ? "AI Turn (O)"
                          : "Player ${activePlayer == Player.X ? "X" : "O"}'s Turn"),
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: contentColor,
                  ),
                ),
              ],
            ),
          ),
          if (widget.game.boards.length == 9) ...[
            const SizedBox(width: 10),
            _MiniUltimate3x3GridNav(
              game: widget.game,
              settings: widget.settings,
              contentColor: contentColor,
            ),
          ],
        ],
      ),
    );

    if (theme.name == 'Pacific Waves') {
      headerBody = ClipRRect(
        borderRadius: headerRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: headerBody,
        ),
      );
    } else if (theme.name == 'Rushing Wind') {
      headerBody = CustomPaint(
        painter: ClayBevelPainter(
          borderRadius: 20.0,
          baseColor: theme.boardBg,
          themeName: theme.name,
        ),
        child: headerBody,
      );
    }

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final double angle = _floatController.value * 2 * pi;
        final double dx = cos(angle * 0.8) * 6.0;
        final double dy = sin(angle) * 8.0;
        final double rotation = sin(angle * 0.4) * 0.015;
        
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rotation,
            child: child,
          ),
        );
      },
      child: headerBody,
    );
  }
}

class _MiniUltimate3x3GridNav extends StatelessWidget {
  final GameController game;
  final SettingsController settings;
  final Color contentColor;

  const _MiniUltimate3x3GridNav({
    required this.game,
    required this.settings,
    required this.contentColor,
  });

  static String _getBoardLocationName(int? index) {
    if (index == null) return "ANY BOARD";
    switch (index) {
      case 0: return "TOP-LEFT";
      case 1: return "TOP-CENTER";
      case 2: return "TOP-RIGHT";
      case 3: return "MID-LEFT";
      case 4: return "CENTER";
      case 5: return "MID-RIGHT";
      case 6: return "BOT-LEFT";
      case 7: return "BOT-CENTER";
      case 8: return "BOT-RIGHT";
      default: return "BOARD ${index + 1}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = settings.currentTheme;
    final forcedIdx = game.forcedBoardIndex;
    final boards = game.boards;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: forcedIdx != null ? Colors.yellowAccent : contentColor.withValues(alpha: 0.3),
          width: forcedIdx != null ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3x3 Mini Grid Diagram
          SizedBox(
            width: 36,
            height: 36,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 9,
              itemBuilder: (context, i) {
                final board = i < boards.length ? boards[i] : null;
                final isForced = forcedIdx == i;
                final isGameOver = board?.isGameOver ?? false;
                final winner = board?.winner;

                Color cellBg = Colors.white.withValues(alpha: 0.1);
                Widget? symbol;

                if (winner == Player.X) {
                  cellBg = theme.colorX.withValues(alpha: 0.4);
                  symbol = Text('X', style: TextStyle(color: theme.colorX, fontSize: 8, fontWeight: FontWeight.bold));
                } else if (winner == Player.O) {
                  cellBg = theme.colorO.withValues(alpha: 0.4);
                  symbol = Text('O', style: TextStyle(color: theme.colorO, fontSize: 8, fontWeight: FontWeight.bold));
                } else if (isGameOver) {
                  cellBg = Colors.grey.withValues(alpha: 0.3);
                } else if (isForced) {
                  cellBg = Colors.yellowAccent;
                } else if (forcedIdx == null && !isGameOver) {
                  cellBg = Colors.white.withValues(alpha: 0.25);
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(2),
                    border: isForced
                        ? Border.all(color: Colors.orangeAccent, width: 1.0)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: symbol,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Forced Navigation Location Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "FORCED GRID",
                style: TextStyle(
                  fontSize: 8.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: forcedIdx != null ? Colors.yellowAccent : contentColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 1.0),
              Text(
                _getBoardLocationName(forcedIdx),
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w900,
                  color: forcedIdx != null ? Colors.yellowAccent : contentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
