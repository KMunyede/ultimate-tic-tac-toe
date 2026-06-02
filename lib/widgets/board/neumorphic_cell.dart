// lib/widgets/board/neumorphic_cell.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../features/game/logic/game_controller.dart';
import '../../features/settings/logic/settings_controller.dart';
import '../../core/theme/app_theme.dart';
import 'animated_marker.dart';
import 'anticipation_halo_painter.dart';

class NeumorphicCell extends StatefulWidget {
  final VoidCallback? onTap;
  final Player player;
  final Color baseColor;
  final bool isBlocked;
  final bool isShielded; // [NEW] Track shields in cell UI
  final double boardSize;
  final int boardIndex;
  final int cellIndex;

  const NeumorphicCell({
    super.key,
    required this.onTap,
    required this.player,
    required this.baseColor,
    required this.boardSize,
    required this.boardIndex,
    required this.cellIndex,
    this.isBlocked = false,
    this.isShielded = false,
  });

  @override
  State<NeumorphicCell> createState() => _NeumorphicCellState();
}

class _NeumorphicCellState extends State<NeumorphicCell>
    with TickerProviderStateMixin {
  late AnimationController _pressController, _shakeController, _pulseController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100),
        lowerBound: 0.92,
        upperBound: 1.0,
        value: 1.0);
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(NeumorphicCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double borderRadius = widget.boardSize * 0.08;
    final double shadowOffset = (widget.boardSize * 0.02).clamp(1.0, 6.0);
    final double shadowBlur = shadowOffset * 2;

    // PERFORMANCE: Selective state watching to prevent redundant rebuilds
    final lastPlayedBoardIndex = context.select<GameController, int?>((c) => c.lastPlayedBoardIndex);
    final lastPlayedCellIndex = context.select<GameController, int?>((c) => c.lastPlayedCellIndex);
    final isLastMove = lastPlayedBoardIndex == widget.boardIndex && lastPlayedCellIndex == widget.cellIndex;
    
    final activeTheme = context.select<SettingsController, AppTheme>((s) => s.currentTheme);
    final currentPlayer = context.select<GameController, Player>((c) => c.currentPlayer);
    final themeColor = currentPlayer == Player.X ? activeTheme.colorX : activeTheme.colorO;

    final bool isNatureTheme = activeTheme.name == 'Rushing Wind' ||
        activeTheme.name == 'Amazon Jungle' ||
        activeTheme.name == 'Rising Moon' ||
        activeTheme.name == 'Drifting Cloud' ||
        activeTheme.name == 'Crimson Leaf';

    // TICKER OPTIMIZATION: Only pulse if it's the last move
    if (isLastMove && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isLastMove && _pulseController.isAnimating) {
      _pulseController.stop();
    }

    return MouseRegion(
      onEnter: (_) {
        if (!widget.isBlocked && widget.player == Player.none) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: _isHovered ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, hoverVal, child) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: !widget.isBlocked
                ? (_) => _pressController.reverse()
                : null,
            onTapUp: !widget.isBlocked
                ? (_) => _pressController.forward()
                : null,
            onTap: () {
              if (widget.onTap != null) {
                setState(() => _isHovered = false); // Clear hover on tap
                widget.onTap!();
              } else if (widget.isBlocked) {
                _shakeController.forward(from: 0.0);
              }
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([_shakeController, _pulseController]),
              builder: (context, child) =>
                  Transform.translate(
                    offset: Offset(sin(_shakeController.value * pi * 4) *
                        (widget.boardSize * 0.03), 0),
                    child: ScaleTransition(
                        scale: _pressController, child: child),
                  ),
              child: Container(
                decoration: isNatureTheme
                    ? const BoxDecoration(color: Colors.transparent)
                    : BoxDecoration(
                  color: widget.isBlocked && widget.player == Player.none
                      ? widget.baseColor.withValues(alpha: 0.3)
                      : widget.baseColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    // Deep sharp shadow for deep carved cells
                    BoxShadow(
                        color: NeumorphicColors.getDarkShadow(widget.baseColor),
                        offset: Offset(shadowOffset * 0.8, shadowOffset * 0.8),
                        blurRadius: shadowBlur * 0.45),
                    // Crisp sharp highlight for carved cells
                    BoxShadow(color: NeumorphicColors.getLightShadow(
                        widget.baseColor),
                        offset: Offset(
                            -shadowOffset * 0.7, -shadowOffset * 0.7),
                        blurRadius: shadowBlur * 0.4),
                  ],
                ),
                child: Stack(
                  children: [
                    if (!widget.isBlocked && widget.player == Player.none)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: AnticipationHaloPainter(
                              pulse: _pulseController.value,
                              hover: hoverVal,
                              themeName: activeTheme.name,
                              activeColor: themeColor,
                              boardSize: widget.boardSize,
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(widget.boardSize * 0.01),
                        child: AnimatedMarker(
                          player: widget.player,
                          boardSize: widget.boardSize,
                          isLarge: false,
                        ),
                      ),
                    ),
                    if (widget.isShielded)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: ShieldLockPainter(
                                boardSize: widget.boardSize),
                          ),
                        ),
                      ),
                    
                    // Pulse neon ring overlay around the last played move cell
                    if (isLastMove)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final double pulseVal = 0.45 + (_pulseController.value * 0.55);
                              final Color lastMoveColor = widget.player == Player.X 
                                  ? activeTheme.colorX 
                                  : activeTheme.colorO;
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(borderRadius),
                                  border: Border.all(
                                    color: lastMoveColor.withValues(alpha: pulseVal),
                                    width: 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: lastMoveColor.withValues(alpha: pulseVal * 0.45),
                                      blurRadius: 5.0 + _pulseController.value * 7.0,
                                      spreadRadius: 0.5 + _pulseController.value * 1.5,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ShieldLockPainter extends CustomPainter {
  final double boardSize;

  ShieldLockPainter({required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = boardSize * 0.016;
    final Color goldColor = const Color(0xFFFFD700);
    final Color lightGold = const Color(0xFFFFFDE7);

    // 1. Draw glowing neon shield outline around the cell
    final paintGlow = Paint()
      ..color = goldColor.withValues(alpha: 0.45)
      ..strokeWidth = strokeWidth * 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.5);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(boardSize * 0.08),
      ));
    canvas.drawPath(path, paintGlow);

    final paintGas = Paint()
      ..color = goldColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paintGas);

    // 2. Draw Padlock emblem in top-right corner
    final double iconSize = size.width * 0.28;
    final double rightOffset = size.width * 0.08;
    final double topOffset = size.height * 0.08;

    final paintIcon = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill;

    final lockRect = Rect.fromLTWH(
        size.width - iconSize - rightOffset, topOffset + iconSize * 0.4,
        iconSize, iconSize * 0.6);
    final lockShackleRect = Rect.fromLTWH(
        size.width - iconSize - rightOffset + iconSize * 0.2, topOffset,
        iconSize * 0.6, iconSize * 0.6);

    // Shackle
    final shacklePaint = Paint()
      ..color = goldColor
      ..strokeWidth = strokeWidth * 0.7
      ..style = PaintingStyle.stroke;
    canvas.drawArc(lockShackleRect, 3.14, 3.14, false, shacklePaint);

    // Body
    canvas.drawRRect(
        RRect.fromRectAndRadius(lockRect, Radius.circular(boardSize * 0.015)),
        paintIcon);

    // Shackle Core Glow
    final shackleCorePaint = Paint()
      ..color = lightGold
      ..strokeWidth = strokeWidth * 0.25
      ..style = PaintingStyle.stroke;
    canvas.drawArc(lockShackleRect, 3.14, 3.14, false, shackleCorePaint);

    // Body Core Center dot
    final bodyCorePaint = Paint()
      ..color = lightGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(
        size.width - rightOffset - iconSize * 0.5, topOffset + iconSize * 0.7),
        boardSize * 0.005, bodyCorePaint);
  }

  @override
  bool shouldRepaint(ShieldLockPainter oldDelegate) => false;
}
