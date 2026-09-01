// lib/widgets/arcade/arcade_interactive_joystick.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/settings/logic/settings_controller.dart';

class InteractiveJoystickWidget extends StatefulWidget {
  final double size;
  const InteractiveJoystickWidget({super.key, this.size = 72.0});

  @override
  State<InteractiveJoystickWidget> createState() => _InteractiveJoystickWidgetState();
}

class _InteractiveJoystickWidgetState extends State<InteractiveJoystickWidget> with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final activeTheme = settings.currentTheme;
    
    Color ballColor = const Color(0xFFFF1744);
    if (activeTheme.name.contains('Candy Meadow')) {
      ballColor = const Color(0xFFFF4081);
    } else if (activeTheme.name.contains('Woodville Carve')) {
      ballColor = const Color(0xFFFF9100);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onHover: (event) {
        final double halfSize = widget.size / 2;
        final double dx = (event.localPosition.dx - halfSize) / halfSize;
        final double dy = (event.localPosition.dy - halfSize) / halfSize;
        setState(() {
          _tiltX = dx.clamp(-1.0, 1.0);
          _tiltY = dy.clamp(-1.0, 1.0);
        });
      },
      onExit: (_) => setState(() {
        _isHovered = false;
        _tiltX = 0.0;
        _tiltY = 0.0;
      }),
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, child) {
          double finalTiltX = _tiltX;
          double finalTiltY = _tiltY;
          if (!_isHovered) {
            final double angle = _idleController.value * 2 * pi;
            finalTiltX = cos(angle) * 0.18;
            finalTiltY = sin(angle) * 0.18;
          }

          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: JoystickPainter(
              tiltX: finalTiltX,
              tiltY: finalTiltY,
              ballColor: ballColor,
              isLight: activeTheme.brightness == Brightness.light,
            ),
          );
        },
      ),
    );
  }
}

class JoystickPainter extends CustomPainter {
  final double tiltX;
  final double tiltY;
  final Color ballColor;
  final bool isLight;

  JoystickPainter({
    required this.tiltX,
    required this.tiltY,
    required this.ballColor,
    required this.isLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;

    final wellPaint = Paint()
      ..shader = RadialGradient(
        colors: isLight
            ? [Colors.grey.shade400, Colors.grey.shade600]
            : [const Color(0xFF070709), const Color(0xFF202028)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, wellPaint);

    final wellBorder = Paint()
      ..color = isLight ? Colors.grey.shade700 : const Color(0xFF33333E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, wellBorder);

    final double washerRadius = radius * 0.6;
    final Offset washerCenter = center + Offset(tiltX * radius * 0.14, tiltY * radius * 0.14);
    
    final washerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(washerCenter.dx, washerCenter.dy + 1.5), washerRadius, washerShadow);

    final washerPaint = Paint()
      ..color = isLight ? const Color(0xFF222222) : const Color(0xFF15151A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(washerCenter, washerRadius, washerPaint);

    final washerHolePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(washerCenter, washerRadius * 0.25, washerHolePaint);

    final Offset ballCenter = center + Offset(tiltX * radius * 0.42, tiltY * radius * 0.42);
    
    final shaftShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..strokeWidth = radius * 0.16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(washerCenter + const Offset(1, 2), ballCenter + const Offset(1, 2), shaftShadowPaint);

    final shaftPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.grey.shade300, Colors.white, Colors.grey.shade500, Colors.grey.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(washerCenter, ballCenter))
      ..strokeWidth = radius * 0.13
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(washerCenter, ballCenter, shaftPaint);

    final double ballRadius = radius * 0.38;
    
    final ballShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawCircle(Offset(ballCenter.dx + 2, ballCenter.dy + 4), ballRadius, ballShadow);

    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(ballColor, Colors.white, 0.4)!,
          ballColor,
          Color.lerp(ballColor, Colors.black, 0.5)!,
        ],
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
      ).createShader(Rect.fromCircle(center: ballCenter, radius: ballRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballCenter, ballRadius, ballPaint);

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballCenter + Offset(-ballRadius * 0.3, -ballRadius * 0.3), ballRadius * 0.18, shinePaint);
  }

  @override
  bool shouldRepaint(covariant JoystickPainter oldDelegate) =>
      oldDelegate.tiltX != tiltX || oldDelegate.tiltY != tiltY || oldDelegate.ballColor != ballColor || oldDelegate.isLight != isLight;
}
