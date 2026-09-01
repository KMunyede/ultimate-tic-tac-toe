// lib/widgets/board/animated_marker.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/player.dart';
import '../../features/settings/logic/settings_controller.dart';
import 'marker_painter.dart';

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

class _AnimatedMarkerState extends State<AnimatedMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Player? _lastPlayer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    if (widget.player != Player.none) _controller.forward();
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
    final baseColor = widget.player == Player.X ? activeTheme.colorX : activeTheme.colorO;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => SizedBox.expand(
        child: CustomPaint(
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
