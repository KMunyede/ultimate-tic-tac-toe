// lib/widgets/animated_vibrant_background.dart

import 'dart:math';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = settings.currentTheme;

    if (settings.lowDetailMode) {
      return CustomPaint(
        painter: BackgroundMeshPainter(
          time: 0.0,
          theme: theme,
          lowDetailMode: true,
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double elapsedSeconds = _stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond;
        // Pass scaled continuous time so sways, drifts and waves flow infinitely without looping snaps
        return CustomPaint(
          painter: BackgroundMeshPainter(
            time: elapsedSeconds / 18.0,
            theme: theme,
            lowDetailMode: false,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class BackgroundMeshPainter extends CustomPainter {
  final double time;
  final AppTheme theme;
  final bool lowDetailMode;

  BackgroundMeshPainter({
    required this.time,
    required this.theme,
    required this.lowDetailMode,
  });

  void drawBambooLeaf(Canvas canvas, Offset stem, double angle, double scale, Color color, {bool isShadow = false, bool isDualTone = false, Color? outlineColor}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (isShadow) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    }

    canvas.save();
    canvas.translate(stem.dx, stem.dy);
    canvas.rotate(angle);
    canvas.scale(scale);

    // Elegant, rounded drooping bamboo leaf path (from the mockup!)
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-7, -15, -5, -35)
      ..quadraticBezierTo(-2.5, -50, 0, -65)  // elegant, rounded tip
      ..quadraticBezierTo(2.5, -50, 5, -35)
      ..quadraticBezierTo(7, -15, 0, 0)
      ..close();

    canvas.drawPath(path, paint);

    if (!isShadow) {
      final veinColor = isDualTone && outlineColor != null
          ? outlineColor.withValues(alpha: 0.60)
          : color.withValues(alpha: color.a * 0.40);
          
      final veinPaint = Paint()
        ..color = veinColor
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw elegant leaf central vein
      canvas.drawLine(Offset.zero, const Offset(0, -60), veinPaint);

      if (isDualTone && outlineColor != null) {
        final outlinePaint = Paint()
          ..color = outlineColor
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, outlinePaint);
      }
    }

    canvas.restore();
  }

  void drawLeafCluster(Canvas canvas, Offset pos, double angle, double time, Color color, {bool isShadow = false, bool isDualTone = false, Color? outlineColor}) {
    final double leafSway = sin(time * 2.0 * pi + pos.dx * 0.05) * 0.08;
    
    // Leaf 1: Center - Droop straight down with scale 2.6
    drawBambooLeaf(canvas, pos, angle + leafSway, 2.6, color, isShadow: isShadow, isDualTone: isDualTone, outlineColor: outlineColor);
    
    // Leaf 2: Left - Widely separated and angled out, scale 2.1
    final Offset stemOffsetL = Offset(cos(angle - pi / 2) * -28, sin(angle - pi / 2) * -28);
    drawBambooLeaf(canvas, pos + stemOffsetL, angle - 0.80 + leafSway * 0.7, 2.1, color, isShadow: isShadow, isDualTone: isDualTone, outlineColor: outlineColor);
    
    // Leaf 3: Right - Widely separated and angled out, scale 2.2
    final Offset stemOffsetR = Offset(cos(angle + pi / 2) * 28, sin(angle + pi / 2) * 28);
    drawBambooLeaf(canvas, pos + stemOffsetR, angle + 0.80 + leafSway * 1.1, 2.2, color, isShadow: isShadow, isDualTone: isDualTone, outlineColor: outlineColor);
  }

  void drawBambooBranch(Canvas canvas, Offset origin, double baseAngle, double scale, double time, Color color, {bool isShadow = false, bool isDualTone = false, Color? outlineColor}) {
    // Overload/delegate to drawOrganicCanopy for seamless integration
    drawOrganicCanopy(canvas, origin, baseAngle, scale, time, color, isShadow: isShadow);
  }

  void drawMapleLeaf(Canvas canvas, Offset stem, double angle, double scale, Color color, {bool isShadow = false, bool isDualTone = false, Color? outlineColor}) {
    // Delegate to drawBambooLeaf for drifting leaf compatibility
    drawBambooLeaf(canvas, stem, angle, scale, color, isShadow: isShadow, isDualTone: isDualTone, outlineColor: outlineColor);
  }


  void drawTreeTrunk(Canvas canvas, Offset start, Offset control, Offset end, double startWidth, double endWidth, Color color, {bool isShadow = false}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isShadow) {
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    }

    const int segments = 20;
    Offset last = start;
    for (int i = 1; i <= segments; i++) {
      final double t = i / segments;
      final double x = (1 - t) * (1 - t) * start.dx + 2 * (1 - t) * t * control.dx + t * t * end.dx;
      final double y = (1 - t) * (1 - t) * start.dy + 2 * (1 - t) * t * control.dy + t * t * end.dy;
      final Offset current = Offset(x, y);

      final double w = startWidth + (endWidth - startWidth) * t;
      paint.strokeWidth = w;

      canvas.drawLine(last, current, paint);
      last = current;
    }
  }

  void drawOrganicCanopy(Canvas canvas, Offset origin, double baseAngle, double scale, double time, Color woodColor, {bool isShadow = false}) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(baseAngle);
    canvas.scale(scale);

    // Main Trunk curves reaching outwards towards the water (perfect quadratic curves)
    final double s1 = sin(time * 2.0 * pi) * 0.03;
    final Offset start = Offset.zero;
    final Offset control = Offset(45, -65 + sin(time * pi) * 3);
    final Offset end = Offset(85 + sin(time * 2.0 * pi + 0.5) * 5, -125 + cos(time * 2.0 * pi) * 4);

    final shadowColor = Colors.black.withValues(alpha: 0.08);
    final Color trunkColor = isShadow ? shadowColor : woodColor;

    // Draw Main Trunk
    drawTreeTrunk(canvas, start, control, end, 16.0, 5.0, trunkColor, isShadow: isShadow);

    // Growing Twigs (curved, tapered branches) off the trunk
    // Twig 1 (Middle-left branch) - starts at 0.35 along trunk
    final double sTwig1 = sin(time * 2.0 * pi + 0.8) * 0.04;
    final Offset twigStart1 = Offset(
      (1 - 0.35) * (1 - 0.35) * start.dx + 2 * (1 - 0.35) * 0.35 * control.dx + 0.35 * 0.35 * end.dx,
      (1 - 0.35) * (1 - 0.35) * start.dy + 2 * (1 - 0.35) * 0.35 * control.dy + 0.35 * 0.35 * end.dy,
    );
    final Offset twigEnd1 = Offset(twigStart1.dx - 48, twigStart1.dy - 38 + sTwig1 * 10);
    final Offset twigControl1 = Offset(twigStart1.dx - 25, twigStart1.dy - 15);
    drawTreeTrunk(canvas, twigStart1, twigControl1, twigEnd1, 5.5, 2.0, trunkColor, isShadow: isShadow);

    // Twig 2 (Middle-right branch) - starts at 0.65 along trunk
    final double sTwig2 = sin(time * 2.0 * pi + 1.4) * 0.04;
    final Offset twigStart2 = Offset(
      (1 - 0.65) * (1 - 0.65) * start.dx + 2 * (1 - 0.65) * 0.65 * control.dx + 0.65 * 0.65 * end.dx,
      (1 - 0.65) * (1 - 0.65) * start.dy + 2 * (1 - 0.65) * 0.65 * control.dy + 0.65 * 0.65 * end.dy,
    );
    final Offset twigEnd2 = Offset(twigStart2.dx + 48, twigStart2.dy - 28 + sTwig2 * 10);
    final Offset twigControl2 = Offset(twigStart2.dx + 25, twigStart2.dy - 10);
    drawTreeTrunk(canvas, twigStart2, twigControl2, twigEnd2, 4.5, 1.8, trunkColor, isShadow: isShadow);

    // Twig 3 (Sub-branch near the tip) - starts at 0.82 along trunk
    final double sTwig3 = sin(time * 2.0 * pi + 2.0) * 0.04;
    final Offset twigStart3 = Offset(
      (1 - 0.82) * (1 - 0.82) * start.dx + 2 * (1 - 0.82) * 0.82 * control.dx + 0.82 * 0.82 * end.dx,
      (1 - 0.82) * (1 - 0.82) * start.dy + 2 * (1 - 0.82) * 0.82 * control.dy + 0.82 * 0.82 * end.dy,
    );
    final Offset twigEnd3 = Offset(twigStart3.dx - 22, twigStart3.dy - 38 + sTwig3 * 8);
    final Offset twigControl3 = Offset(twigStart3.dx - 10, twigStart3.dy - 20);
    drawTreeTrunk(canvas, twigStart3, twigControl3, twigEnd3, 3.5, 1.5, trunkColor, isShadow: isShadow);

    // Draw foliage leaves at the tips
    if (!isShadow) {
      final Color leafColor = const Color(0xFF5C6F56); // organic sage green leaf body
      final Color leafOutline = const Color(0xFF86997F); // organic lighter green highlights
      
      // Tip cluster (Main canopy head)
      drawLeafCluster(canvas, end, s1, time, leafColor, isShadow: false, isDualTone: true, outlineColor: leafOutline);
      
      // Twig 1 cluster (Drooping left)
      drawLeafCluster(canvas, twigEnd1, sTwig1 - pi / 3.5, time, leafColor, isShadow: false, isDualTone: true, outlineColor: leafOutline);

      // Twig 2 cluster (Drooping right)
      drawLeafCluster(canvas, twigEnd2, sTwig2 + pi / 3.5, time, leafColor, isShadow: false, isDualTone: true, outlineColor: leafOutline);

      // Twig 3 cluster (Extra leafy top-left)
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

  void drawMapleBranch(Canvas canvas, Offset origin, double baseAngle, double scale, double time, Color woodColor, {bool isShadow = false}) {
    // Delegate to drawOrganicCanopy for visual consistency
    drawOrganicCanopy(canvas, origin, baseAngle, scale, time, woodColor, isShadow: isShadow);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // 1. Draw solid premium diagonal background mist gradient
    final paintBg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: theme.bgGradient,
      ).createShader(rect);
    canvas.drawRect(rect, paintBg);

    // 2. Draw Realistic Rice-Paper / Stipple Texture (specifically for Rushing Wind)
    if (theme.name == 'Rushing Wind' && !lowDetailMode) {
      final rand = Random(42); // Deterministic seed so texture is perfectly static!
      
      // Paint 1800+ microscopic stipple dots representing fine powdery grain
      final stipplePaint = Paint()..style = PaintingStyle.fill;
      for (int i = 0; i < 1800; i++) {
        final double rx = rand.nextDouble() * size.width;
        final double ry = rand.nextDouble() * size.height;
        final double radius = 0.4 + rand.nextDouble() * 0.7;
        final double opacity = 0.01 + rand.nextDouble() * 0.035;
        
        // Alternate between soft light-sand and soft dark-sage stipples
        final Color stippleColor = rand.nextBool()
            ? theme.textColor.withValues(alpha: opacity)
            : theme.mainColor.withValues(alpha: opacity * 0.5);
            
        stipplePaint.color = stippleColor;
        canvas.drawCircle(Offset(rx, ry), radius, stipplePaint);
      }
      
      // Paint 180+ fine fibrous lines representing hand-made rice-paper fibers
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
          
        // Paint a wobbly fiber by drawing a two-segment path
        final double midX = (startX + endX) / 2 + (rand.nextDouble() - 0.5) * 1.5;
        final double midY = (startY + endY) / 2 + (rand.nextDouble() - 0.5) * 1.5;
        
        final fiberPath = Path()
          ..moveTo(startX, startY)
          ..quadraticBezierTo(midX, midY, endX, endY);
          
        canvas.drawPath(fiberPath, fiberPaint);
      }
    }

    if (lowDetailMode) {
      // Premium static representation
      final paintStatic = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBg,
            theme.boardBg.withValues(alpha: 0.7),
          ],
        ).createShader(rect);
      canvas.drawRect(rect, paintStatic);
      return;
    }

    const int points = 100; // Higher resolution for smooth fluid water

    // Layered Water Fluid Dynamics
    // We simulate 8 overlapping wave layers to create physical water depth and caustics
    for (int layer = 0; layer < 8; layer++) {
      final double depthAlpha = 1.0 - (layer / 8.0); // Deeper layers are more faint
      // Smoothened caustics wave speed (slower, gentle sloshing!)
      final double waveSpeed = theme.name == 'Rushing Wind' ? 0.05 + (layer * 0.015) : 0.3 + (layer * 0.12);
      // Smoothened wave amplitude
      final double amplitude = theme.name == 'Rushing Wind' ? 10.0 - (layer * 0.6) : 22.0 - (layer * 1.8);
      
      final double frequency = 1.2 + (layer * 0.35);
      final double verticalOffset = size.height * 0.22 + (layer * size.height * 0.07);

      final path = Path();
      path.moveTo(0, size.height);
      path.lineTo(0, verticalOffset);

      for (int i = 0; i <= points; i++) {
        final double ratio = i / points;
        final double x = ratio * size.width;
        
        // Fluid noise math: mix of two sine waves and a phase shift
        final double y = verticalOffset +
            sin(ratio * pi * frequency + time * 2 * pi * waveSpeed) * amplitude +
            cos(ratio * pi * (frequency * 0.8) - time * pi * (waveSpeed * 0.7)) * (amplitude * 0.5);
            
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();

      // Alternate colors for refractive caustics (introducing different shades of blue and gentle aquamarines)
      Color waveColor;
      if (theme.name == 'Rushing Wind') {
        final List<Color> rushingWindWaveColors = [
          const Color(0xFF1B365D), // Deep Indigo Blue
          const Color(0xFF2E5B82), // Slate River Blue
          const Color(0xFF4A90E2), // Clear Crystalline Blue
          const Color(0xFF6BA4E8), // Misty Glacier Blue
          const Color(0xFF5E8B7F), // Luminous Sage Blue
          const Color(0xFF2C3E50), // Soft Ocean Sapphire
          const Color(0xFF0F4C5C), // Deep Turquoise
          const Color(0xFF3B8EA5), // Soft Aquamarine
        ];
        waveColor = rushingWindWaveColors[layer % rushingWindWaveColors.length];
      } else {
        waveColor = layer % 3 == 0
            ? theme.mainColor
            : (layer % 3 == 1 ? theme.accentGlow : Colors.white);
      }

      final double waveAlphaScale = theme.name == 'Rushing Wind' ? 0.95 : 1.0;
      final double waveAlpha = (0.22 * depthAlpha * waveAlphaScale).clamp(0.0, 1.0);
      final double waveBaseAlpha = (0.10 * depthAlpha * waveAlphaScale).clamp(0.0, 1.0);

      final paintWave = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            waveColor.withValues(alpha: waveAlpha),
            waveColor.withValues(alpha: 0.02 * depthAlpha),
          ],
        ).createShader(rect)
        ..blendMode = BlendMode.overlay; // Critical for water caustics effect

      // We draw an overlay layer, but some platforms struggle with pure overlay on white, 
      // so we also draw a very faint normal layer underneath it to anchor the color.
      final paintWaveBase = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            waveColor.withValues(alpha: waveBaseAlpha),
            waveColor.withValues(alpha: 0.0),
          ],
        ).createShader(rect);

      canvas.drawPath(path, paintWaveBase);
      canvas.drawPath(path, paintWave);

      // Add specular sun glints on the crests of the top layers
      if (layer < 4) {
        final glintPath = Path();
        glintPath.moveTo(0, verticalOffset + sin(time * 2 * pi * waveSpeed) * amplitude + cos(-time * pi * (waveSpeed * 0.7)) * (amplitude * 0.5));
        for (int i = 1; i <= points; i++) {
          final double ratio = i / points;
          final double x = ratio * size.width;
          final double y = verticalOffset +
              sin(ratio * pi * frequency + time * 2 * pi * waveSpeed) * amplitude +
              cos(ratio * pi * (frequency * 0.8) - time * pi * (waveSpeed * 0.7)) * (amplitude * 0.5);
          glintPath.lineTo(x, y);
        }

        final paintGlint = Paint()
          ..color = (theme.name == 'Rushing Wind'
              ? theme.mainColor.withValues(alpha: 0.25 * depthAlpha)
              : Colors.white.withValues(alpha: 0.45 * depthAlpha))
          ..strokeWidth = 2.5 - layer * 0.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
          ..blendMode = BlendMode.screen;

        canvas.drawPath(glintPath, paintGlint);
      }
    }

    // 5. Draw Swaying Organic Curved twig branches (nestled inside all four corners)
    if (theme.name == 'Rushing Wind') {
      final Color branchWoodColor = const Color(0xFF7E5B44); // Warm Cedar Twig Mahogany Wood Brown

      // Top-Left corner maple branch
      canvas.save();
      drawMapleBranch(canvas, const Offset(-10, -10) + const Offset(8, 12), 3 * pi / 4, 1.45, time, Colors.black.withValues(alpha: 0.08), isShadow: true);
      drawMapleBranch(canvas, const Offset(-10, -10), 3 * pi / 4, 1.45, time, branchWoodColor);
      canvas.restore();

      // Bottom-Right corner maple branch
      canvas.save();
      drawMapleBranch(canvas, Offset(size.width + 10, size.height + 10) + const Offset(-8, -12), -pi / 4, 1.50, time, Colors.black.withValues(alpha: 0.08), isShadow: true);
      drawMapleBranch(canvas, Offset(size.width + 10, size.height + 10), -pi / 4, 1.50, time, branchWoodColor);
      canvas.restore();

      // Bottom-Left corner maple branch
      canvas.save();
      drawMapleBranch(canvas, Offset(-10, size.height + 10) + const Offset(8, -12), pi / 4, 1.35, time, Colors.black.withValues(alpha: 0.08), isShadow: true);
      drawMapleBranch(canvas, Offset(-10, size.height + 10), pi / 4, 1.35, time, branchWoodColor);
      canvas.restore();

      // Top-Right corner maple branch - New 4th Corner!
      canvas.save();
      drawMapleBranch(canvas, Offset(size.width + 10, -10) + const Offset(-8, 12), -3 * pi / 4, 1.40, time, Colors.black.withValues(alpha: 0.08), isShadow: true);
      drawMapleBranch(canvas, Offset(size.width + 10, -10), -3 * pi / 4, 1.40, time, branchWoodColor);
      canvas.restore();
    }

    // 6. Draw Beautifully Rounded Drifting Leaves falling slowly and smoothly from top to bottom of screen
    if (theme.name == 'Rushing Wind' && !lowDetailMode) {
      final Color shadowColor = Colors.black.withValues(alpha: 0.05);

      // Define 6 leaves using biological pigments and ultra-slow weightless velocities
      final List<Map<String, dynamic>> driftLeaves = [
        // Leaf 1: Medium-dark sage green
        {
          'startX': 0.05, 'startY': -0.1, 'scale': 0.85, 'baseAngle': pi / 6, 'speedX': 0.08, 'speedY': 0.05, 'swaySpeed': 1.6, 'swayAmp': 20.0,
          'bodyColor': const Color(0xFF5C6F56), 'outlineColor': const Color(0xFF86997F)
        },
        // Leaf 2: Lighter misty sage green
        {
          'startX': 0.25, 'startY': -0.35, 'scale': 0.75, 'baseAngle': pi / 4, 'speedX': 0.06, 'speedY': 0.04, 'swaySpeed': 2.0, 'swayAmp': 15.0,
          'bodyColor': const Color(0xFF70806A), 'outlineColor': const Color(0xFFBAC7B8)
        },
        // Leaf 3: Deep forest sage green
        {
          'startX': 0.45, 'startY': -0.15, 'scale': 0.90, 'baseAngle': -pi / 6, 'speedX': 0.09, 'speedY': 0.06, 'swaySpeed': 1.8, 'swayAmp': 24.0,
          'bodyColor': const Color(0xFF4F634A), 'outlineColor': const Color(0xFF7D9276)
        },
        // Leaf 4: Bright organic bamboo green
        {
          'startX': 0.65, 'startY': -0.25, 'scale': 0.70, 'baseAngle': pi / 3, 'speedX': 0.05, 'speedY': 0.035, 'swaySpeed': 2.2, 'swayAmp': 12.0,
          'bodyColor': const Color(0xFF688A60), 'outlineColor': const Color(0xFF94A88E)
        },
        // Leaf 5: Soft mossy green
        {
          'startX': 0.85, 'startY': -0.05, 'scale': 0.80, 'baseAngle': pi / 5, 'speedX': 0.07, 'speedY': 0.045, 'swaySpeed': 1.5, 'swayAmp': 18.0,
          'bodyColor': const Color(0xFF7D9276), 'outlineColor': const Color(0xFFBAC7B8)
        },
        // Leaf 6: Pale silvery sage green
        {
          'startX': 0.15, 'startY': -0.5, 'scale': 0.72, 'baseAngle': -pi / 4, 'speedX': 0.065, 'speedY': 0.04, 'swaySpeed': 2.4, 'swayAmp': 14.0,
          'bodyColor': const Color(0xFF94A88E), 'outlineColor': const Color(0xFFC3CFC0)
        },
        // Leaf 7: Lush olive green
        {
          'startX': 0.35, 'startY': -0.6, 'scale': 0.88, 'baseAngle': pi / 8, 'speedX': 0.08, 'speedY': 0.05, 'swaySpeed': 1.9, 'swayAmp': 22.0,
          'bodyColor': const Color(0xFF5C6F56), 'outlineColor': const Color(0xFF94A88E)
        },
        // Leaf 8: Golden-highlighted sage green
        {
          'startX': 0.55, 'startY': -0.4, 'scale': 0.82, 'baseAngle': pi / 3.5, 'speedX': 0.075, 'speedY': 0.048, 'swaySpeed': 2.1, 'swayAmp': 16.0,
          'bodyColor': const Color(0xFF70806A), 'outlineColor': const Color(0xFFE4E1DA)
        },
        // Leaf 9: Delicate young bamboo green
        {
          'startX': 0.72, 'startY': -0.55, 'scale': 0.68, 'baseAngle': -pi / 5, 'speedX': 0.055, 'speedY': 0.038, 'swaySpeed': 2.5, 'swayAmp': 13.0,
          'bodyColor': const Color(0xFF688A60), 'outlineColor': const Color(0xFFBAC7B8)
        },
        // Leaf 10: Rich canopy shadow green
        {
          'startX': 0.95, 'startY': -0.3, 'scale': 0.86, 'baseAngle': pi / 7, 'speedX': 0.085, 'speedY': 0.052, 'swaySpeed': 1.7, 'swayAmp': 21.0,
          'bodyColor': const Color(0xFF4F634A), 'outlineColor': const Color(0xFF86997F)
        },
      ];

      for (var leaf in driftLeaves) {
        // Compute displacement based on continuous looping time (0.0 to 1.0)
        double t = time;
        double xFraction = (leaf['startX']! + leaf['speedX']! * t * 1.5) % 1.4 - 0.2;
        double yFraction = (leaf['startY']! + leaf['speedY']! * t * 1.5) % 1.4 - 0.2;

        double px = xFraction * size.width + sin(time * leaf['swaySpeed']! * 2 * pi + leaf['startX']!) * leaf['swayAmp']!;
        double py = yFraction * size.height;
        
        // Combine base angle + slow rotation + minor wiggle sway
        double angle = leaf['baseAngle']! + time * 1.5 * pi + cos(time * 2 * pi + leaf['startY']!) * 0.15;
        double scale = leaf['scale']!;

        // Draw Shadow first
        drawMapleLeaf(canvas, Offset(px + 6.0, py + 8.0), angle, scale, shadowColor, isShadow: true);
        // Draw Dual-Tone Drifting Leaf in beautiful Autumn Colors
        drawMapleLeaf(canvas, Offset(px, py), angle, scale, leaf['bodyColor']!, isDualTone: true, outlineColor: leaf['outlineColor']!);
      }
    }

    // 7. Draw Semi-Transparent Whisps of Wind gliding across the screen to make branches sway
    if (theme.name == 'Rushing Wind' && !lowDetailMode) {
      // Draw 3 distinct wind wisps
      for (int w = 0; w < 3; w++) {
        final double windTime = (time + w * 0.33) % 1.0;
        final double startX = -200 + windTime * (size.width + 400);
        final double baseY = size.height * (0.22 + w * 0.28);

        final path = Path();
        
        // Draw a long, wobbly horizontal wave representing a gust of wind
        const double wispLength = 300.0;
        for (double dx = 0; dx <= wispLength; dx += 8.0) {
          final double ratio = dx / wispLength;
          final double wx = startX + dx;
          // Smooth sine wave component + cosine wiggle
          final double wy = baseY + 
              sin(ratio * pi * 2 + time * 3 * pi) * 15.0 + 
              cos(ratio * pi * 4 - time * 1.5 * pi) * 6.0;
          if (dx == 0) {
            path.moveTo(wx, wy);
          } else {
            path.lineTo(wx, wy);
          }
        }

        // Make the wind wisp fade out at the start and end of its path
        final wispPaintFaded = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.2 + sin(time * pi) * 0.5
          ..shader = LinearGradient(
            colors: [
              theme.textColor.withValues(alpha: 0.0),
              theme.textColor.withValues(alpha: 0.08),
              theme.textColor.withValues(alpha: 0.08),
              theme.textColor.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.25, 0.75, 1.0],
          ).createShader(Rect.fromLTWH(startX, baseY - 25, wispLength, 50))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);

        canvas.drawPath(path, wispPaintFaded);
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundMeshPainter oldDelegate) =>
      oldDelegate.lowDetailMode != lowDetailMode ||
      oldDelegate.theme != theme ||
      (!lowDetailMode && oldDelegate.time != time);
}
