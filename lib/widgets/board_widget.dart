// ignore_for_file: unused_element
// lib/widgets/board_widget.dart
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/theme/app_theme.dart';
import '../features/game/logic/game_controller.dart';
import '../features/settings/logic/settings_controller.dart';
import '../models/player.dart';
import '../models/game_board.dart';
import 'board/winning_line.dart';
import 'board/winner_effect.dart';
import 'board/neumorphic_cell.dart';
import 'board/clay_bevel_painter.dart';
import 'board/debossed_grid_painter.dart';

class BoardWidget extends StatefulWidget {
  final int boardIndex;

  const BoardWidget({super.key, required this.boardIndex});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Offset> _rotationNotifier = ValueNotifier(Offset.zero);
  StreamSubscription<AccelerometerEvent>? _subscription;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    // Ultra-slow ocean wave duration
    final floatDuration = Duration(milliseconds: 6500 + (widget.boardIndex * 450));
    _floatController = AnimationController(vsync: this, duration: floatDuration);
    _floatController.repeat(); // Always float for all themes

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      DateTime lastUpdate = DateTime.now();
      _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
        final now = DateTime.now();
        if (now.difference(lastUpdate).inMilliseconds < 16) return; // Throttle to ~60Hz
        
        if (mounted) {
          final double yRot = (event.x / 10.0).clamp(-0.1, 0.1);
          final double xRot = (-event.y / 10.0).clamp(-0.1, 0.1);
          _rotationNotifier.value = Offset(xRot, yRot);
          lastUpdate = now;
        }
      }, onError: (error) {});
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _rotationNotifier.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Optimization: Use Selector to only rebuild when this specific board changes
    return Selector<GameController, ({GameBoard board, int? forcedIdx, Player current, int boardsLength})>(
      selector: (_, gc) => (
        board: widget.boardIndex < gc.boards.length ? gc.boards[widget.boardIndex] : GameBoard(),
        forcedIdx: gc.forcedBoardIndex,
        current: gc.currentPlayer,
        boardsLength: gc.boards.length,
      ),
      builder: (context, data, _) {
        final board = data.board;
        if (widget.boardIndex >= data.boardsLength) return const SizedBox.shrink();

        final settings = context.watch<SettingsController>();
        final isForced = data.forcedIdx == widget.boardIndex;
        final theme = Theme.of(context);
        final themeBgColor = theme.colorScheme.surface;
        
        final isNatureTheme = settings.currentTheme.name == 'Rushing Wind' ||
            settings.currentTheme.name == 'Amazon Jungle' ||
            settings.currentTheme.name == 'Pacific Waves' ||
            settings.currentTheme.name == 'Drifting Cloud' ||
            settings.currentTheme.name == 'Crimson Leaf';

        return LayoutBuilder(
          builder: (context, constraints) {
            final double scalingFactor = data.boardsLength > 1 ? 1.05 : 1.0; // Dynamic 5% Scaling
            final double boardSize = constraints.maxWidth * (data.boardsLength > 1 ? 1.02 : 1.0);
            final double padding = boardSize * 0.08 * scalingFactor;
            final double spacing = isNatureTheme ? 0.0 : (boardSize * 0.05 * scalingFactor);
            final double borderRadius = isNatureTheme ? (boardSize * 0.15) : (boardSize * 0.12);
            final double shadowOffset = (boardSize * 0.04).clamp(2.0, 10.0);
            final double shadowBlur = shadowOffset * 2;

            final bool isPlayable = (data.forcedIdx == null || data.forcedIdx == widget.boardIndex) && !board.isGameOver;
            
            final activePlayer = data.current;
            final themeColor = activePlayer == Player.X ? settings.currentTheme.colorX : settings.currentTheme.colorO;

            return RepaintBoundary(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 350),
                scale: data.boardsLength > 1 ? (isPlayable ? 1.02 : 0.95) : 1.0,
                child: ListenableBuilder(
                  listenable: Listenable.merge([_floatController, _rotationNotifier]),
                  builder: (context, child) {
                    final double floatAngle = _floatController.value * 2 * pi;
                    final double driftMultiplier = isPlayable ? 1.0 : 0.7;
                    
                    // Complex "Ocean Wave" motion: Horizontal drift + Vertical swell + Subtle sway
                    final double floatDx = sin(floatAngle) * 8.0 * driftMultiplier;
                    final double floatDy = cos(floatAngle * 0.85) * 12.0 * driftMultiplier;
                    final double swayRotation = sin(floatAngle * 0.5) * 0.025 * driftMultiplier;
                    
                    final double xRotation = _rotationNotifier.value.dx;
                    final double yRotation = _rotationNotifier.value.dy;

                    final double tiltShadowX = shadowOffset * (1.0 + (yRotation * 12.0));
                    final double tiltShadowY = shadowOffset * (1.0 + (-xRotation * 12.0));
                    final double lightShadowX = -shadowOffset * (1.0 - (yRotation * 12.0));
                    final double lightShadowY = -shadowOffset * (1.0 - (-xRotation * 12.0));

                    return Transform.translate(
                      offset: Offset(floatDx, floatDy),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(xRotation)
                          ..rotateY(yRotation)
                          ..rotateZ(swayRotation),
                        alignment: Alignment.center,
                        child: _buildBoardCore(
                          board, 
                          themeBgColor, 
                          isForced, 
                          borderRadius, 
                          shadowBlur, 
                          tiltShadowX, tiltShadowY, 
                          lightShadowX, lightShadowY, 
                          themeColor, 
                          boardSize, padding, spacing, 
                          settings,
                          xRotation, yRotation,
                          data.forcedIdx,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBoardCore(GameBoard board, Color themeBgColor, bool isForced, double borderRadius, double shadowBlur, double tsX, double tsY, double lsX, double lsY, Color themeColor, double boardSize, double padding, double spacing, SettingsController settings, double xRotation, double yRotation, int? forcedIdx) {
    return Container(
      decoration: BoxDecoration(
        color: isForced ? Color.lerp(themeBgColor, Colors.yellow.withValues(alpha: 0.35), 0.4)! : themeBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isForced ? Border.all(color: Colors.yellowAccent, width: 3.0) : null,
        boxShadow: [
          BoxShadow(color: NeumorphicColors.getDarkShadow(themeBgColor).withValues(alpha: 0.45), offset: Offset(tsX * 1.2, tsY * 1.2), blurRadius: shadowBlur * 0.8),
          BoxShadow(color: NeumorphicColors.getLightShadow(themeBgColor).withValues(alpha: 0.95), offset: Offset(lsX * 1.0, lsY * 1.0), blurRadius: shadowBlur * 0.9),
          if (isForced) BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.6), blurRadius: shadowBlur * 2, spreadRadius: 3),
        ],
      ),
      child: CustomPaint(
        painter: ClayBevelPainter(
          borderRadius: borderRadius,
          baseColor: themeBgColor,
          themeName: settings.currentTheme.name,
          tiltX: xRotation,
          tiltY: yRotation,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: SizedBox.square(
            dimension: boardSize - (padding * 2),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: DebossedGridPainter(
                        baseColor: themeBgColor,
                        themeName: settings.currentTheme.name,
                        padding: padding,
                        tiltX: xRotation,
                        tiltY: yRotation,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, cellIndex) {
                      return NeumorphicCell(
                        onTap: (board.isGameOver || (forcedIdx != null && forcedIdx != widget.boardIndex))
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                context.read<GameController>().makeMove(widget.boardIndex, cellIndex);
                                if (!_floatController.isAnimating) _floatController.repeat();
                              },
                        player: board.cells[cellIndex],
                        baseColor: isForced ? Color.lerp(themeBgColor, Colors.yellow.withValues(alpha: 0.25), 0.4)! : themeBgColor,
                        isBlocked: board.isGameOver || (forcedIdx != null && forcedIdx != widget.boardIndex),
                        isShielded: board.shields[cellIndex],
                        boardSize: boardSize,
                        boardIndex: widget.boardIndex,
                        cellIndex: cellIndex,
                      );
                    },
                  ),
                ),
                if (board.winner != null && board.winningLine != null)
                  Positioned.fill(
                    child: WinningLineWidget(
                      winner: board.winner!,
                      winningLine: board.winningLine!,
                      boardSize: boardSize,
                      padding: padding,
                      spacing: spacing,
                    ),
                  ),
                if (board.winner != null)
                  Positioned.fill(
                    child: BoardWinnerEffect(winner: board.winner!, boardSize: boardSize),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
