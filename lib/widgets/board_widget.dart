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
        settings.currentTheme.name == 'Floating Feather' ||
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

        final bool isPlayable = (controller.forcedBoardIndex == null ||
            controller.forcedBoardIndex == widget.boardIndex) &&
            !board.isGameOver;
        final double opacity = controller.boards.length > 1 ? (isPlayable
            ? 1.0
            : (board.isGameOver ? 0.50 : 0.65)) : 1.0;
        final double scale = controller.boards.length > 1 ? (isPlayable
            ? 1.04
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
                    offset: Offset(shadowOffset * 1.2, shadowOffset * 1.2),
                    blurRadius: shadowBlur * 0.8,
                  ),
                  BoxShadow(
                    color: NeumorphicColors
                        .getLightShadow(themeBgColor)
                        .withValues(alpha: 0.95),
                    offset: Offset(-shadowOffset * 1.0, -shadowOffset * 1.0),
                    blurRadius: shadowBlur * 0.9,
                  ),
                  // 2. Sharp Proximity creases (very tight offset, solid opacity for hard edge)
                  BoxShadow(
                    color: NeumorphicColors
                        .getDarkShadow(themeBgColor)
                        .withValues(alpha: 0.85),
                    offset: Offset(shadowOffset * 0.4, shadowOffset * 0.4),
                    blurRadius: shadowBlur * 0.25,
                  ),
                  BoxShadow(
                    color: NeumorphicColors.getLightShadow(themeBgColor),
                    offset: Offset(-shadowOffset * 0.3, -shadowOffset * 0.3),
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
                ),
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Stack(
                    children: [
                      if (board.winner != null)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: SubBoardWatermark(
                              winner: board.winner!,
                              themeName: settings.currentTheme.name,
                              boardSize: boardSize,
                              boardIndex: widget.boardIndex,
                            ),
                          ),
                        ),
                      // Painted debossed/carved grid grooves pressed into the warm clay tile
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: DebossedGridPainter(
                              baseColor: themeBgColor,
                              themeName: settings.currentTheme.name,
                              padding: padding,
                            ),
                          ),
                        ),
                      ),
                      GridView.builder(
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
                final double driftMultiplier = isPlayable ? 1.4 : 0.7;
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
                    Positioned.fill(child: BoardWinnerEffect(
                        winner: board.winner!, boardSize: boardSize)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class WinningLineWidget extends StatefulWidget {
  final Player winner;
  final List<int> winningLine;
  final double boardSize;
  final double padding;
  final double spacing;

  const WinningLineWidget({
    super.key,
    required this.winner,
    required this.winningLine,
    required this.boardSize,
    required this.padding,
    required this.spacing,
  });

  @override
  State<WinningLineWidget> createState() => _WinningLineWidgetState();
}

class _WinningLineWidgetState extends State<WinningLineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    final baseColor = widget.winner == Player.X
        ? activeTheme.colorX
        : activeTheme.colorO;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          CustomPaint(
            painter: WinningLinePainter(
              winner: widget.winner,
              winningLine: widget.winningLine,
              progress: _controller.value,
              boardSize: widget.boardSize,
              padding: widget.padding,
              spacing: widget.spacing,
              baseColor: baseColor,
            ),
          ),
    );
  }
}

class WinningLinePainter extends CustomPainter {
  final Player winner;
  final List<int> winningLine;
  final double progress, boardSize, padding, spacing;
  final Color baseColor;

  WinningLinePainter({
    required this.winner,
    required this.winningLine,
    required this.progress,
    required this.boardSize,
    required this.padding,
    required this.spacing,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = boardSize * 0.05;
    final double cellSize = (boardSize - (padding * 2) - (spacing * 2)) / 3;

    Offset getCenter(int index) {
      final int row = index ~/ 3;
      final int col = index % 3;
      return Offset(
        padding + col * (cellSize + spacing) + cellSize / 2,
        padding + row * (cellSize + spacing) + cellSize / 2,
      );
    }

    final start = getCenter(winningLine.first);
    final end = getCenter(winningLine.last);
    final currentEnd = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );

    // Determine dynamic neon colors based on active theme
    final double alpha = 0.95;
    final Color glowColor = baseColor.withValues(alpha: alpha * 0.45);
    final Color gasColor = baseColor.withValues(alpha: alpha);
    final Color coreColor = Color.lerp(baseColor, Colors.white, 0.75)!
        .withValues(alpha: alpha * 0.9);

    // 1. Outer Glow
    final paintGlow = Paint()
      ..color = glowColor
      ..strokeWidth = strokeWidth * 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, strokeWidth * 0.5);
    canvas.drawLine(start, currentEnd, paintGlow);

    // 2. Neon Gas
    final paintGas = Paint()
      ..color = gasColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, currentEnd, paintGas);

    // 3. Core Filament
    final paintCore = Paint()
      ..color = coreColor
      ..strokeWidth = strokeWidth * 0.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, currentEnd, paintCore);
  }

  @override
  bool shouldRepaint(WinningLinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.baseColor != baseColor;
}

class BoardWinnerEffect extends StatefulWidget {
  final Player winner;
  final double boardSize;

  const BoardWinnerEffect(
      {super.key, required this.winner, required this.boardSize});

  @override
  State<BoardWinnerEffect> createState() => _BoardWinnerEffectState();
}

class _BoardWinnerEffectState extends State<BoardWinnerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..addListener(() => setState(() {}));
    _createParticles();
    _controller.forward();
  }

  void _createParticles() {
    final settings = Provider.of<SettingsController>(context, listen: false);
    final activeTheme = settings.currentTheme;
    final color = widget.winner == Player.X ? activeTheme.colorX : activeTheme
        .colorO;
    for (int i = 0; i < 40; i++) {
      _particles.add(Particle(
        color: color.withValues(alpha: _random.nextDouble() * 0.8 + 0.2),
        angle: _random.nextDouble() * 2 * pi,
        speed: _random.nextDouble() * 4 + 2,
        size: _random.nextDouble() * (widget.boardSize * 0.04) + 2,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: ParticlePainter(particles: _particles,
          progress: _controller.value,
          boardSize: widget.boardSize)),
    );
  }
}

class Particle {
  final Color color;
  final double angle, speed, size;

  Particle(
      {required this.color, required this.angle, required this.speed, required this.size});
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress, boardSize;

  ParticlePainter(
      {required this.particles, required this.progress, required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();
    for (var p in particles) {
      final distance = p.speed * progress * (boardSize * 0.5);
      final x = center.dx + cos(p.angle) * distance;
      final y = center.dy + sin(p.angle) * distance;
      paint.color = p.color.withValues(
          alpha: (1.0 - progress).clamp(0.0, 1.0) * p.color.a);
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

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

    final gameController = context.watch<GameController>();
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    final activePlayer = gameController.currentPlayer;
    final themeColor = activePlayer == Player.X
        ? activeTheme.colorX
        : activeTheme.colorO;

    final bool isNatureTheme = activeTheme.name == 'Rushing Wind' ||
        activeTheme.name == 'Floating Feather' ||
        activeTheme.name == 'Rising Moon' ||
        activeTheme.name == 'Drifting Cloud' ||
        activeTheme.name == 'Crimson Leaf';

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
                              themeName: settings.currentTheme.name,
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
                    if (gameController.lastPlayedBoardIndex == widget.boardIndex &&
                        gameController.lastPlayedCellIndex == widget.cellIndex)
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

class AnimatedMarker extends StatefulWidget {
  final Player player;
  final double boardSize;
  final bool isLarge;

  const AnimatedMarker({
    super.key,
    required this.player,
    required this.boardSize,
    this.isLarge = false,
  });

  @override
  State<AnimatedMarker> createState() => _AnimatedMarkerState();
}

class _AnimatedMarkerState extends State<AnimatedMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Player? _lastPlayer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 850), // Slowed down for satisfying real-time signature draw speed
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic, // Simulated brush acceleration/deceleration
    );
    if (widget.player != Player.none) {
      _controller.forward();
    }
    _lastPlayer = widget.player;
  }

  @override
  void didUpdateWidget(AnimatedMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.player != _lastPlayer) {
      if (widget.player == Player.none) {
        _controller.reset();
      } else {
        _controller.forward(from: 0.0);
      }
      _lastPlayer = widget.player;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.player == Player.none) {
      return const SizedBox.shrink();
    }
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    final baseColor = widget.player == Player.X
        ? activeTheme.colorX
        : activeTheme.colorO;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) =>
          SizedBox.expand(
            child: CustomPaint(
              size: Size.infinite,
              painter: MarkerPainter(
                player: widget.player,
                progress: _animation.value,
                boardSize: widget.boardSize,
                isLarge: widget.isLarge,
                baseColor: baseColor,
                themeName: activeTheme.name,
              ),
            ),
          ),
    );
  }
}

class MarkerPainter extends CustomPainter {
  final Player player;
  final double progress, boardSize;
  final bool isLarge;
  final Color baseColor;
  final String themeName;

  MarkerPainter({
    required this.player,
    required this.progress,
    required this.boardSize,
    required this.isLarge,
    required this.baseColor,
    required this.themeName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double baseStrokeWidth = isLarge ? boardSize * 0.12 : boardSize *
        0.08;
    final double strokeWidth = baseStrokeWidth.clamp(
        isLarge ? 4.0 : 2.5, isLarge ? 40.0 : 12.0);

    final double padding = isLarge ? size.width * 0.15 : size.width * 0.22;


    void drawWobblyLine(Offset p1, Offset p2, Paint paint) {
      final double dx = p2.dx - p1.dx;
      final double dy = p2.dy - p1.dy;
      final double len = sqrt(dx * dx + dy * dy);
      if (len < 2) {
        canvas.drawLine(p1, p2, paint);
        return;
      }

      final int segments = (len / 6.0).clamp(4, 30).toInt();
      final path = Path();
      path.moveTo(p1.dx, p1.dy);

      final double px = -dy / len;
      final double py = dx / len;

      final random = Random(p1.dx.toInt() ^ p2.dy.toInt());

      for (int i = 1; i <= segments; i++) {
        final double ratio = i / segments;
        final double x = p1.dx + dx * ratio;
        final double y = p1.dy + dy * ratio;

        final double wobble = sin(ratio * pi * 5) * 0.9 +
            (random.nextDouble() - 0.5) * 0.6;
        path.lineTo(x + px * wobble, y + py * wobble);
      }
      canvas.drawPath(path, paint);
    }

    void drawWobblyArc(Rect rect, double startAngle, double sweepAngle,
        Paint paint) {
      final double cx = rect.center.dx;
      final double cy = rect.center.dy;
      final double rx = rect.width / 2;
      final double ry = rect.height / 2;

      final int segments = (sweepAngle.abs() * 25).clamp(6, 60).toInt();
      final path = Path();

      final double firstAngle = startAngle;
      final double firstWobble = sin(firstAngle * 6) * 0.8;
      path.moveTo(
        cx + cos(firstAngle) * (rx + firstWobble),
        cy + sin(firstAngle) * (ry + firstWobble),
      );

      final random = Random(rect.left.toInt() ^ rect.top.toInt());

      for (int i = 1; i <= segments; i++) {
        final double ratio = i / segments;
        final double angle = startAngle + sweepAngle * ratio;

        final double wobble = sin(angle * 7) * 0.9 +
            (random.nextDouble() - 0.5) * 0.5;
        path.lineTo(
          cx + cos(angle) * (rx + wobble),
          cy + sin(angle) * (ry + wobble),
        );
      }
      canvas.drawPath(path, paint);
    }

    void drawCalligraphicLine(Offset p1, Offset p2, Color color) {
      final double dx = p2.dx - p1.dx;
      final double dy = p2.dy - p1.dy;
      final double len = sqrt(dx * dx + dy * dy);
      if (len < 2) return;

      final int segments = (len / 3.0).clamp(10, 45).toInt();
      final List<Offset> points = [];
      points.add(p1);

      final double px = -dy / len;
      final double py = dx / len;
      final random = Random(p1.dx.toInt() ^ p2.dy.toInt());

      for (int i = 1; i <= segments; i++) {
        final double ratio = i / segments;
        final double x = p1.dx + dx * ratio;
        final double y = p1.dy + dy * ratio;

        final double wobble = sin(ratio * pi * 4) * 0.35 +
            (random.nextDouble() - 0.5) * 0.25;
        points.add(Offset(x + px * wobble, y + py * wobble));
      }

      // Draw segments with calligraphic swelling & tapering
      for (int i = 0; i < points.length - 1; i++) {
        final double ratio = i / (points.length - 1);
        final double scale = 0.28 + sin(ratio * pi) * 1.15;
        final double currentWidth = strokeWidth * scale;

        final paint = Paint()
          ..color = color.withValues(alpha: 0.95)
          ..strokeWidth = currentWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    void drawCalligraphicArc(Rect rect, double startAngle, double sweepAngle,
        Color color) {
      final double cx = rect.center.dx;
      final double cy = rect.center.dy;
      final double rx = rect.width / 2;
      final double ry = rect.height / 2;

      final int segments = 50;
      final List<Offset> points = [];
      final random = Random(rect.left.toInt() ^ rect.top.toInt());

      for (int i = 0; i <= segments; i++) {
        final double ratio = i / segments;
        final double angle = startAngle + sweepAngle * ratio;
        final double wobble = sin(angle * 5) * 0.4 +
            (random.nextDouble() - 0.5) * 0.25;
        points.add(Offset(
          cx + cos(angle) * (rx + wobble),
          cy + sin(angle) * (ry + wobble),
        ));
      }

      for (int i = 0; i < points.length - 1; i++) {
        final double ratio = i / (points.length - 1);
        final double scale = 0.32 + sin(ratio * pi) * 1.1;
        final double currentWidth = strokeWidth * scale;

        final paint = Paint()
          ..color = color.withValues(alpha: 0.95)
          ..strokeWidth = currentWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    void drawBristleStroke(Offset p1, Offset p2, Color color) {
      final double dx = p2.dx - p1.dx;
      final double dy = p2.dy - p1.dy;
      final double len = sqrt(dx * dx + dy * dy);
      if (len < 2) return;

      final int numBristles = 14; // Multiple overlapping brush hairs
      final random = Random(p1.dx.toInt() ^ p2.dy.toInt());

      for (int b = 0; b < numBristles; b++) {
        final path = Path();
        path.moveTo(p1.dx, p1.dy);

        // Distribute bristles randomly across the width of the stroke
        final double bristleSpread = (random.nextDouble() - 0.5) * strokeWidth;
        final double bristleWidth = 1.0 + random.nextDouble() * 2.0;

        // Dry brush effect: some bristles are fainter, simulating less paint
        final double bristleAlpha = 0.3 + random.nextDouble() * 0.6;

        final int segments = 15;
        final double px = -dy / len;
        final double py = dx / len;

        for (int i = 1; i <= segments; i++) {
          final double ratio = i / segments;
          final double x = p1.dx + dx * ratio;
          final double y = p1.dy + dy * ratio;

          // Pressure simulation: Brush stroke tapers at ends and swells in middle
          final double pressure = sin(ratio * pi);
          final double currentOffset = bristleSpread * pressure;

          path.lineTo(x + px * currentOffset, y + py * currentOffset);
        }

        final paint = Paint()
          ..color = color.withValues(alpha: bristleAlpha)
          ..strokeWidth = bristleWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(path, paint);
      }
    }

    void drawBristleArc(Rect rect, double startAngle, double sweepAngle,
        Color color) {
      final double cx = rect.center.dx;
      final double cy = rect.center.dy;
      final double rx = rect.width / 2;
      final double ry = rect.height / 2;

      final int numBristles = 16;
      final random = Random(rect.left.toInt() ^ rect.top.toInt());

      for (int b = 0; b < numBristles; b++) {
        final path = Path();
        final double bristleSpread = (random.nextDouble() - 0.5) * strokeWidth;
        final double bristleWidth = 1.0 + random.nextDouble() * 2.0;
        final double bristleAlpha = 0.3 + random.nextDouble() * 0.6;

        final int segments = 30;

        path.moveTo(
          cx + cos(startAngle) * (rx),
          cy + sin(startAngle) * (ry),
        );

        for (int i = 1; i <= segments; i++) {
          final double ratio = i / segments;
          final double angle = startAngle + sweepAngle * ratio;

          // Pressure swelling: paint pools at bottom of loop, tapers at start/end
          final double pressure = 0.3 + 0.7 * sin(ratio * pi);
          final double currentSpread = bristleSpread * pressure;

          path.lineTo(
            cx + cos(angle) * (rx + currentSpread),
            cy + sin(angle) * (ry + currentSpread),
          );
        }

        final paint = Paint()
          ..color = color.withValues(alpha: bristleAlpha)
          ..strokeWidth = bristleWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(path, paint);
      }
    }

    void drawThemedLine(Offset p1, Offset p2) {
      if (themeName == 'Rising Moon') {
        // Laser-crisp glowing neon (high energy, zero powdery blur)
        final paintGlow = Paint()
          ..color = baseColor.withValues(alpha: 0.45)
          ..strokeWidth = strokeWidth * 1.4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
        drawWobblyLine(p1, p2, paintGlow);

        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.95)
          ..strokeWidth = strokeWidth * 0.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintCore);

        final paintHighlight = Paint()
          ..color = Colors.white
          ..strokeWidth = strokeWidth * 0.22
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintHighlight);
      } else if (themeName == 'Drifting Cloud') {
        // Blocky solid strokes with a flat black drop shadow
        final paintShadow = Paint()
          ..color = const Color(0xFF384F56).withValues(alpha: 0.28)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(
            Offset(p1.dx + 2.5, p1.dy + 2.5), Offset(p2.dx + 2.5, p2.dy + 2.5),
            paintShadow);

        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.95)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintCore);

        final paintHighlight = Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = strokeWidth * 0.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintHighlight);
      } else if (themeName == 'Crimson Leaf') {
        // Authentic sumi calligraphic brush strokes
        drawCalligraphicLine(p1, p2, baseColor);
      } else if (themeName == 'Floating Feather') {
        // Clean matte wobbly pastel line
        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.90)
          ..strokeWidth = strokeWidth * 0.9
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintCore);

        final paintHighlight = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = strokeWidth * 0.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintHighlight);
      } else if (themeName == 'Rushing Wind') {
        // Phase C: Powdery Halo (Glow Pass) for Rushing Wind
        // First pass: Wide, thick stroke with blur and low opacity for chalk halo
        final paintHalo = Paint()
          ..color = baseColor.withValues(alpha: 0.18)
          ..strokeWidth = strokeWidth * 1.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        drawWobblyLine(p1, p2, paintHalo);

        // Second pass: Solid core stroke with 85% opacity
        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.85)
          ..strokeWidth = strokeWidth * 0.9
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintCore);

        // Third pass: Very thin center line representing highest pressure
        final paintPressure = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = strokeWidth * 0.18
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintPressure);
      } else {
        // Default: Authentic Paint Brush Strokes
        drawBristleStroke(p1, p2, baseColor);
      }
    }

    void drawThemedArc(Rect rect, double startAngle, double sweepAngle) {
      if (themeName == 'Rising Moon') {
        final paintGlow = Paint()
          ..color = baseColor.withValues(alpha: 0.45)
          ..strokeWidth = strokeWidth * 1.4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
        drawWobblyArc(rect, startAngle, sweepAngle, paintGlow);

        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.95)
          ..strokeWidth = strokeWidth * 0.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintCore);

        final paintHighlight = Paint()
          ..color = Colors.white
          ..strokeWidth = strokeWidth * 0.22
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintHighlight);
      } else if (themeName == 'Drifting Cloud') {
        final paintShadow = Paint()
          ..color = const Color(0xFF384F56).withValues(alpha: 0.28)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final offsetRect = rect.shift(const Offset(2.5, 2.5));
        drawWobblyArc(offsetRect, startAngle, sweepAngle, paintShadow);

        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.95)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintCore);

        final paintHighlight = Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = strokeWidth * 0.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintHighlight);
      } else if (themeName == 'Crimson Leaf') {
        drawCalligraphicArc(rect, startAngle, sweepAngle, baseColor);
      } else if (themeName == 'Floating Feather') {
        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.90)
          ..strokeWidth = strokeWidth * 0.9
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintCore);

        final paintHighlight = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = strokeWidth * 0.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintHighlight);
      } else if (themeName == 'Rushing Wind') {
        // Phase C: Powdery Halo (Glow Pass) for Rushing Wind
        // First pass: Wide, thick stroke with blur and low opacity for chalk halo
        final paintHalo = Paint()
          ..color = baseColor.withValues(alpha: 0.18)
          ..strokeWidth = strokeWidth * 1.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        drawWobblyArc(rect, startAngle, sweepAngle, paintHalo);

        // Second pass: Solid core stroke with 85% opacity
        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.85)
          ..strokeWidth = strokeWidth * 0.9
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintCore);

        // Third pass: Very thin center line representing highest pressure
        final paintPressure = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = strokeWidth * 0.18
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintPressure);
      } else {
        // Default: Authentic Paint Brush Strokes
        drawBristleArc(rect, startAngle, sweepAngle, baseColor);
      }
    }

    if (player == Player.X) {
      if (themeName == 'Rushing Wind') {
        // First stroke: 0.0 to 0.45. Pause: 0.45 to 0.55. Second stroke: 0.55 to 1.0.
        double stroke1Progress = 0.0;
        double stroke2Progress = 0.0;
        if (progress <= 0.45) {
          stroke1Progress = progress / 0.45;
        } else if (progress <= 0.55) {
          stroke1Progress = 1.0;
          stroke2Progress = 0.0;
        } else {
          stroke1Progress = 1.0;
          stroke2Progress = (progress - 0.55) / 0.45;
        }

        if (stroke1Progress > 0) {
          final start = Offset(padding, padding);
          final end = Offset(
              padding + (size.width - 2 * padding) * stroke1Progress,
              padding + (size.height - 2 * padding) * stroke1Progress);
          drawThemedLine(start, end);
        }
        if (stroke2Progress > 0) {
          final start = Offset(size.width - padding, padding);
          final end = Offset((size.width - padding) -
              (size.width - 2 * padding) * stroke2Progress,
              padding + (size.height - 2 * padding) * stroke2Progress);
          drawThemedLine(start, end);
        }
      } else {
        if (progress > 0) {
          double p1 = (progress * 2).clamp(0.0, 1.0);
          final start = Offset(padding, padding);
          final end = Offset(padding + (size.width - 2 * padding) * p1,
              padding + (size.height - 2 * padding) * p1);
          drawThemedLine(start, end);
        }
        if (progress > 0.5) {
          double p2 = ((progress - 0.5) * 2).clamp(0.0, 1.0);
          final start = Offset(size.width - padding, padding);
          final end = Offset(
              (size.width - padding) - (size.width - 2 * padding) * p2,
              padding + (size.height - 2 * padding) * p2);
          drawThemedLine(start, end);
        }
      }
    } else if (player == Player.O) {
      final rect = Rect.fromLTRB(
          padding, padding, size.width - padding, size.height - padding);
      if (themeName == 'Rushing Wind') {
        // Variable speed: accelerate towards bottom, decelerate near top closure
        final double warpedProgress = (progress + 0.08 * sin(progress * 2 * pi))
            .clamp(0.0, 1.0);
        drawThemedArc(rect, -1.5, 6.28 * warpedProgress);
      } else {
        drawThemedArc(rect, -1.5, 6.28 * progress);
      }
    }
  }

  void _drawLadybug(Canvas canvas, Size size, double progress) {
    final double r = size.width * 0.35 * progress;
    if (r <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Red body
    final bodyPaint = Paint()
      ..color = const Color(0xFFE53935)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, r, bodyPaint);

    // 2. Black head
    if (progress > 0.25) {
      final headPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      final headCenter = Offset(center.dx, center.dy - r * 0.85);
      canvas.drawCircle(headCenter, r * 0.38, headPaint);
    }

    // 3. Black separation line
    if (progress > 0.45) {
      final linePaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(center.dx, center.dy - r),
        Offset(center.dx, center.dy + r),
        linePaint,
      );
    }

    // 4. Little black wing spots
    if (progress > 0.65) {
      final dotPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      final double dotRadius = r * 0.15;
      // Left spots
      canvas.drawCircle(
          Offset(center.dx - r * 0.42, center.dy - r * 0.2), dotRadius,
          dotPaint);
      canvas.drawCircle(
          Offset(center.dx - r * 0.48, center.dy + r * 0.25), dotRadius,
          dotPaint);
      // Right spots
      canvas.drawCircle(
          Offset(center.dx + r * 0.42, center.dy - r * 0.2), dotRadius,
          dotPaint);
      canvas.drawCircle(
          Offset(center.dx + r * 0.48, center.dy + r * 0.25), dotRadius,
          dotPaint);
    }

    // 5. White specular gloss shine overlay
    if (progress > 0.35) {
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(center.dx - r * 0.35, center.dy - r * 0.35), r * 0.15,
          shinePaint);
    }

    // 6. Cute antennae
    if (progress > 0.55) {
      final antennaPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      final pathLeft = Path()
        ..moveTo(center.dx - r * 0.2, center.dy - r * 0.95)
        ..quadraticBezierTo(
            center.dx - r * 0.4, center.dy - r * 1.25, center.dx - r * 0.55,
            center.dy - r * 1.15);
      canvas.drawPath(pathLeft, antennaPaint);

      final pathRight = Path()
        ..moveTo(center.dx + r * 0.2, center.dy - r * 0.95)
        ..quadraticBezierTo(
            center.dx + r * 0.4, center.dy - r * 1.25, center.dx + r * 0.55,
            center.dy - r * 1.15);
      canvas.drawPath(pathRight, antennaPaint);
    }
  }

  void _drawDonut(Canvas canvas, Size size, double progress) {
    final center = Offset(size.width / 2, size.height / 2);
    final double r = size.width * 0.35 * progress;
    if (r <= 0) return;
    final double thickness = r * 0.5;

    // 1. Golden-brown pastry base
    final doughPaint = Paint()
      ..color = const Color(0xFFE5A882)
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r - thickness / 2, doughPaint);

    // 2. Thick strawberry glazed frosting layer
    if (progress > 0.3) {
      final glazingPaint = Paint()
        ..color = const Color(0xFFFF4081)
        ..strokeWidth = thickness * 0.72
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, r - thickness / 2, glazingPaint);
    }

    // 3. Specular white shine gloss
    if (progress > 0.4) {
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCircle(
            center: center, radius: r - thickness / 2 - thickness * 0.18),
        -2.2, // angle
        0.8, // sweep angle
        false,
        shinePaint,
      );
    }

    // 4. Colorful sprinkles scattered
    if (progress > 0.65) {
      final List<Color> sprinkleColors = [
        const Color(0xFF00E5FF),
        const Color(0xFF76FF03),
        const Color(0xFFFFEA00),
        Colors.white,
      ];
      final sprinklePaint = Paint()
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 8; i++) {
        final double angle = (i * pi / 4) + 0.25;
        final double radius = r - thickness / 2;
        final Offset sprCenter = Offset(
          center.dx + cos(angle) * radius,
          center.dy + sin(angle) * radius,
        );

        final double sprAngle = angle + 1.25;
        final Offset start = Offset(
          sprCenter.dx - cos(sprAngle) * 3,
          sprCenter.dy - sin(sprAngle) * 3,
        );
        final Offset end = Offset(
          sprCenter.dx + cos(sprAngle) * 3,
          sprCenter.dy + sin(sprAngle) * 3,
        );

        sprinklePaint.color = sprinkleColors[i % sprinkleColors.length];
        canvas.drawLine(start, end, sprinklePaint);
      }
    }
  }

  void _drawStoneX(Canvas canvas, Size size, double progress) {
    final double padding = size.width * 0.22;
    final double strokeWidth = size.width * 0.12 * progress;
    if (strokeWidth <= 0) return;

    void drawStoneLine(Offset p1, Offset p2) {
      // 1. Dark bottom shadow offset
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..strokeWidth = strokeWidth * 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(p1.dx + 2, p1.dy + 2), Offset(p2.dx + 2, p2.dy + 2),
          shadowPaint);

      // 2. Base grey stone plate
      final stonePaint = Paint()
        ..color = const Color(0xFF757575)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, stonePaint);

      // 3. Light specular edge highlights
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..strokeWidth = strokeWidth * 0.25
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(p1.dx - 1, p1.dy - 1), Offset(p2.dx - 1, p2.dy - 1),
          highlightPaint);
    }

    if (progress > 0) {
      double p1 = (progress * 2).clamp(0.0, 1.0);
      final start = Offset(padding, padding);
      final end = Offset(padding + (size.width - 2 * padding) * p1,
          padding + (size.height - 2 * padding) * p1);
      drawStoneLine(start, end);
    }
    if (progress > 0.5) {
      double p2 = ((progress - 0.5) * 2).clamp(0.0, 1.0);
      final start = Offset(size.width - padding, padding);
      final end = Offset(
          (size.width - padding) - (size.width - 2 * padding) * p2,
          padding + (size.height - 2 * padding) * p2);
      drawStoneLine(start, end);
    }
  }

  void _drawStoneO(Canvas canvas, Size size, double progress) {
    final double padding = size.width * 0.22;
    final rect = Rect.fromLTRB(
        padding, padding, size.width - padding, size.height - padding);
    final double strokeWidth = size.width * 0.12 * progress;
    if (strokeWidth <= 0) return;

    // 1. Dark bottom shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth * 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect.shift(const Offset(1, 2)), -1.5, 6.28 * progress, false,
        shadowPaint);

    // 2. White stone ring
    final stonePaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, -1.5, 6.28 * progress, false, stonePaint);

    // 3. Highlight inner bevel sheens
    final highlightPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth * 0.2
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
        rect.shift(const Offset(-0.5, -0.5)), -1.5, 6.28 * progress, false,
        highlightPaint);
  }

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isLarge != isLarge ||
          oldDelegate.baseColor != baseColor ||
          oldDelegate.themeName != themeName;
}

class SubBoardWatermark extends StatelessWidget {
  final Player winner;
  final String themeName;
  final double boardSize;
  final int boardIndex;

  const SubBoardWatermark({
    super.key,
    required this.winner,
    required this.themeName,
    required this.boardSize,
    required this.boardIndex,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: WatermarkPainter(
        winner: winner,
        themeName: themeName,
        boardSize: boardSize,
        boardIndex: boardIndex,
      ),
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final Player winner;
  final String themeName;
  final double boardSize;
  final int boardIndex;

  WatermarkPainter({
    required this.winner,
    required this.themeName,
    required this.boardSize,
    required this.boardIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (themeName.contains('Candy Meadow')) {
      _paintCandyWatermark(canvas, size, center);
    } else if (themeName.contains('Woodville Carve')) {
      _paintWoodvilleWatermark(canvas, size, center);
    } else {
      _paintNeonWatermark(canvas, size, center);
    }
  }

  void _paintCandyWatermark(Canvas canvas, Size size, Offset center) {
    final paintGrid = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double hexRadius = size.width * 0.12;
    final double hexWidth = hexRadius * sqrt(3);
    final double hexHeight = hexRadius * 1.5;

    for (int row = -2; row <= 2; row++) {
      for (int col = -2; col <= 2; col++) {
        final double cx = center.dx + col * hexWidth +
            (row % 2 != 0 ? hexWidth / 2 : 0);
        final double cy = center.dy + row * hexHeight;

        final path = Path();
        for (int i = 0; i < 6; i++) {
          final double angle = i * pi / 3;
          final double px = cx + cos(angle) * hexRadius;
          final double py = cy + sin(angle) * hexRadius;
          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();
        canvas.drawPath(path, paintGrid);
      }
    }

    final beePaint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawOval(Rect.fromCenter(
        center: center, width: size.width * 0.28, height: size.height * 0.18),
        beePaint);

    final wingPaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(
        center.dx - size.width * 0.13, center.dy - size.height * 0.08),
        width: size.width * 0.15,
        height: size.height * 0.22), wingPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(
        center.dx + size.width * 0.13, center.dy - size.height * 0.08),
        width: size.width * 0.15,
        height: size.height * 0.22), wingPaint);
  }

  void _paintWoodvilleWatermark(Canvas canvas, Size size, Offset center) {
    final darkCharcoal = const Color(0xFF271A15).withValues(alpha: 0.38);
    final burntPaint = Paint()
      ..color = darkCharcoal
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    if (winner == Player.X) {
      final double pad = size.width * 0.15;
      canvas.drawLine(
          Offset(pad, pad), Offset(size.width - pad, size.height - pad),
          burntPaint);
      canvas.drawLine(
          Offset(size.width - pad, pad), Offset(pad, size.height - pad),
          burntPaint);
    } else {
      final double pad = size.width * 0.15;
      canvas.drawCircle(center, size.width / 2 - pad, burntPaint);
    }

    final crackPaint = Paint()
      ..color = const Color(0xFF150E0C).withValues(alpha: 0.50)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center,
        Offset(center.dx + size.width * 0.25, center.dy - size.height * 0.15),
        crackPaint);
    canvas.drawLine(center,
        Offset(center.dx - size.width * 0.20, center.dy + size.height * 0.22),
        crackPaint);
  }

  void _paintNeonWatermark(Canvas canvas, Size size, Offset center) {
    final activeColor = winner == Player.X
        ? const Color(0xFFFF007F)
        : const Color(0xFF00FFCC);
    final pulseColor = activeColor.withValues(alpha: 0.15);

    final paintRing = Paint()
      ..color = pulseColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, size.width * 0.4, paintRing);
    canvas.drawCircle(center, size.width * 0.22, paintRing);

    final paintLine = Paint()
      ..color = pulseColor.withValues(alpha: 0.20)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(size.width * 0.05, center.dy),
        Offset(size.width * 0.95, center.dy), paintLine);
    canvas.drawLine(Offset(center.dx, size.height * 0.05),
        Offset(center.dx, size.height * 0.95), paintLine);

    final tickPaint = Paint()
      ..color = pulseColor
      ..strokeWidth = 2.0;
    for (int i = 0; i < 4; i++) {
      final double angle = i * pi / 2;
      final Offset tickStart = Offset(
        center.dx + cos(angle) * size.width * 0.38,
        center.dy + sin(angle) * size.width * 0.38,
      );
      final Offset tickEnd = Offset(
        center.dx + cos(angle) * size.width * 0.42,
        center.dy + sin(angle) * size.width * 0.42,
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }
  }

  @override
  bool shouldRepaint(WatermarkPainter oldDelegate) =>
      oldDelegate.winner != winner || oldDelegate.themeName != themeName ||
          oldDelegate.boardIndex != boardIndex;
}

class AnticipationHaloPainter extends CustomPainter {
  final double pulse;
  final double hover;
  final String themeName;
  final Color activeColor;
  final double boardSize;

  AnticipationHaloPainter({
    required this.pulse,
    required this.hover,
    required this.themeName,
    required this.activeColor,
    required this.boardSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    if (themeName.contains('Candy Meadow')) {
      _paintCandyHalo(canvas, size, center, radius);
    } else if (themeName.contains('Woodville Carve')) {
      _paintWoodvilleHalo(canvas, size, center, radius);
    } else if (themeName.contains('Rushing Wind') ||
        themeName.contains('Floating Feather') ||
        themeName.contains('Rising Moon') ||
        themeName.contains('Drifting Cloud') ||
        themeName.contains('Crimson Leaf')) {
      _paintNatureHalo(canvas, size, center, radius);
    } else {
      _paintNeonHalo(canvas, size, center, radius);
    }
  }

  void _paintNatureHalo(Canvas canvas, Size size, Offset center,
      double radius) {
    // 1. Soft Powdery Ambient Glow in center matching the chalk color
    final paintGlow = Paint()
      ..color = activeColor.withValues(
          alpha: 0.08 + pulse * 0.08 + hover * 0.22)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    canvas.drawCircle(center, radius * (0.42 + pulse * 0.15), paintGlow);

    // 2. Hand-drawn wobbly chalk circle/highlight on hover
    if (hover > 0.05) {
      final double baseStrokeWidth = boardSize * 0.008;
      final double strokeWidth = baseStrokeWidth.clamp(1.5, 6.0);
      final paintHighlight = Paint()
        ..color = activeColor.withValues(alpha: 0.5 * hover)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw a wobbly hand-drawn soft chalk ring around the cell center
      final double r = radius * 0.58;
      final int segments = 24;
      final path = Path();
      final random = Random(themeName.hashCode);

      for (int i = 0; i <= segments; i++) {
        final double angle = i * 2 * pi / segments;
        final double wobble = sin(angle * 6) * (radius * 0.025) +
            (random.nextDouble() - 0.5) * (radius * 0.015);
        final double x = center.dx + cos(angle) * (r + wobble);
        final double y = center.dy + sin(angle) * (r + wobble);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paintHighlight);
    }
  }

  void _paintNeonHalo(Canvas canvas, Size size, Offset center, double radius) {
    final double strokeWidth = boardSize * 0.008;

    // 1. Pulsing Ambient Halo Glow
    final double currentRadius = radius * (0.45 + pulse * 0.22);
    final paintGlow = Paint()
      ..color = activeColor.withValues(
          alpha: (0.08 + pulse * 0.12 + hover * 0.28).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.35);
    canvas.drawCircle(center, currentRadius, paintGlow);

    // 2. High-Tech Laser Radar Ring (only visible or flares up on hover)
    if (hover > 0.05) {
      final paintRing = Paint()
        ..color = activeColor.withValues(alpha: 0.7 * hover)
        ..strokeWidth = strokeWidth * 0.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius * 0.62, paintRing);

      // Tech Crosshair Tick Lines
      final paintTick = Paint()
        ..color = activeColor.withValues(alpha: 0.9 * hover)
        ..strokeWidth = strokeWidth * 1.2;
      for (int i = 0; i < 4; i++) {
        final double angle = i * pi / 2;
        final Offset start = Offset(
          center.dx + cos(angle) * radius * 0.52,
          center.dy + sin(angle) * radius * 0.52,
        );
        final Offset end = Offset(
          center.dx + cos(angle) * radius * 0.72,
          center.dy + sin(angle) * radius * 0.72,
        );
        canvas.drawLine(start, end, paintTick);
      }
    }

    // 3. Corner Brackets (Tech locking frame)
    final double margin = radius *
        (0.28 - hover * 0.15); // moves outward as hovered
    final double bracketLen = radius * 0.22;
    final paintBracket = Paint()
      ..color = activeColor.withValues(
          alpha: (0.15 + hover * 0.75).clamp(0.0, 1.0))
      ..strokeWidth = strokeWidth * 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-Left
    final pathTL = Path()
      ..moveTo(margin, margin + bracketLen)
      ..lineTo(margin, margin)..lineTo(margin + bracketLen, margin);
    canvas.drawPath(pathTL, paintBracket);

    // Top-Right
    final pathTR = Path()
      ..moveTo(size.width - margin, margin + bracketLen)
      ..lineTo(size.width - margin, margin)..lineTo(
          size.width - margin - bracketLen, margin);
    canvas.drawPath(pathTR, paintBracket);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(margin, size.height - margin - bracketLen)
      ..lineTo(margin, size.height - margin)..lineTo(
          margin + bracketLen, size.height - margin);
    canvas.drawPath(pathBL, paintBracket);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(size.width - margin, size.height - margin - bracketLen)
      ..lineTo(size.width - margin, size.height - margin)..lineTo(
          size.width - margin - bracketLen, size.height - margin);
    canvas.drawPath(pathBR, paintBracket);
  }

  void _paintCandyHalo(Canvas canvas, Size size, Offset center, double radius) {
    // 1. Warm pink/gold blossom ring
    final glowColor = const Color(0xFFFF4081).withValues(
        alpha: 0.12 + 0.15 * pulse + 0.25 * hover);
    final coreColor = const Color(0xFFFFEB3B).withValues(
        alpha: 0.25 + 0.45 * hover);

    final paintGlow = Paint()
      ..color = glowColor
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.3);
    canvas.drawCircle(center, radius * (0.45 + pulse * 0.15), paintGlow);

    // Honeycomb/Blossom Outline on hover
    if (hover > 0.05) {
      final paintPetals = Paint()
        ..color = coreColor
        ..strokeWidth = 2.0 * hover
        ..style = PaintingStyle.stroke;

      final path = Path();
      const int petals = 6;
      final double rMax = radius * (0.65 + pulse * 0.05);
      final double rMin = radius * 0.45;
      for (int i = 0; i <= petals; i++) {
        final double angle = i * 2 * pi / petals;
        final double midAngle = (i + 0.5) * 2 * pi / petals;
        final double px = center.dx + cos(angle) * rMin;
        final double py = center.dy + sin(angle) * rMin;
        final double mx = center.dx + cos(midAngle) * rMax;
        final double my = center.dy + sin(midAngle) * rMax;
        final double nextPx = center.dx + cos((i + 1) * 2 * pi / petals) * rMin;
        final double nextPy = center.dy + sin((i + 1) * 2 * pi / petals) * rMin;

        if (i == 0) {
          path.moveTo(px, py);
        }
        path.quadraticBezierTo(mx, my, nextPx, nextPy);
      }
      canvas.drawPath(path, paintPetals);
    }

    // Cute sweet sugar drop sparks around
    final double sparkRadius = radius * 0.72;
    final paintSpark = Paint()
      ..style = PaintingStyle.fill;
    final int numSparks = 5;
    for (int i = 0; i < numSparks; i++) {
      final double angle = (i * 2 * pi / numSparks) + pulse * 0.8;
      final double x = center.dx + cos(angle) * sparkRadius;
      final double y = center.dy + sin(angle) * sparkRadius;
      final double sizeVal = (3.0 + 3.0 * sin(pulse * pi + i)) *
          (0.5 + 0.5 * hover);
      paintSpark.color = i % 2 == 0
          ? const Color(0xFF00E5FF).withValues(alpha: 0.4 + 0.4 * hover)
          : const Color(0xFFFFEA00).withValues(alpha: 0.4 + 0.4 * hover);
      canvas.drawCircle(Offset(x, y), sizeVal, paintSpark);
    }
  }

  void _paintWoodvilleHalo(Canvas canvas, Size size, Offset center,
      double radius) {
    // Runic amber glowing aura
    final amberColor = const Color(0xFFE65100);
    final coreAmber = const Color(0xFFFFB300);

    final paintGlow = Paint()
      ..color = amberColor.withValues(alpha: 0.1 + 0.15 * pulse + 0.3 * hover)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    canvas.drawCircle(center, radius * (0.42 + pulse * 0.12), paintGlow);

    // Glowing warm molten amber cracks inside the cell borders
    final double margin = radius * 0.2;
    final paintCracks = Paint()
      ..color = coreAmber.withValues(alpha: 0.3 + 0.7 * hover)
      ..strokeWidth = 1.5 + 1.5 * hover
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double step = radius * 0.3;
    final double crackOffset = sin(pulse * pi) * 2.0;

    // Top-Left crack
    final pathTL = Path()
      ..moveTo(margin, margin)
      ..lineTo(margin + step + crackOffset, margin + crackOffset)..lineTo(
          margin + step * 0.5, margin + step * 0.7);
    canvas.drawPath(pathTL, paintCracks);

    // Bottom-Right crack
    final pathBR = Path()
      ..moveTo(size.width - margin, size.height - margin)
      ..lineTo(size.width - margin - step - crackOffset,
          size.height - margin - crackOffset)..lineTo(
          size.width - margin - step * 0.6, size.height - margin - step * 0.8);
    canvas.drawPath(pathBR, paintCracks);

    // Runic ring in center on hover
    if (hover > 0.05) {
      final paintRunicRing = Paint()
        ..color = coreAmber.withValues(alpha: 0.65 * hover)
        ..strokeWidth = 2.0 * hover
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius * 0.58, paintRunicRing);

      // Dash runes
      final runePaint = Paint()
        ..color = coreAmber.withValues(alpha: 0.85 * hover)
        ..strokeWidth = 2.5 * hover;
      for (int i = 0; i < 8; i++) {
        final double angle = i * pi / 4 + pulse * 0.2;
        final Offset start = Offset(
          center.dx + cos(angle) * radius * 0.52,
          center.dy + sin(angle) * radius * 0.52,
        );
        final Offset end = Offset(
          center.dx + cos(angle) * radius * 0.64,
          center.dy + sin(angle) * radius * 0.64,
        );
        canvas.drawLine(start, end, runePaint);
      }
    }
  }

  @override
  bool shouldRepaint(AnticipationHaloPainter oldDelegate) =>
      oldDelegate.pulse != pulse || oldDelegate.hover != hover ||
          oldDelegate.themeName != themeName ||
          oldDelegate.activeColor != activeColor;
}

class ClayBevelPainter extends CustomPainter {
  final double borderRadius;
  final Color baseColor;
  final String themeName;

  ClayBevelPainter({
    required this.borderRadius,
    required this.baseColor,
    required this.themeName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final deflated = rrect.deflate(
        1.0); // Inset slightly to hug the inner curve perfectly

    final paintLight = Paint()
      ..color = NeumorphicColors.getLightShadow(
          baseColor) // Dynamic soft highlight catcher
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDark = Paint()
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(
          alpha: 0.65) // Deep sharp bevel shadow
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-Left Bevel Path (starts from bottom-left corner and travels around the curve to the top-right corner)
    final pathLight = Path()
      ..moveTo(deflated.left, deflated.bottom - deflated.blRadiusY)
      ..lineTo(deflated.left, deflated.top + deflated.tlRadiusY)
      ..quadraticBezierTo(
          deflated.left, deflated.top, deflated.left + deflated.tlRadiusX,
          deflated.top)
      ..lineTo(deflated.right - deflated.trRadiusX, deflated.top);

    // Bottom-Right Bevel Path (starts from top-right corner and travels around the curve to the bottom-left corner)
    final pathDark = Path()
      ..moveTo(deflated.right - deflated.trRadiusX, deflated.top)
      ..quadraticBezierTo(deflated.right, deflated.top, deflated.right,
          deflated.top + deflated.trRadiusY)
      ..lineTo(deflated.right, deflated.bottom - deflated.brRadiusY)
      ..quadraticBezierTo(
          deflated.right, deflated.bottom, deflated.right - deflated.brRadiusX,
          deflated.bottom)
      ..lineTo(deflated.left + deflated.blRadiusX, deflated.bottom)
      ..quadraticBezierTo(deflated.left, deflated.bottom, deflated.left,
          deflated.bottom - deflated.blRadiusY);

    canvas.drawPath(pathLight, paintLight);
    canvas.drawPath(pathDark, paintDark);
  }

  @override
  bool shouldRepaint(ClayBevelPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
          oldDelegate.baseColor != baseColor ||
          oldDelegate.themeName != themeName;
}

class DebossedGridPainter extends CustomPainter {
  final Color baseColor;
  final String themeName;
  final double padding;

  DebossedGridPainter({
    required this.baseColor,
    required this.themeName,
    required this.padding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (themeName != 'Rushing Wind' &&
        themeName != 'Floating Feather' &&
        themeName != 'Rising Moon' &&
        themeName != 'Drifting Cloud' &&
        themeName != 'Crimson Leaf') {
      return; // only draw for nature themes!
    }

    final double w = size.width;
    final double h = size.height;

    // Grid coordinates (exact cell boundaries)
    final double x1 = w / 3;
    final double x2 = 2 * w / 3;
    final double y1 = h / 3;
    final double y2 = 2 * h / 3;

    // Lines start slightly into the outer padding area to give the elegant carved cap look from the design mockup
    final double lineStart = -padding * 0.55;
    final double lineEndW = w + (padding * 0.55);
    final double lineEndH = h + (padding * 0.55);

    // Carved groove styling:
    // 1. Dark shadow crease (base layer to ground the groove depth)
    final paintBase = Paint()
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(
          alpha: 0.45) // Deepened crease
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal, 1.2); // Tighter blur for deeper look

    // 2. Dark inner shadow (inset top-left shadow)
    final paintDark = Paint()
      ..color = NeumorphicColors.getDarkShadow(baseColor).withValues(
          alpha: 0.75) // Sharp dark inner shadow
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 3. Bright inner light catcher (inset bottom-right highlight)
    final paintLight = Paint()
      ..color = NeumorphicColors.getLightShadow(baseColor).withValues(
          alpha: 0.45) // Softer nature highlight blend
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawCarvedLine(Offset p1, Offset p2) {
      // Draw base dark crease
      canvas.drawLine(p1, p2, paintBase);

      // Draw dark shadow line (offset top-left: -0.7, -0.7)
      canvas.drawLine(
        Offset(p1.dx - 0.7, p1.dy - 0.7),
        Offset(p2.dx - 0.7, p2.dy - 0.7),
        paintDark,
      );

      // Draw light catching line (offset bottom-right: 0.7, 0.7)
      canvas.drawLine(
        Offset(p1.dx + 0.7, p1.dy + 0.7),
        Offset(p2.dx + 0.7, p2.dy + 0.7),
        paintLight,
      );
    }

    // Horizontal lines
    drawCarvedLine(Offset(lineStart, y1), Offset(lineEndW, y1));
    drawCarvedLine(Offset(lineStart, y2), Offset(lineEndW, y2));

    // Vertical lines
    drawCarvedLine(Offset(x1, lineStart), Offset(x1, lineEndH));
    drawCarvedLine(Offset(x2, lineStart), Offset(x2, lineEndH));
  }

  @override
  bool shouldRepaint(DebossedGridPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
          oldDelegate.themeName != themeName ||
          oldDelegate.padding != padding;
}
