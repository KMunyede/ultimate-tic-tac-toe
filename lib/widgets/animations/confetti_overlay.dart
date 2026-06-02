import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/settings/logic/settings_controller.dart';

enum ParticleType {
  rectangle,
  circle,
  star,
  ribbon,
  diamond
}

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiPiece> _pieces = [];
  final Random _random = Random();
  double _globalTime = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..addListener(() {
        if (mounted) {
          setState(() {
            _globalTime += 0.016;
            final double wind = sin(_globalTime * 1.5) * 2.5; // Sinusoidal shifting wind draft
            final Size size = MediaQuery.of(context).size;
            
            for (var p in _pieces) {
              p.update(wind, size);
            }
          });
        }
      });
    _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pieces.isEmpty) {
      _initConfetti();
    }
  }

  void _initConfetti() {
    final Size size = MediaQuery.of(context).size;
    final int pieceCount = (size.width * size.height / 4200).round().clamp(90, 260);
    
    final settings = context.read<SettingsController>();
    final theme = settings.currentTheme;
    
    // Highly sophisticated, theme-adaptive color palettes matching premium designs!
    final List<Color> colors;
    if (theme.name == 'Rushing Wind') {
      colors = [
        theme.mainColor, // Misty Sage
        theme.accentGlow, // Ochre Gold
        theme.colorX, // Sage green
        theme.colorO, // Ochre
        const Color(0xFFEDEADF), // Pale cream clay
        const Color(0xFFF9F7F1), // Pure milk white
      ];
    } else if (theme.name == 'Rising Moon') {
      colors = [
        theme.mainColor, // Neon Violet
        theme.accentGlow, // Indigo
        theme.colorX, // Electric violet
        theme.colorO, // Cyan glow
        const Color(0xFFE8D3FF), // Frosted lavender
        const Color(0xFF90CAF9), // Ice blue
      ];
    } else if (theme.name == 'Crimson Leaf') {
      colors = [
        theme.mainColor, // Autumn Crimson
        theme.accentGlow, // glistening gold
        theme.colorX, // Vermillion
        theme.colorO, // Maple orange
        const Color(0xFFFDE8E8), // Cherry blossom pink
        const Color(0xFFFFFDF0), // Bamboo paper
      ];
    } else if (theme.name == 'Drifting Cloud') {
      colors = [
        theme.mainColor, // Sky blue
        theme.textColor, // Bold charcoal
        const Color(0xFFD6E4E8), // Ice blue
        const Color(0xFFF0F4F8), // Soft wisp
        Colors.white,
      ];
    } else if (theme.name == 'Amazon Jungle') {
      colors = [
        theme.mainColor, // Lush Canopy Green
        theme.accentGlow, // Sunray Gold
        const Color(0xFF8BC34A), // Lime Green
        const Color(0xFFFFEB3B), // Bright Yellow
        const Color(0xFFE91E63), // Tropical Magenta Pink
        const Color(0xFFFFFDE7), // Soft White Down
      ];
    } else {
      colors = [
        Colors.amber.shade300,
        Colors.pink.shade300,
        Colors.cyan.shade300,
        Colors.purple.shade300,
        Colors.orange.shade300,
        Colors.lightGreen.shade300,
      ];
    }

    _pieces.clear();
    for (int i = 0; i < pieceCount; i++) {
      // 🌋 Fountain Blast Cones shooting high from the bottom-center of the viewport!
      final double angle = -pi / 2 + (_random.nextDouble() - 0.5) * (pi / 1.4); // Conical upward vector
      final double force = _random.nextDouble() * 14.0 + 8.0; // Dynamic explosive force
      
      final type = ParticleType.values[_random.nextInt(ParticleType.values.length)];
      
      _pieces.add(_ConfettiPiece(
        color: colors[_random.nextInt(colors.length)],
        x: size.width / 2 + (_random.nextDouble() - 0.5) * 60,
        y: size.height + 30, // Start just offscreen
        vx: cos(angle) * force,
        vy: sin(angle) * force,
        size: _random.nextDouble() * 9 + 4,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.25,
        type: type,
        windPhase: _random.nextDouble() * 2 * pi,
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
      child: CustomPaint(
        painter: _ConfettiPainter(pieces: _pieces),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPiece {
  final Color color;
  final double size;
  final double rotationSpeed;
  final ParticleType type;
  final double windPhase;
  
  double x, y, vx, vy, rotation = 0;
  double alpha = 1.0;
  final List<Offset> ribbonPoints = []; // Trailing points for winding ribbons

  _ConfettiPiece({
    required this.color,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.rotationSpeed,
    required this.type,
    required this.windPhase,
  });

  void update(double wind, Size sizeLimit) {
    // 🌌 Kinetic Gravity + Drag Force Physics:
    vy += 0.28; // Standard gravity acceleration
    
    // Horizontal wind influence
    final double windFactor = sin(windPhase + y * 0.005) * 0.35;
    vx = (vx + (wind + windFactor) * 0.05) * 0.97;
    vy = vy * 0.97; // Fluid air resistance drag

    x += vx;
    y += vy;
    rotation += rotationSpeed;

    // Streamer trailing history
    if (type == ParticleType.ribbon) {
      ribbonPoints.add(Offset(x, y));
      if (ribbonPoints.length > 9) {
        ribbonPoints.removeAt(0);
      }
    }

    // Fade out as it drifts lower
    if (y > sizeLimit.height * 0.65) {
      alpha = (1.0 - ((y - sizeLimit.height * 0.65) / (sizeLimit.height * 0.35))).clamp(0.0, 1.0);
    }

    // Recycle fallen pieces back into dynamic sky rain
    if (y > sizeLimit.height + 50 || x < -50 || x > sizeLimit.width + 50) {
      y = -30;
      x = Random().nextDouble() * sizeLimit.width;
      vy = Random().nextDouble() * 3.5 + 1.0;
      vx = (Random().nextDouble() - 0.5) * 2.0;
      alpha = 1.0;
      ribbonPoints.clear();
    }
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  _ConfettiPainter({required this.pieces});

  // Draws a beautiful 5-pointed star vector path
  Path _drawStar(double cx, double cy, double outerRadius, double innerRadius) {
    final path = Path();
    double rot = pi / 2 * 3;
    double x = cx;
    double y = cy;
    const double step = pi / 5;

    path.moveTo(cx, cy - outerRadius);
    for (int i = 0; i < 5; i++) {
      x = cx + cos(rot) * outerRadius;
      y = cy + sin(rot) * outerRadius;
      path.lineTo(x, y);
      rot += step;

      x = cx + cos(rot) * innerRadius;
      y = cy + sin(rot) * innerRadius;
      path.lineTo(x, y);
      rot += step;
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (var p in pieces) {
      if (p.alpha <= 0.001) continue;
      
      // 🌟 Holographic Foil Shimmer effect: Colors catch light as they tumble!
      final double shimmer = (sin(p.rotation * 3.0) + 1.0) / 2.0; // 0.0 to 1.0
      final Color glossyColor = Color.lerp(p.color, Colors.white, shimmer * 0.38)!;
      paint.color = glossyColor.withValues(alpha: p.alpha);

      // 1. Serpentine Winding Ribbon Streamer
      if (p.type == ParticleType.ribbon) {
        if (p.ribbonPoints.length > 1) {
          final ribbonPath = Path();
          ribbonPath.moveTo(p.ribbonPoints.first.dx, p.ribbonPoints.first.dy);
          for (int i = 1; i < p.ribbonPoints.length; i++) {
            ribbonPath.lineTo(p.ribbonPoints[i].dx, p.ribbonPoints[i].dy);
          }
          
          final ribbonPaint = Paint()
            ..color = p.color.withValues(alpha: p.alpha * 0.82)
            ..style = PaintingStyle.stroke
            ..strokeWidth = p.size * 0.38
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          canvas.drawPath(ribbonPath, ribbonPaint);
        }
        continue;
      }

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      switch (p.type) {
        // 2. Shiny Foil Rectangle
        case ParticleType.rectangle:
          canvas.drawRect(Rect.fromLTWH(-p.size / 2, -p.size * 0.3, p.size, p.size * 0.6), paint);
          break;
          
        // 3. Falling Bubble Circle
        case ParticleType.circle:
          canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
          break;
          
        // 4. Glittering Gold Star
        case ParticleType.star:
          canvas.drawPath(_drawStar(0, 0, p.size * 0.75, p.size * 0.32), paint);
          break;
          
        // 5. Skewed Crystal Diamond
        case ParticleType.diamond:
          final diamondPath = Path()
            ..moveTo(0, -p.size * 0.8)
            ..lineTo(p.size * 0.48, 0)
            ..lineTo(0, p.size * 0.8)
            ..lineTo(-p.size * 0.48, 0)
            ..close();
          canvas.drawPath(diamondPath, paint);
          break;
          
        default:
          canvas.drawRect(Rect.fromLTWH(-p.size / 2, -p.size / 2, p.size, p.size), paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
