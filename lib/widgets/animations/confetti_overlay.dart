import 'dart:math';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..addListener(() => setState(() {
        for (var p in _pieces) {
          p.update();
        }
      }));
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
    // Density-based count: more pieces on tablets, fewer on phones
    final int pieceCount = (size.width * size.height / 6000).round().clamp(60, 300);
    
    final colors = [
      Colors.redAccent,
      Colors.blueAccent,
      Colors.yellowAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
    ];

    for (int i = 0; i < pieceCount; i++) {
      _pieces.add(_ConfettiPiece(
        color: colors[_random.nextInt(colors.length)],
        x: _random.nextDouble(),
        y: _random.nextDouble() * -2.0, // Staggered start height
        size: _random.nextDouble() * 8 + 4,
        speed: _random.nextDouble() * 0.01 + 0.005,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
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
  final double speed;
  final double rotationSpeed;
  double x, y, rotation = 0;

  _ConfettiPiece({
    required this.color,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotationSpeed,
  });

  void update() {
    y += speed;
    rotation += rotationSpeed;
    if (y > 1.2) {
      y = -0.2;
      x = Random().nextDouble();
    }
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  _ConfettiPainter({required this.pieces});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var p in pieces) {
      paint.color = p.color;
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.rotation);
      
      // Draw varied shapes (rects and circles)
      if (p.size % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(0, 0, p.size, p.size * 0.6), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter old) => true;
}
