// lib/widgets/board/winning_line.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../features/settings/logic/settings_controller.dart';

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
    final baseColor = activeTheme.name == 'Amazon Jungle'
        ? const Color(0xFFCBE346) // Bright lime-yellow neon laser!
        : (widget.winner == Player.X ? activeTheme.colorX : activeTheme.colorO);

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
