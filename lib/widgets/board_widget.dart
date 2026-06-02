// ignore_for_file: unused_element
// lib/widgets/board_widget.dart
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../core/theme/app_theme.dart';
import '../features/game/logic/game_controller.dart';
import '../features/settings/logic/settings_controller.dart';
import '../models/player.dart';
import 'board/winning_line.dart';
import 'board/winner_effect.dart';
import 'board/watermark.dart';
import 'board/neumorphic_cell.dart';
import 'board/clay_bevel_painter.dart';
import 'board/debossed_grid_painter.dart';
import 'board/animated_marker.dart';

class BoardWidget extends StatefulWidget {
  final int boardIndex;

  const BoardWidget({super.key, required this.boardIndex});

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  double xRotation = 0;
  double yRotation = 0;
  StreamSubscription<AccelerometerEvent>? _subscription;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();

    // Desynchronized phase loop durations so each board floats on its own wave signature
    final floatDuration = Duration(
        milliseconds: 3200 + (widget.boardIndex * 280));
    _floatController = AnimationController(
      vsync: this,
      duration: floatDuration,
    ); // Performance Calibration: Removed ..repeat() to eliminate per-frame sub-board repaints

    // Sensors are only supported on mobile platforms. 
    // Checking platform to avoid MissingPluginException on Windows/Web.
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _subscription =
          accelerometerEventStream().listen((AccelerometerEvent event) {
            if (mounted) {
              setState(() {
                yRotation = (event.x / 10.0).clamp(-0.1, 0.1);
                xRotation = (-event.y / 10.0).clamp(-0.1, 0.1);
              });
            }
          }, onError: (error) {
            if (kDebugMode) {
              print("Accelerometer error ignored safely: $error");
            }
          });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GameController>(context);
    final settings = Provider.of<SettingsController>(context);
    if (widget.boardIndex >= controller.boards.length) {
      return const SizedBox.shrink();
    }

    final board = controller.boards[widget.boardIndex];
    final theme = Theme.of(context);
    final themeBgColor = theme.colorScheme.surface;
    final isForced = controller.forcedBoardIndex == widget.boardIndex;

    final bool isNatureTheme = settings.currentTheme.name == 'Rushing Wind' ||
        settings.currentTheme.name == 'Amazon Jungle' ||
        settings.currentTheme.name == 'Rising Moon' ||
        settings.currentTheme.name == 'Drifting Cloud' ||
        settings.currentTheme.name == 'Crimson Leaf';

    return LayoutBuilder(
      builder: (context, constraints) {
        final double boardSize = constraints.maxWidth;

        // ADAPTIVE SCALING FACTORS
        final double padding = boardSize * 0.08; // 8% padding
        final double spacing = isNatureTheme ? 0.0 : (boardSize *
            0.05); // flush cells for nature themes!
        final double borderRadius = isNatureTheme
            ? (boardSize * 0.15)
            : (boardSize * 0.12); // extremely rounded corners!
        final double shadowOffset = (boardSize * 0.04).clamp(2.0, 10.0);
        final double shadowBlur = shadowOffset * 2;

        // DYNAMIC SHADOW TRACING
        // As the board tilts, the shadow stretches in the opposite direction
        final double tiltShadowX = shadowOffset * (1.0 + (yRotation * 12.0));
        final double tiltShadowY = shadowOffset * (1.0 + (-xRotation * 12.0));
        final double lightShadowX = -shadowOffset * (1.0 - (yRotation * 12.0));
        final double lightShadowY = -shadowOffset * (1.0 - (-xRotation * 12.0));

        final bool isPlayable = (controller.forcedBoardIndex == null ||
            controller.forcedBoardIndex == widget.boardIndex) &&
            !board.isGameOver;
        final double opacity = controller.boards.length > 1 ? (isPlayable
            ? 1.0
            : (board.isGameOver ? 0.50 : 0.65)) : 1.0;
        final double scale = controller.boards.length > 1 ? (isPlayable
            ? 1.02 // DAMPENED: From 1.04 to 1.02 to reduce screen footprint
            : 0.95) : 1.0;

        final activePlayer = controller.currentPlayer;
        final themeColor = activePlayer == Player.X ? settings.currentTheme
            .colorX : settings.currentTheme.colorO;

        // Pulse effect for Forced Board in Ultimate Mode
        final boardContainer = ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isForced
                    ? Color.lerp(themeBgColor.withValues(alpha: 0.94),
                    Colors.yellow.withValues(alpha: 0.35), 0.4)!
                    : themeBgColor.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(borderRadius),
                border: isForced
                    ? Border.all(color: Colors.yellowAccent, width: 3.0)
                    : null,
                boxShadow: [
                  // 1. Deep Ambient shadows (tighter spread, higher opacity for depth)
                  BoxShadow(
                    color: NeumorphicColors
                        .getDarkShadow(themeBgColor)
                        .withValues(alpha: 0.45),
                    offset: Offset(tiltShadowX * 1.2, tiltShadowY * 1.2),
                    blurRadius: shadowBlur * 0.8,
                  ),
                  BoxShadow(
                    color: NeumorphicColors
                        .getLightShadow(themeBgColor)
                        .withValues(alpha: 0.95),
                    offset: Offset(lightShadowX * 1.0, lightShadowY * 1.0),
                    blurRadius: shadowBlur * 0.9,
                  ),
                  // 2. Sharp Proximity creases (very tight offset, solid opacity for hard edge)
                  BoxShadow(
                    color: NeumorphicColors
                        .getDarkShadow(themeBgColor)
                        .withValues(alpha: 0.85),
                    offset: Offset(tiltShadowX * 0.4, tiltShadowY * 0.4),
                    blurRadius: shadowBlur * 0.25,
                  ),
                  BoxShadow(
                    color: NeumorphicColors.getLightShadow(themeBgColor),
                    offset: Offset(lightShadowX * 0.3, lightShadowY * 0.3),
                    blurRadius: shadowBlur * 0.2,
                  ),
                  if (isForced)
                    BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.6),
                        blurRadius: shadowBlur * 2,
                        spreadRadius: 3)
                  else
                    if (isPlayable && controller.boards.length > 1)
                      BoxShadow(color: themeColor.withValues(alpha: 0.25),
                          blurRadius: shadowBlur * 1.5,
                          spreadRadius: 1.5),
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
                  child: Stack(
                    children: [
                    // LAYER 1: WATERMARK (Deepest Parallax)
                    if (board.winner != null)
                      Positioned.fill(
                        child: Transform(
                          transform: Matrix4.translationValues(0.0, 0.0, -15.0),
                          alignment: Alignment.center,
                          child: IgnorePointer(
                            child: SubBoardWatermark(
                              winner: board.winner!,
                              themeName: settings.currentTheme.name,
                              boardSize: boardSize,
                              boardIndex: widget.boardIndex,
                            ),
                          ),
                        ),
                      ),
                    // LAYER 2: DEBOSSED GRID (Mid Parallax)
                    Positioned.fill(
                      child: Transform(
                        transform: Matrix4.translationValues(0.0, 0.0, -5.0),
                        alignment: Alignment.center,
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
                    ),
                    // LAYER 3: CELLS & MARKERS (Top Parallax)
                    Transform(
                      transform: Matrix4.translationValues(0.0, 0.0, 10.0),
                      alignment: Alignment.center,
                      child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                          ),
                          itemCount: 9,
                          itemBuilder: (context, cellIndex) {
                            return NeumorphicCell(
                              onTap: (board.isGameOver ||
                                  (controller.forcedBoardIndex != null &&
                                      controller.forcedBoardIndex !=
                                          widget.boardIndex))
                                  ? null
                                  : () {
                                HapticFeedback
                                    .lightImpact(); // Add Tactile Feedback
                                controller.makeMove(widget.boardIndex, cellIndex);
                                // Resume floating leaf animations dynamically
                                if (!_floatController.isAnimating) {
                                  _floatController.repeat();
                                }
                              },
                              player: board.cells[cellIndex],
                              baseColor: isForced
                                  ? Color.lerp(themeBgColor,
                                  Colors.yellow.withValues(alpha: 0.25), 0.4)!
                                  : themeBgColor,
                              isBlocked: board.isGameOver ||
                                  (controller.forcedBoardIndex != null &&
                                      controller.forcedBoardIndex !=
                                          widget.boardIndex),
                              isShielded: board.shields[cellIndex],
                              boardSize: boardSize,
                              boardIndex: widget.boardIndex,
                              cellIndex: cellIndex,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Resume float loop on first load or active state transitions
        if (isPlayable && !_floatController.isAnimating) {
          _floatController.repeat();
        }

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          opacity: opacity,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            scale: scale,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, childWidget) {
                final double floatAngle = _floatController.value * 2 * pi;
                // Sinusoidal leaf-floating motion on waves (desynchronized)
                // DAMPENED DRIFT: Multiplier reduced from 1.4/0.7 to 1.1/0.6 to prevent spillage
                final double driftMultiplier = isPlayable ? 1.1 : 0.6;
                final double floatDx = sin(floatAngle) * 3.0 * driftMultiplier;
                final double floatDy = cos(floatAngle * 1.5) * 5.0 *
                    driftMultiplier;
                final double swayRotation = sin(floatAngle) * 0.022 *
                    driftMultiplier;

                return TweenAnimationBuilder<double>(
                  key: ValueKey(board.winner),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    final double shake = (board.winner != null && value < 1.0)
                        ? sin(value * pi * 4) * (boardSize * 0.05)
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(shake + floatDx, floatDy),
                      child: Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateX(xRotation)
                          ..rotateY(yRotation)
                          ..rotateZ(swayRotation),
                        alignment: Alignment.center,
                        child: child,
                      ),
                    );
                  },
                  child: childWidget,
                );
              },
              child: Stack(
                children: [
                  boardContainer,
                  if (board.winner != null)
                    Positioned.fill(
                      child: Transform(
                        transform: Matrix4.translationValues(0.0, 0.0, 45.0),
                        alignment: Alignment.center,
                        child: IgnorePointer(
                          child: Center(
                            child: AnimatedMarker(
                              player: board.winner!,
                              boardSize: boardSize,
                              isLarge: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (board.winner != null && board.winningLine != null)
                    Positioned.fill(
                      child: Transform(
                        transform: Matrix4.translationValues(0.0, 0.0, 30.0),
                        alignment: Alignment.center,
                        child: WinningLineWidget(
                          winner: board.winner!,
                          winningLine: board.winningLine!,
                          boardSize: boardSize,
                          padding: padding,
                          spacing: spacing,
                        ),
                      ),
                    ),
                  if (board.winner != null)
                    Positioned.fill(
                      child: Transform(
                        transform: Matrix4.translationValues(0.0, 0.0, 50.0),
                        alignment: Alignment.center,
                        child: BoardWinnerEffect(
                            winner: board.winner!, boardSize: boardSize),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

