// lib/widgets/score_board.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/game/logic/game_controller.dart';
import '../models/player.dart';

class ScoreBoard extends StatelessWidget {
  final bool isSmallScreen;
  final bool isVertical;

  const ScoreBoard({
    super.key,
    required this.isSmallScreen,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isLandscape = screenWidth > screenHeight;
        final shortestSide = screenWidth < screenHeight ? screenWidth : screenHeight;
        final isMobileLandscape = isLandscape && shortestSide < 600;

        // More aggressive scale for mobile landscape to fit narrow sidebars
        double scale = isVertical ? 0.8 : (constraints.maxWidth / 500.0).clamp(0.6, 1.1);
        if (isMobileLandscape && isVertical) {
          scale = 0.65; // Scale down for phone landscape sidebars
        }
        
        final double horizontalPadding = (isMobileLandscape ? 4.0 : 12.0) * scale;

        Widget content;

        if (isVertical) {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScoreItem(
                label: 'PLAYER X',
                boardsWon: game.boardsWonX,
                sessionWins: game.sessionWinsX,
                color: Colors.red.shade800,
                isCurrent: game.currentPlayer == Player.X && !game.isOverallGameOver,
                scale: scale,
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8 * scale),
                child: _VSDivider(scale: scale),
              ),
              _ScoreItem(
                label: 'PLAYER O',
                boardsWon: game.boardsWonO,
                sessionWins: game.sessionWinsO,
                color: const Color(0xFF0D47A1),
                isCurrent: game.currentPlayer == Player.O && !game.isOverallGameOver,
                scale: scale,
              ),
            ],
          );
        } else {
          content = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 10,
                child: _ScoreItem(
                  label: 'PLAYER X',
                  boardsWon: game.boardsWonX,
                  sessionWins: game.sessionWinsX,
                  color: Colors.red.shade800,
                  isCurrent: game.currentPlayer == Player.X && !game.isOverallGameOver,
                  scale: scale,
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(child: _VSDivider(scale: scale)),
              ),
              Expanded(
                flex: 10,
                child: _ScoreItem(
                  label: 'PLAYER O',
                  boardsWon: game.boardsWonO,
                  sessionWins: game.sessionWinsO,
                  color: const Color(0xFF0D47A1),
                  isCurrent: game.currentPlayer == Player.O && !game.isOverallGameOver,
                  scale: scale,
                ),
              ),
            ],
          );
        }

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 * scale : 20 * scale,
            horizontal: horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 15 * scale,
                offset: Offset(0, 6 * scale),
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final int boardsWon;
  final int sessionWins;
  final Color color;
  final bool isCurrent;
  final double scale;

  const _ScoreItem({
    required this.label,
    required this.boardsWon,
    required this.sessionWins,
    required this.color,
    required this.isCurrent,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(8 * scale),
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrent ? color : color.withValues(alpha: 0.1),
          width: isCurrent ? 2.5 * scale : 1.0,
        ),
        borderRadius: BorderRadius.circular(16 * scale),
        color: isCurrent ? color.withValues(alpha: 0.05) : Colors.transparent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 12 * scale, // Reduced from 20
                letterSpacing: 1.0 * scale,
              ),
            ),
          ),
          SizedBox(height: 8 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: _ScoreBadge(
                  value: boardsWon,
                  label: 'BOARDS',
                  color: color.withValues(alpha: 0.12),
                  textColor: color,
                  scale: scale,
                  isMain: false,
                ),
              ),
              SizedBox(width: 4 * scale),
              Expanded(
                child: _ScoreBadge(
                  value: sessionWins,
                  label: 'WINS',
                  color: color,
                  textColor: Colors.white,
                  scale: scale,
                  isMain: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color textColor;
  final double scale;
  final bool isMain;

  const _ScoreBadge({
    required this.value,
    required this.label,
    required this.color,
    required this.textColor,
    required this.scale,
    required this.isMain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 4 * scale,
        vertical: isMain ? 8 * scale : 6 * scale,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10 * scale),
        boxShadow: isMain ? [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8 * scale,
            offset: Offset(0, 3 * scale),
          )
        ] : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: (isMain ? 18 : 16) * scale,
                fontWeight: FontWeight.w900,
                color: textColor,
                height: 1.0,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11 * scale, // Increased from 8
                fontWeight: FontWeight.w900,
                color: textColor.withValues(alpha: 0.9),
                letterSpacing: 0.5 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VSDivider extends StatelessWidget {
  final double scale;
  const _VSDivider({required this.scale});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'VS',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade400,
          fontSize: 22 * scale,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
