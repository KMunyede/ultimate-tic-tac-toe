// lib/widgets/arcade/common_arcade_widgets.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/settings/logic/settings_controller.dart';

class BlinkingLabel extends StatefulWidget {
  final String label;
  final bool active;
  final Color color;
  final double fontSize;

  const BlinkingLabel({
    super.key,
    required this.label,
    required this.active,
    required this.color,
    this.fontSize = 9.0,
  });

  @override
  State<BlinkingLabel> createState() => _BlinkingLabelState();
}

class _BlinkingLabelState extends State<BlinkingLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.active) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BlinkingLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_blinkController.isAnimating) {
      _blinkController.repeat(reverse: true);
    } else if (!widget.active && _blinkController.isAnimating) {
      _blinkController.stop();
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final isLight = settings.currentTheme.brightness == Brightness.light;

    final style = TextStyle(
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: widget.color,
      shadows: (widget.active && !isLight)
          ? [
              Shadow(
                color: widget.color.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ]
          : [],
    );

    if (widget.active) {
      return AnimatedBuilder(
        animation: _blinkController,
        builder: (context, child) {
          return Opacity(
            opacity: _blinkController.value > 0.5 ? 1.0 : 0.35,
            child: Text(widget.label, style: style),
          );
        },
      );
    }

    return Text(widget.label, style: style);
  }
}
