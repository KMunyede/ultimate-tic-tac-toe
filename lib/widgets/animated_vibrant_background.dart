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
  late AnimationController _controller;
  final List<EnergyNode> _energyNodes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Create 15 floating energetic particles
    for (int i = 0; i < 15; i++) {
      _energyNodes.add(EnergyNode(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: _random.nextDouble() * 0.015 + 0.005,
        size: _random.nextDouble() * 5.0 + 2.0,
        opacity: _random.nextDouble() * 0.4 + 0.1,
        angle: _random.nextDouble() * 2 * pi,
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
    final settings = context.watch<SettingsController>();
    final theme = settings.currentTheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Slowly update particles movement
        _updateEnergyNodes();

        return CustomPaint(
          painter: BackgroundMeshPainter(
            time: _controller.value,
            theme: theme,
            energyNodes: _energyNodes,
          ),
          child: widget.child,
        );
      },
    );
  }

  void _updateEnergyNodes() {
    for (var node in _energyNodes) {
      node.y -= node.speed * 0.08; // Rise slowly
      node.x += sin(node.angle + _controller.value * 2 * pi) * 0.002; // S-curve wiggle
      
      // Reset if out of bounds
      if (node.y < -0.05) {
        node.y = 1.05;
        node.x = _random.nextDouble();
      }
    }
  }
}

class EnergyNode {
  double x, y;
  final double speed, size, opacity, angle;
  EnergyNode({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.angle,
  });
}

class BackgroundMeshPainter extends CustomPainter {
  final double time;
  final AppTheme theme;
  final List<EnergyNode> energyNodes;

  BackgroundMeshPainter({
    required this.time,
    required this.theme,
    required this.energyNodes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = theme.brightness == Brightness.dark;
    final List<Color> colors = theme.bgGradient;
    
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final double waveAngle = time * 2 * pi;
    final double dx = cos(waveAngle) * 0.20;
    final double dy = sin(waveAngle) * 0.20;
    
    // Wave the gradient stops dynamically to simulate fluid currents washing over the layout
    final double stop1 = (0.0 + sin(waveAngle) * 0.12).clamp(0.0, 0.25);
    final double stop2 = (0.5 + sin(waveAngle + 2.094) * 0.12).clamp(0.35, 0.65);
    final double stop3 = (1.0 + sin(waveAngle + 4.188) * 0.12).clamp(0.75, 1.0);

    // Generate organic shifting color bands to simulate gentle liquid currents flowing in a river
    final List<Color> dynamicColors = colors.map((color) {
      final hsl = HSLColor.fromColor(color);
      final int idx = colors.indexOf(color);
      
      // Calculate desynchronized wave offsets per color band
      final double hueOffset = sin(waveAngle + idx * 1.5) * 12.0; // Subtle +/- 12 degree shift
      final double lightnessOffset = cos(waveAngle * 1.2 + idx * 2.0) * 0.04; // Soothing +/- 4% light shift
      
      return hsl
          .withHue((hsl.hue + hueOffset) % 360.0) // Wrap hue around 360 safely
          .withLightness((hsl.lightness + lightnessOffset).clamp(0.0, 1.0))
          .toColor();
    }).toList();

    final paintBase = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 - dx, -1.0 + dy),
        end: Alignment(1.0 + dx, 1.0 - dy),
        colors: dynamicColors.length >= 3 
            ? dynamicColors 
            : (dynamicColors.length == 2 
                ? [dynamicColors[0], dynamicColors[1], dynamicColors[0]] 
                : [theme.scaffoldBg, theme.boardBg, theme.scaffoldBg]),
        stops: dynamicColors.length >= 3 
            ? [stop1, stop2, stop3] 
            : null,
      ).createShader(rect);
    canvas.drawRect(rect, paintBase);

    // 2. Draw shifting animated auroras (radial glows)
    final double auroraTime = time * 2 * pi;
    final double center1X = size.width * (0.3 + sin(auroraTime) * 0.15);
    final double center1Y = size.height * (0.2 + cos(auroraTime) * 0.15);
    final double radius1 = size.width * 0.75;
    
    final paintAurora1 = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (center1X / size.width) * 2 - 1,
          (center1Y / size.height) * 2 - 1,
        ),
        radius: 0.7,
        colors: [
          theme.accentGlow.withValues(alpha: isDark ? 0.15 : 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(center1X, center1Y), radius: radius1));
    canvas.drawRect(rect, paintAurora1);

    final double center2X = size.width * (0.7 + cos(auroraTime + pi) * 0.15);
    final double center2Y = size.height * (0.8 + sin(auroraTime + pi) * 0.15);
    final double radius2 = size.width * 0.75;

    final paintAurora2 = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (center2X / size.width) * 2 - 1,
          (center2Y / size.height) * 2 - 1,
        ),
        radius: 0.7,
        colors: [
          theme.mainColor.withValues(alpha: isDark ? 0.12 : 0.20),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(center2X, center2Y), radius: radius2));
    canvas.drawRect(rect, paintAurora2);

    // 3. Draw Perspective 3D Cyber-grid (Only for dark mode to keep light themes clean!)
    if (isDark) {
      _drawCyberGrid(canvas, size, theme.mainColor.withValues(alpha: 0.08));
    }

    // 4. Draw Rising Energy Nodes (floating themed leaves, blossoms, and embers)
    final isCandy = theme.name.contains('Candy Meadow');
    final isWood = theme.name.contains('Woodville Carve');

    for (int i = 0; i < energyNodes.length; i++) {
      final node = energyNodes[i];
      final double posX = node.x * size.width;
      final double posY = node.y * size.height;
      final pos = Offset(posX, posY);

      if (isCandy) {
        if (i % 2 == 0) {
          _drawLeafNode(canvas, pos, node.size * 1.5, node.opacity * 0.7);
        } else {
          _drawBlossomNode(canvas, pos, node.size * 1.2, node.opacity * 0.8);
        }
      } else if (isWood) {
        _drawEmberNode(canvas, pos, node.size * 1.2, node.opacity);
      } else {
        // Neon Cyberpulse: star circle
        final paintNode = Paint()..style = PaintingStyle.fill;
        paintNode.color = theme.mainColor.withValues(alpha: node.opacity);
        canvas.drawCircle(pos, node.size, paintNode);

        if (node.size > 4.0) {
          paintNode.color = Colors.white.withValues(alpha: node.opacity * 1.5);
          canvas.drawCircle(pos, node.size * 0.35, paintNode);
        }
      }
    }
  }

  void _drawLeafNode(Canvas canvas, Offset pos, double size, double opacity) {
    final leafPaint = Paint()
      ..color = Colors.green.shade400.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(pos.dx, pos.dy - size)
      ..quadraticBezierTo(pos.dx + size, pos.dy, pos.dx, pos.dy + size)
      ..quadraticBezierTo(pos.dx - size, pos.dy, pos.dx, pos.dy - size);
    canvas.drawPath(path, leafPaint);
  }

  void _drawBlossomNode(Canvas canvas, Offset pos, double size, double opacity) {
    final paint = Paint()
      ..color = Colors.pinkAccent.shade100.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(pos.dx - size * 0.4, pos.dy), size * 0.5, paint);
    canvas.drawCircle(Offset(pos.dx + size * 0.4, pos.dy), size * 0.5, paint);
    canvas.drawCircle(Offset(pos.dx, pos.dy - size * 0.4), size * 0.5, paint);
    canvas.drawCircle(Offset(pos.dx, pos.dy + size * 0.4), size * 0.5, paint);
    
    paint.color = Colors.yellow.shade300.withValues(alpha: opacity);
    canvas.drawCircle(pos, size * 0.3, paint);
  }

  void _drawEmberNode(Canvas canvas, Offset pos, double size, double opacity) {
    final paint = Paint()
      ..color = const Color(0xFFFFB300).withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(pos.dx, pos.dy - size)
      ..lineTo(pos.dx + size * 0.7, pos.dy)
      ..lineTo(pos.dx, pos.dy + size)
      ..lineTo(pos.dx - size * 0.7, pos.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawCyberGrid(Canvas canvas, Size size, Color gridColor) {
    final paintGrid = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double horizonY = size.height * 0.45; // Horizon plane
    final double gridBottomWidth = size.width * 1.5;
    
    // Draw vertical perspective grid lines radiating from the horizon center outwards
    const int verticalLines = 14;
    for (int i = 0; i <= verticalLines; i++) {
      double ratio = i / verticalLines;
      
      // Calculate top coordinate (closely bundled at horizon center)
      double topX = size.width * 0.5 + (ratio - 0.5) * (size.width * 0.2);
      
      // Calculate bottom coordinate (radiating wide)
      double bottomX = size.width * 0.5 + (ratio - 0.5) * gridBottomWidth;
      
      canvas.drawLine(
        Offset(topX, horizonY),
        Offset(bottomX, size.height),
        paintGrid,
      );
    }

    // Draw horizontal lines that scroll downwards
    const int horizontalLines = 8;
    final double gridScroll = (time * 8.0) % 1.0;
    
    for (int i = 0; i < horizontalLines; i++) {
      // Exponential spacing to simulate 3D depth perspective
      double normVal = (i + gridScroll) / horizontalLines;
      double yVal = horizonY + pow(normVal, 2.0) * (size.height - horizonY);
      
      canvas.drawLine(
        Offset(0, yVal),
        Offset(size.width, yVal),
        paintGrid,
      );
    }
  }

  @override
  bool shouldRepaint(BackgroundMeshPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.theme != theme;
}
