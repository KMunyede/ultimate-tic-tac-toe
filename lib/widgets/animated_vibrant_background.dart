// lib/widgets/animated_vibrant_background.dart

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/settings/logic/settings_controller.dart';
import '../core/theme/app_theme.dart';

class AnimatedVibrantBackground extends StatefulWidget {
  final Widget child;

  const AnimatedVibrantBackground({super.key, required this.child});

  @override
  State<AnimatedVibrantBackground> createState() => _AnimatedVibrantBackgroundState();
}

class _AnimatedVibrantBackgroundState extends State<AnimatedVibrantBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Stopwatch _stopwatch;
  ui.Picture? _cachedTexture;
  Size? _lastSize;
  AppTheme? _lastTheme;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _cachedTexture?.dispose();
    super.dispose();
  }

  void _updateCache(Size size, AppTheme theme) {
    if (_cachedTexture != null && _lastSize == size && _lastTheme == theme) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    if (theme.name == 'Rushing Wind') {
      final rand = Random(42);
      final stipplePaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 1800; i++) {
        final double rx = rand.nextDouble() * size.width;
        final double ry = rand.nextDouble() * size.height;
        final double radius = 0.4 + rand.nextDouble() * 0.7;
        final double opacity = 0.01 + rand.nextDouble() * 0.035;
        
        final Color stippleColor = rand.nextBool()
            ? theme.textColor.withValues(alpha: opacity)
            : theme.mainColor.withValues(alpha: opacity * 0.5);
            
        stipplePaint.color = stippleColor;
        canvas.drawCircle(Offset(rx, ry), radius, stipplePaint);
      }
      
      final fiberPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
        
      for (int i = 0; i < 180; i++) {
        final double startX = rand.nextDouble() * size.width;
        final double startY = rand.nextDouble() * size.height;
        final double length = 4.0 + rand.nextDouble() * 9.0;
        final double angle = rand.nextDouble() * 2 * pi;
        
        final double endX = startX + cos(angle) * length;
        final double endY = startY + sin(angle) * length;
        
        final double opacity = 0.01 + rand.nextDouble() * 0.025;
        final double strokeWidth = 0.45 + rand.nextDouble() * 0.4;
        
        fiberPaint
          ..color = theme.textColor.withValues(alpha: opacity)
          ..strokeWidth = strokeWidth;
          
        final double midX = (startX + endX) / 2 + (rand.nextDouble() - 0.5) * 1.5;
        final double midY = (startY + endY) / 2 + (rand.nextDouble() - 0.5) * 1.5;
        
        final fiberPath = Path()
          ..moveTo(startX, startY)
          ..quadraticBezierTo(midX, midY, endX, endY);
          
        canvas.drawPath(fiberPath, fiberPaint);
      }
    }

    _cachedTexture?.dispose();
    _cachedTexture = recorder.endRecording();
    _lastSize = size;
    _lastTheme = theme;
  }

  @override
  Widget build(BuildContext context) {
    // Optimization: Use select to only rebuild when necessary
    final settings = context.select<SettingsController, ({AppTheme theme, bool lowDetailMode})>(
      (s) => (theme: s.currentTheme, lowDetailMode: s.lowDetailMode)
    );
    
    final theme = settings.theme;

    if (settings.lowDetailMode) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: BackgroundMeshPainter(
            time: 0.0,
            theme: theme,
            lowDetailMode: true,
          ),
          child: widget.child,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final double elapsedSeconds = _stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
        return RepaintBoundary(
          child: CustomPaint(
            painter: BackgroundMeshPainter(
              time: elapsedSeconds / 18.0,
              theme: theme,
              lowDetailMode: false,
              textureCache: _cachedTexture,
              onSizeChanged: (size) => WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _updateCache(size, theme));
              }),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class BackgroundMeshPainter extends CustomPainter {
  final double time;
  final AppTheme theme;
  final bool lowDetailMode;
  final ui.Picture? textureCache;
  final Function(Size)? onSizeChanged;

  // Pre-allocated Paint and Path objects to reduce GC pressure and frame skip
  final Paint _wavePaint = Paint();
  final Paint _leafPaint = Paint();
  final Paint _veinPaint = Paint();
  final Paint _trunkPaint = Paint();
  final Paint _bgPaint = Paint();
  final Paint _sunPaint = Paint();
  final Paint _birdPaint = Paint();
  final Paint _glitterPaint = Paint();
  final Path _wavePath = Path();
  final Path _leafPath = Path();
  final Path _birdPath = Path();

  BackgroundMeshPainter({
    required this.time,
    required this.theme,
    required this.lowDetailMode,
    this.textureCache,
    this.onSizeChanged,
  });

  void drawBambooLeaf(Canvas canvas, Offset stem, double angle, double scale, Color color, {bool isShadow = false, bool isDualTone = false, Color? outlineColor}) {
    _leafPaint
      ..color = color
      ..style = PaintingStyle.fill;
    
    if (isShadow) {
      _leafPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    } else {
      _leafPaint.maskFilter = null;
    }

    canvas.save();
    canvas.translate(stem.dx, stem.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    
    _leafPath.reset();
    _leafPath.moveTo(0, 0);
    _leafPath.quadraticBezierTo(-7, -15, -5, -35);
    _leafPath.quadraticBezierTo(-2.5, -50, 0, -65);
    _leafPath.quadraticBezierTo(2.5, -50, 5, -35);
    _leafPath.quadraticBezierTo(7, -15, 0, 0);
    _leafPath.close();
    
    canvas.drawPath(_leafPath, _leafPaint);

    if (!isShadow) {
      final veinColor = isDualTone && outlineColor != null ? outlineColor.withValues(alpha: 0.60) : color.withValues(alpha: color.a * 0.40);
      _veinPaint
        ..color = veinColor
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset.zero, const Offset(0, -60), _veinPaint);
      if (isDualTone && outlineColor != null) {
        _veinPaint
          ..color = outlineColor
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawPath(_leafPath, _veinPaint);
      }
    }
    canvas.restore();
  }

  void drawLeafCluster(Canvas canvas, Offset pos, double angle, double time, Color color, {bool isShadow = false, bool isDualTone = false, Color? outlineColor}) {
    final double leafSway = sin(time * 2.0 * pi + pos.dx * 0.05) * 0.08;
    drawBambooLeaf(canvas, pos, angle + leafSway, 2.6, color, isShadow: isShadow, isDualTone: isDualTone, outlineColor: outlineColor);
    final Offset stemOffsetL = Offset(cos(angle - pi / 2) * -28, sin(angle - pi / 2) * -28);
    drawBambooLeaf(canvas, pos + stemOffsetL, angle - 0.80 + leafSway * 0.7, 2.1, color, isShadow: isShadow, isDualTone: isDualTone, outlineColor: outlineColor);
    final Offset stemOffsetR = Offset(cos(angle + pi / 2) * 28, sin(angle + pi / 2) * 28);
    drawBambooLeaf(canvas, pos + stemOffsetR, angle + 0.80 + leafSway * 1.1, 2.2, color, isShadow: isShadow, isDualTone: isDualTone, outlineColor: outlineColor);
  }

  void drawTreeTrunk(Canvas canvas, Offset start, Offset control, Offset end, double startWidth, double endWidth, Color color, {bool isShadow = false}) {
    _trunkPaint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    if (isShadow) {
      _trunkPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    } else {
      _trunkPaint.maskFilter = null;
    }

    const int segments = 12; // Optimized: further reduced
    Offset last = start;
    for (int i = 1; i <= segments; i++) {
      final double t = i / segments;
      final double invT = 1 - t;
      final double x = invT * invT * start.dx + 2 * invT * t * control.dx + t * t * end.dx;
      final double y = invT * invT * start.dy + 2 * invT * t * control.dy + t * t * end.dy;
      final Offset current = Offset(x, y);
      _trunkPaint.strokeWidth = startWidth + (endWidth - startWidth) * t;
      canvas.drawLine(last, current, _trunkPaint);
      last = current;
    }
  }

  void drawOrganicCanopy(Canvas canvas, Offset origin, double baseAngle, double scale, double time, Color woodColor, {bool isShadow = false}) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(baseAngle);
    canvas.scale(scale);
    final double s1 = sin(time * 2.0 * pi) * 0.03;
    final Offset start = Offset.zero;
    final Offset control = Offset(45, -65 + sin(time * pi) * 3);
    final Offset end = Offset(85 + sin(time * 2.0 * pi + 0.5) * 5, -125 + cos(time * 2.0 * pi) * 4);
    final shadowColor = Colors.black.withValues(alpha: 0.08);
    final Color trunkColor = isShadow ? shadowColor : woodColor;
    drawTreeTrunk(canvas, start, control, end, 16.0, 5.0, trunkColor, isShadow: isShadow);
    final double sTwig1 = sin(time * 2.0 * pi + 0.8) * 0.04;
    final Offset twigStart1 = Offset((1 - 0.35) * (1 - 0.35) * start.dx + 2 * (1 - 0.35) * 0.35 * control.dx + 0.35 * 0.35 * end.dx, (1 - 0.35) * (1 - 0.35) * start.dy + 2 * (1 - 0.35) * 0.35 * control.dy + 0.35 * 0.35 * end.dy);
    final Offset twigEnd1 = Offset(twigStart1.dx - 48, twigStart1.dy - 38 + sTwig1 * 10);
    final Offset twigControl1 = Offset(twigStart1.dx - 25, twigStart1.dy - 15);
    drawTreeTrunk(canvas, twigStart1, twigControl1, twigEnd1, 5.5, 2.0, trunkColor, isShadow: isShadow);
    final double sTwig2 = sin(time * 2.0 * pi + 1.4) * 0.04;
    final Offset twigStart2 = Offset((1 - 0.65) * (1 - 0.65) * start.dx + 2 * (1 - 0.65) * 0.65 * control.dx + 0.65 * 0.65 * end.dx, (1 - 0.65) * (1 - 0.65) * start.dy + 2 * (1 - 0.65) * 0.65 * control.dy + 0.65 * 0.65 * end.dy);
    final Offset twigEnd2 = Offset(twigStart2.dx + 48, twigStart2.dy - 28 + sTwig2 * 10);
    final Offset twigControl2 = Offset(twigStart2.dx + 25, twigStart2.dy - 10);
    drawTreeTrunk(canvas, twigStart2, twigControl2, twigEnd2, 4.5, 1.8, trunkColor, isShadow: isShadow);
    final double sTwig3 = sin(time * 2.0 * pi + 2.0) * 0.04;
    final Offset twigStart3 = Offset((1 - 0.82) * (1 - 0.82) * start.dx + 2 * (1 - 0.82) * 0.82 * control.dx + 0.82 * 0.82 * end.dx, (1 - 0.82) * (1 - 0.82) * start.dy + 2 * (1 - 0.82) * 0.82 * control.dy + 0.82 * 0.82 * end.dy);
    final Offset twigEnd3 = Offset(twigStart3.dx - 22, twigStart3.dy - 38 + sTwig3 * 8);
    final Offset twigControl3 = Offset(twigStart3.dx - 10, twigStart3.dy - 20);
    drawTreeTrunk(canvas, twigStart3, twigControl3, twigEnd3, 3.5, 1.5, trunkColor, isShadow: isShadow);
    if (!isShadow) {
      final Color leafColor = const Color(0xFF5C6F56);
      final Color leafOutline = const Color(0xFF86997F);
      drawLeafCluster(canvas, end, s1, time, leafColor, isShadow: false, isDualTone: true, outlineColor: leafOutline);
      drawLeafCluster(canvas, twigEnd1, sTwig1 - pi / 3.5, time, leafColor, isShadow: false, isDualTone: true, outlineColor: leafOutline);
      drawLeafCluster(canvas, twigEnd2, sTwig2 + pi / 3.5, time, leafColor, isShadow: false, isDualTone: true, outlineColor: leafOutline);
      drawLeafCluster(canvas, twigEnd3, sTwig3 - pi / 4.5, time, leafColor, isShadow: false, isDualTone: true, outlineColor: leafOutline);
    } else {
      final Color shadowColorL = Colors.black.withValues(alpha: 0.05);
      drawLeafCluster(canvas, end, s1, time, shadowColorL, isShadow: true);
      drawLeafCluster(canvas, twigEnd1, sTwig1 - pi / 3.5, time, shadowColorL, isShadow: true);
      drawLeafCluster(canvas, twigEnd2, sTwig2 + pi / 3.5, time, shadowColorL, isShadow: true);
      drawLeafCluster(canvas, twigEnd3, sTwig3 - pi / 4.5, time, shadowColorL, isShadow: true);
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (onSizeChanged != null) onSizeChanged!(size);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    _bgPaint.shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: theme.bgGradient).createShader(rect);
    canvas.drawRect(rect, _bgPaint);

    if (textureCache != null) {
      canvas.drawPicture(textureCache!);
    }

    if (lowDetailMode) return;

    // Optimization: reduced water layers and points for high-performance waves
    const int points = 18; // Further reduced from 20
    for (int layer = 0; layer < 3; layer++) { // Reduced from 4
      final double depthAlpha = 1.0 - (layer / 4.0);
      final double waveSpeed = theme.name == 'Rushing Wind' ? 0.05 + (layer * 0.015) : 0.3 + (layer * 0.12);
      final double amplitude = theme.name == 'Rushing Wind' ? 10.0 - (layer * 0.6) : 22.0 - (layer * 1.8);
      final double frequency = 1.2 + (layer * 0.35);
      final double verticalOffset = size.height * 0.22 + (layer * size.height * 0.07);
      
      _wavePath.reset();
      _wavePath.moveTo(0, size.height);
      _wavePath.lineTo(0, verticalOffset);
      for (int i = 0; i <= points; i++) {
        final double ratio = i / points;
        final double x = ratio * size.width;
        final double y = verticalOffset + sin(ratio * pi * frequency + time * 2 * pi * waveSpeed) * amplitude + cos(ratio * pi * (frequency * 0.8) - time * pi * (waveSpeed * 0.7)) * (amplitude * 0.5);
        _wavePath.lineTo(x, y);
      }
      _wavePath.lineTo(size.width, size.height);
      _wavePath.close();

      Color waveColor;
      if (theme.name == 'Rushing Wind') {
        const List<Color> colors = [Color(0xFF1B365D), Color(0xFF2E5B82), Color(0xFF4A90E2), Color(0xFF6BA4E8)];
        waveColor = colors[layer % colors.length];
      } else {
        waveColor = layer % 3 == 0 ? theme.mainColor : (layer % 3 == 1 ? theme.accentGlow : Colors.white);
      }
      final double waveAlpha = (0.20 * depthAlpha).clamp(0.0, 1.0);
      
      _wavePaint
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [waveColor.withValues(alpha: waveAlpha), waveColor.withValues(alpha: 0.01 * depthAlpha)]).createShader(rect)
        ..blendMode = BlendMode.overlay;
      
      canvas.drawPath(_wavePath, _wavePaint);
    }

    if (theme.name == 'Rushing Wind') {
      final Color branchWoodColor = const Color(0xFF7E5B44);
      canvas.save();
      drawOrganicCanopy(canvas, const Offset(-10, -10), 3 * pi / 4, 1.45, time, branchWoodColor);
      canvas.restore();
      canvas.save();
      drawOrganicCanopy(canvas, Offset(size.width + 10, size.height + 10), -pi / 4, 1.50, time, branchWoodColor);
      canvas.restore();
      
      // Drifting leaves optimization: fewer leaves
      final List<Map<String, dynamic>> driftLeaves = [
        {'startX': 0.05, 'startY': -0.1, 'scale': 0.85, 'baseAngle': pi / 6, 'speedX': 0.08, 'speedY': 0.05, 'swaySpeed': 1.6, 'swayAmp': 20.0, 'bodyColor': const Color(0xFF5C6F56), 'outlineColor': const Color(0xFF86997F)},
        {'startX': 0.45, 'startY': -0.15, 'scale': 0.90, 'baseAngle': -pi / 6, 'speedX': 0.09, 'speedY': 0.06, 'swaySpeed': 1.8, 'swayAmp': 24.0, 'bodyColor': const Color(0xFF4F634A), 'outlineColor': const Color(0xFF7D9276)},
      ];
      for (var leaf in driftLeaves) {
        double xFraction = (leaf['startX']! + leaf['speedX']! * time * 1.5) % 1.4 - 0.2;
        double yFraction = (leaf['startY']! + leaf['speedY']! * time * 1.5) % 1.4 - 0.2;
        double px = xFraction * size.width + sin(time * leaf['swaySpeed']! * 2 * pi + leaf['startX']!) * leaf['swayAmp']!;
        double py = yFraction * size.height;
        double angle = leaf['baseAngle']! + time * 1.5 * pi;
        drawBambooLeaf(canvas, Offset(px, py), angle, leaf['scale']!, leaf['bodyColor']!, isDualTone: true, outlineColor: leaf['outlineColor']!);
      }
    }

    if (theme.name == 'Amazon Jungle') {
      _drawGodRays(canvas, size);
      _drawWaterfall(canvas, size);
      _drawFireflies(canvas, size);
    }

    if (theme.name == 'Pacific Waves') {
      _drawPacificSunset(canvas, size);
      _drawSloshingWaves(canvas, size);
    }

    if (theme.name == 'River Flow') {
      _drawRiverSurface(canvas, size);
    }
  }

  void _drawPacificSunset(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // 1. Draw Sun in the background
    _sunPaint.shader = RadialGradient(
        center: const Alignment(0, -0.6),
        radius: 0.8,
        colors: [
          const Color(0xFFFFE082).withValues(alpha: 0.6),
          const Color(0xFFFF9800).withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.2), size.width * 0.4, _sunPaint);

    // 2. Distant Birds
    _birdPaint
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final random = Random(123);
    for (int i = 0; i < 3; i++) { // Reduced from 4
      final double bx = size.width * (0.2 + random.nextDouble() * 0.6);
      final double by = size.height * (0.1 + random.nextDouble() * 0.15);
      final double bSize = 6.0 + random.nextDouble() * 4.0;
      final double wingSway = sin(time * 5.0 + i) * 2.0;
      
      _birdPath.reset();
      _birdPath.moveTo(bx - bSize, by + wingSway);
      _birdPath.quadraticBezierTo(bx, by - 4, bx + bSize, by + wingSway);
      canvas.drawPath(_birdPath, _birdPaint);
    }
  }

  void _drawSloshingWaves(Canvas canvas, Size size) {
    const int points = 18; // Reduced from 20
    final random = Random(456);

    for (int layer = 0; layer < 3; layer++) { // Reduced from 4
      final double waveSpeed = 0.35 + (layer * 0.12);
      final double amplitude = 20.0 - (layer * 2.5);
      final double verticalOffset = size.height * 0.62 + (layer * size.height * 0.075);
      
      _wavePath.reset();
      _wavePath.moveTo(0, size.height);
      _wavePath.lineTo(0, verticalOffset);
      
      for (int i = 0; i <= points; i++) {
        final double ratio = i / points;
        final double x = ratio * size.width;
        final double y = verticalOffset + 
            sin(ratio * pi * 3.0 + time * 2 * pi * waveSpeed) * amplitude + 
            cos(ratio * pi * 2.0 - time * pi * (waveSpeed * 0.9)) * (amplitude * 0.5);
        _wavePath.lineTo(x, y);
      }
      _wavePath.lineTo(size.width, size.height);
      _wavePath.close();

      final Color waveColor = layer % 2 == 0 ? const Color(0xFF00E5FF) : Colors.white;
      _wavePaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            waveColor.withValues(alpha: 0.3 - (layer * 0.06)),
            waveColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, verticalOffset - amplitude, size.width, size.height - verticalOffset + amplitude));
      
      canvas.drawPath(_wavePath, _wavePaint);

      // Add "Sun Glitter" on the top layer of waves
      if (layer == 0) {
        _glitterPaint.style = PaintingStyle.fill;
        for (int j = 0; j < 10; j++) { // Reduced from 15
          final double gx = random.nextDouble() * size.width;
          final double gy = verticalOffset + (random.nextDouble() - 0.5) * amplitude;
          final double gPulse = (sin(time * 8.0 + j) + 1.0) * 0.5;
          _glitterPaint.color = Colors.white.withValues(alpha: 0.4 * gPulse);
          canvas.drawCircle(Offset(gx, gy), 1.5, _glitterPaint);
        }
      }
    }
  }

  void _drawGodRays(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final Offset source = Offset(size.width * 0.48, -50);
    for (int i = 0; i < 2; i++) { // Optimization: reduced from 4
      final double sweep = sin(time * 1.2 + i * 1.5) * 0.04;
      final double angle = pi / 3.0 + (i - 0.5) * 0.18 + sweep;
      final double length = size.height * 1.6;
      final Offset p1 = Offset(source.dx - 12.0 * cos(angle + pi / 2), source.dy - 12.0 * sin(angle + pi / 2));
      final Offset p2 = Offset(source.dx + 12.0 * cos(angle + pi / 2), source.dy + 12.0 * sin(angle + pi / 2));
      final Offset p3 = Offset(source.dx + cos(angle) * length + 70.0 * cos(angle + pi / 2), source.dy + sin(angle) * length + 70.0 * sin(angle + pi / 2));
      final Offset p4 = Offset(source.dx + cos(angle) * length - 70.0 * cos(angle + pi / 2), source.dy + sin(angle) * length - 70.0 * sin(angle + pi / 2));
      final path = Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..lineTo(p4.dx, p4.dy)..close();
      paint.shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFFDE7).withValues(alpha: 0.10), const Color(0xFFFFF59D).withValues(alpha: 0.0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(path, paint);
    }
  }

  void _drawWaterfall(Canvas canvas, Size size) {
    final double waterfallWidth = (size.width * 0.12).clamp(45.0, 95.0);
    final rect = Rect.fromLTWH(0, 0, waterfallWidth, size.height);
    canvas.drawRect(rect, Paint()..color = const Color(0xFF0B140A).withValues(alpha: 0.85));
    for (int i = 0; i < 3; i++) {
      final double streamX = (i + 0.5) * (waterfallWidth / 3.0);
      final path = Path()..moveTo(streamX, 0);
      for (double y = 0; y <= size.height; y += 30.0) {
        path.lineTo(streamX + sin(y * 0.06 - time * 32.0 + i * 2.5) * 2.8, y);
      }
      canvas.drawPath(path, Paint()..color = const Color(0xFFB3E5FC).withValues(alpha: 0.15)..strokeWidth = 3.0..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8));
    }
  }

  void _drawFireflies(Canvas canvas, Size size) {
    final random = Random(88);
    for (int i = 0; i < 6; i++) { // Optimization: reduced from 12
      final double px = (random.nextDouble() * 1.2 - 0.1) * size.width + sin(time * 2 * pi + i) * 10.0;
      final double py = (random.nextDouble() * 1.2 - 0.1) * size.height;
      final double pulse = 0.25 + (sin(time * 3.5 * pi + i * 1.8) + 1.0) / 2.0 * 0.75;
      canvas.drawCircle(Offset(px, py), 2.2, Paint()..color = const Color(0xFFFFFF8D).withValues(alpha: 0.82 * pulse));
    }
  }

  void _drawRiverSurface(Canvas canvas, Size size) {
    // 1. Dappled Sunlight (God Rays from top canopy)
    _drawGodRays(canvas, size);

    // 2. Fast-flowing river currents
    const int points = 15;
    for (int layer = 0; layer < 5; layer++) {
      final double waveSpeed = 0.5 + (layer * 0.2); // Faster flowing than ocean
      final double amplitude = 12.0 - (layer * 1.5);
      final double verticalOffset = size.height * (0.2 + layer * 0.18);
      
      _wavePath.reset();
      _wavePath.moveTo(0, size.height);
      _wavePath.lineTo(0, verticalOffset);
      
      for (int i = 0; i <= points; i++) {
        final double ratio = i / points;
        final double x = ratio * size.width;
        // River waves flow horizontally more than vertically
        final double y = verticalOffset + 
            sin(ratio * pi * 4.0 + time * 2 * pi * waveSpeed) * amplitude + 
            cos(ratio * pi * 2.5 - time * pi * (waveSpeed * 0.8)) * (amplitude * 0.6);
        _wavePath.lineTo(x, y);
      }
      _wavePath.lineTo(size.width, size.height);
      _wavePath.close();

      final Color waveColor = layer % 2 == 0 ? const Color(0xFF00BFA5) : const Color(0xFF80CBC4);
      _wavePaint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            waveColor.withValues(alpha: 0.15 - (layer * 0.02)),
            waveColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, verticalOffset - amplitude, size.width, size.height - verticalOffset + amplitude));
      
      canvas.drawPath(_wavePath, _wavePaint);
    }

    // 3. Floating Lily Pads / River Debris
    final List<Map<String, dynamic>> lilyPads = [
      {'startX': 0.1, 'startY': 0.3, 'scale': 1.2, 'speed': 0.06, 'color': const Color(0xFF43A047), 'rot': 0.2},
      {'startX': 0.7, 'startY': 0.6, 'scale': 0.9, 'speed': 0.08, 'color': const Color(0xFF388E3C), 'rot': 1.5},
      {'startX': 0.4, 'startY': 0.8, 'scale': 1.5, 'speed': 0.05, 'color': const Color(0xFF2E7D32), 'rot': -0.5},
      {'startX': 0.8, 'startY': 0.1, 'scale': 0.7, 'speed': 0.09, 'color': const Color(0xFF66BB6A), 'rot': 0.8},
    ];

    for (var pad in lilyPads) {
      double yFraction = (pad['startY']! + pad['speed']! * time) % 1.2 - 0.1;
      double xFraction = (pad['startX']! + sin(time * 0.5 + pad['rot']!) * 0.05);
      
      double px = xFraction * size.width;
      double py = yFraction * size.height;
      
      final padPaint = Paint()..color = pad['color']!..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(pad['rot']! + time * 0.2); // Slow spin
      
      final path = Path()
        ..addArc(Rect.fromCircle(center: Offset.zero, radius: 15.0 * pad['scale']!), 0.4, 2 * pi - 0.8);
      path.lineTo(0, 0);
      path.close();
      
      canvas.drawPath(path, padPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(BackgroundMeshPainter oldDelegate) =>
      oldDelegate.lowDetailMode != lowDetailMode ||
      oldDelegate.theme != theme ||
      (!lowDetailMode && oldDelegate.time != time) ||
      oldDelegate.textureCache != textureCache;
}
