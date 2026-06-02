// lib/features/game/widgets/mini_turn_board.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/player.dart';
import '../../../core/theme/app_theme.dart';

class MiniTurnBoard extends StatefulWidget {
  final Player player;
  final bool isThinking;
  final AppTheme theme;

  const MiniTurnBoard({
    super.key,
    required this.player,
    required this.isThinking,
    required this.theme,
  });

  @override
  State<MiniTurnBoard> createState() => _MiniTurnBoardState();
}

class _MiniTurnBoardState extends State<MiniTurnBoard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color playerColor = widget.player == Player.X 
        ? widget.theme.colorX 
        : widget.theme.colorO;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulseVal = widget.isThinking 
            ? 0.3 + (_pulseController.value * 0.7) 
            : 0.6 + (_pulseController.value * 0.4);
        
        return Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            color: widget.theme.boardBg.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: playerColor.withValues(alpha: pulseVal),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: playerColor.withValues(alpha: pulseVal * 0.3),
                blurRadius: widget.isThinking ? 8.0 : 4.0,
                spreadRadius: widget.isThinking ? 1.0 : 0.0,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _MiniTurnBoardPainter(
              player: widget.player,
              isThinking: widget.isThinking,
              color: playerColor,
              pulse: _pulseController.value,
            ),
          ),
        );
      },
    );
  }
}

class _MiniTurnBoardPainter extends CustomPainter {
  final Player player;
  final bool isThinking;
  final Color color;
  final double pulse;

  _MiniTurnBoardPainter({
    required this.player,
    required this.isThinking,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // Draw tiny 3x3 grid lines
    final paintGrid = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Vertical grid lines
    canvas.drawLine(Offset(w / 3, 4), Offset(w / 3, h - 4), paintGrid);
    canvas.drawLine(Offset(2 * w / 3, 4), Offset(2 * w / 3, h - 4), paintGrid);
    // Horizontal grid lines
    canvas.drawLine(Offset(4, h / 3), Offset(w - 4, h / 3), paintGrid);
    canvas.drawLine(Offset(4, 2 * h / 3), Offset(w - 4, 2 * h / 3), paintGrid);

    // Draw active player symbol (X or O) in the center cell
    final double cx = w / 2;
    final double cy = h / 2;
    final double symbolSize = w / 6;

    final paintSymbol = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (player == Player.X) {
      canvas.drawLine(
        Offset(cx - symbolSize, cy - symbolSize),
        Offset(cx + symbolSize, cy + symbolSize),
        paintSymbol,
      );
      canvas.drawLine(
        Offset(cx + symbolSize, cy - symbolSize),
        Offset(cx - symbolSize, cy + symbolSize),
        paintSymbol,
      );
    } else if (player == Player.O) {
      if (isThinking) {
        final double radius = symbolSize;
        final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
        final double startAngle = pulse * 2 * pi;
        canvas.drawArc(rect, startAngle, 1.5 * pi, false, paintSymbol);
      } else {
        canvas.drawCircle(Offset(cx, cy), symbolSize, paintSymbol);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniTurnBoardPainter oldDelegate) =>
      oldDelegate.player != player ||
      oldDelegate.isThinking != isThinking ||
      oldDelegate.color != color ||
      oldDelegate.pulse != pulse;
}
