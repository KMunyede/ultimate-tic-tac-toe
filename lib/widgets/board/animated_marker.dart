// lib/widgets/board/animated_marker.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../features/settings/logic/settings_controller.dart';

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
    // Calculate stroke width dynamically and proportionally without restrictive static clamps
    final double strokeFactor = isLarge ? 0.12 : 0.045;
    final double strokeWidth = (boardSize * strokeFactor).clamp(1.5, 45.0);

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
      } else if (themeName == 'Amazon Jungle') {
        // 1. Draw a wobbly mahogany dark shadow shifted down-right
        final paintShadow = Paint()
          ..color = const Color(0xFF1B0F0D).withValues(alpha: 0.65)
          ..strokeWidth = strokeWidth * 1.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(Offset(p1.dx + 2.0, p1.dy + 3.0), Offset(p2.dx + 2.0, p2.dy + 3.0), paintShadow);

        // 2. Draw the main wobbly stone log (light grey with high texture)
        final paintStone = Paint()
          ..color = const Color(0xFFCFD8DC)
          ..strokeWidth = strokeWidth * 1.3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintStone);

        // 3. Draw a thin white sunbeam highlight sheen on the top-left edge
        final paintHighlight = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..strokeWidth = strokeWidth * 0.22
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(Offset(p1.dx - 1.0, p1.dy - 1.0), Offset(p2.dx - 1.0, p2.dy - 1.0), paintHighlight);

        // 4. Draw a gold spotlight reflection on the log representing dapples of sunlight!
        final paintGoldBeam = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45)
          ..strokeWidth = strokeWidth * 0.4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(Offset(p1.dx + 0.5, p1.dy + 0.5), Offset(p2.dx + 0.5, p2.dy + 0.5), paintGoldBeam);

        // 5. Draw 3D wobbly branching cracks pressed into the stone
        final paintCrackShadow = Paint()
          ..color = const Color(0xFF90A4AE).withValues(alpha: 0.5)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        final paintCrackCore = Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round;
        
        final Offset mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final Offset dx = Offset((p2.dx - p1.dx) * 0.15, (p2.dy - p1.dy) * 0.15);
        final Offset dy = Offset(-(p2.dy - p1.dy) * 0.15, (p2.dx - p1.dx) * 0.15);
        
        // Left crack branch
        canvas.drawLine(mid, mid + dx + dy * 0.6, paintCrackShadow);
        canvas.drawLine(mid, mid + dx + dy * 0.6, paintCrackCore);
        // Right crack branch
        canvas.drawLine(mid - dx * 0.8, mid - dx * 0.8 - dy * 0.5, paintCrackShadow);
        canvas.drawLine(mid - dx * 0.8, mid - dx * 0.8 - dy * 0.5, paintCrackCore);

        // 6. Paint fluffy layered moss clusters at both ends of the log
        final paintMossDark = Paint()
          ..color = const Color(0xFF1B5E20).withValues(alpha: 0.9)
          ..style = PaintingStyle.fill;
        final paintMossMedium = Paint()
          ..color = const Color(0xFF2E7D32).withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;
        final paintMossLight = Paint()
          ..color = const Color(0xFF8BC34A).withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

        // Fluffy volumetric moss puff at start (p1)
        canvas.drawCircle(Offset(p1.dx + 2, p1.dy - 2), strokeWidth * 0.35, paintMossDark);
        canvas.drawCircle(Offset(p1.dx - 1, p1.dy + 1), strokeWidth * 0.28, paintMossMedium);
        canvas.drawCircle(Offset(p1.dx + 1, p1.dy + 2), strokeWidth * 0.22, paintMossLight);
        canvas.drawCircle(Offset(p1.dx - 3, p1.dy - 1), strokeWidth * 0.18, paintMossLight);

        // Fluffy volumetric moss puff at end (p2)
        canvas.drawCircle(Offset(p2.dx - 2, p2.dy + 1), strokeWidth * 0.32, paintMossDark);
        canvas.drawCircle(Offset(p2.dx + 1, p2.dy - 1), strokeWidth * 0.26, paintMossMedium);
        canvas.drawCircle(Offset(p2.dx - 1, p2.dy - 2), strokeWidth * 0.20, paintMossLight);
        canvas.drawCircle(Offset(p2.dx + 2, p2.dy + 2), strokeWidth * 0.16, paintMossLight);
      } else if (themeName == 'Rushing Wind') {
        // chalk halo
        final paintHalo = Paint()
          ..color = baseColor.withValues(alpha: 0.18)
          ..strokeWidth = strokeWidth * 1.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        drawWobblyLine(p1, p2, paintHalo);

        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.85)
          ..strokeWidth = strokeWidth * 0.9
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyLine(p1, p2, paintCore);

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
      } else if (themeName == 'Amazon Jungle') {
        // 1. Draw wobbly mahogany dark shadow shifted down-right
        final paintShadow = Paint()
          ..color = const Color(0xFF1B0F0D).withValues(alpha: 0.65)
          ..strokeWidth = strokeWidth * 1.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        final offsetRect = rect.shift(const Offset(2.0, 3.0));
        drawWobblyArc(offsetRect, startAngle, sweepAngle, paintShadow);

        // 2. Draw the main wobbly wood ring (rich mahogany brown)
        final paintWood = Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = strokeWidth * 1.3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintWood);

        // 3. Draw wood grain (multiple toned wobbly concentric lines inside/outside wood)
        final paintGrainDark = Paint()
          ..color = const Color(0xFF3E2723).withValues(alpha: 0.8)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        final paintGrainLight = Paint()
          ..color = const Color(0xFF8D6E63).withValues(alpha: 0.5)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;

        drawWobblyArc(rect.deflate(strokeWidth * 0.22), startAngle, sweepAngle, paintGrainDark);
        drawWobblyArc(rect.inflate(strokeWidth * 0.22), startAngle, sweepAngle, paintGrainDark);
        drawWobblyArc(rect.deflate(strokeWidth * 0.1), startAngle, sweepAngle, paintGrainLight);
        drawWobblyArc(rect.inflate(strokeWidth * 0.1), startAngle, sweepAngle, paintGrainLight);

        // 4. Paint fluffy wobbly green moss clumps that grow as the arc sweeps
        final double cx = rect.center.dx;
        final double cy = rect.center.dy;
        final double rx = rect.width / 2;
        final double ry = rect.height / 2;
        
        final paintMossDark = Paint()
          ..color = const Color(0xFF1B5E20).withValues(alpha: 0.95)
          ..style = PaintingStyle.fill;
        final paintMossMedium = Paint()
          ..color = const Color(0xFF2E7D32).withValues(alpha: 0.9)
          ..style = PaintingStyle.fill;
        final paintMossLight = Paint()
          ..color = const Color(0xFF8BC34A).withValues(alpha: 0.85)
          ..style = PaintingStyle.fill;

        final List<double> mossAngles = [-1.0, 0.2, 1.4, 2.6, 3.8, 4.5];
        for (double angle in mossAngles) {
          final double targetProgressAngle = startAngle + sweepAngle;
          if (angle <= targetProgressAngle) {
            final double mx = cx + cos(angle) * rx;
            final double my = cy + sin(angle) * ry;
            
            // Overlapping fluffy multi-layered moss structure
            canvas.drawCircle(Offset(mx, my), strokeWidth * 0.42, paintMossDark);
            canvas.drawCircle(Offset(mx + sin(angle * 10) * 2, my + cos(angle * 10) * 2), strokeWidth * 0.32, paintMossMedium);
            canvas.drawCircle(Offset(mx - sin(angle * 5) * 3, my - cos(angle * 5) * 3), strokeWidth * 0.26, paintMossLight);
            canvas.drawCircle(Offset(mx + cos(angle * 8) * 4, my - sin(angle * 8) * 1), strokeWidth * 0.18, paintMossLight);
          }
        }
      } else if (themeName == 'Rushing Wind') {
        final paintHalo = Paint()
          ..color = baseColor.withValues(alpha: 0.18)
          ..strokeWidth = strokeWidth * 1.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        drawWobblyArc(rect, startAngle, sweepAngle, paintHalo);

        final paintCore = Paint()
          ..color = baseColor.withValues(alpha: 0.85)
          ..strokeWidth = strokeWidth * 0.9
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        drawWobblyArc(rect, startAngle, sweepAngle, paintCore);

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

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isLarge != isLarge ||
          oldDelegate.baseColor != baseColor ||
          oldDelegate.themeName != themeName;
}
