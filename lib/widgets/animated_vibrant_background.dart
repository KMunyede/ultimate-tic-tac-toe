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
    
    // 1. Draw solid base or radial base gradient
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paintBase = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.length >= 2 ? colors : [theme.scaffoldBg, theme.scaffoldBg],
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

    // 4. Draw Rising Energy Nodes (floating stars/dust)
    final paintNode = Paint()..style = PaintingStyle.fill;
    for (var node in energyNodes) {
      final double posX = node.x * size.width;
      final double posY = node.y * size.height;
      paintNode.color = theme.mainColor.withValues(alpha: node.opacity);
      canvas.drawCircle(Offset(posX, posY), node.size, paintNode);

      // Core filament glow for larger nodes
      if (node.size > 4.0) {
        paintNode.color = Colors.white.withValues(alpha: node.opacity * 1.5);
        canvas.drawCircle(Offset(posX, posY), node.size * 0.35, paintNode);
      }
    }
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
