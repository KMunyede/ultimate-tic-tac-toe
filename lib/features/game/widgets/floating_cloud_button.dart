// lib/features/game/widgets/floating_cloud_button.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../settings/logic/settings_controller.dart';

class FloatingCloudButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const FloatingCloudButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<FloatingCloudButton> createState() => _FloatingCloudButtonState();
}

class _FloatingCloudButtonState extends State<FloatingCloudButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
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

    // Build theme-specific decoration and text colors!
    Decoration buttonDec;
    Color contentColor;
    BorderRadius btnRadius = BorderRadius.circular(12.0);
    Color bgColor;

    if (theme.name == 'Rushing Wind') {
      bgColor = theme.mainColor;
      contentColor = Colors.white;
    } else if (theme.name == 'Amazon Jungle') {
      bgColor = theme.mainColor;
      contentColor = Colors.white;
    } else if (theme.name == 'Pacific Waves') {
      bgColor = theme.mainColor;
      contentColor = Colors.white;
    } else if (theme.name == 'Drifting Cloud') {
      bgColor = theme.accentGlow; // Sky Blue
      contentColor = theme.textColor; // Off-white
    } else if (theme.name == 'Crimson Leaf') {
      bgColor = theme.mainColor; // Vibrant Yellow
      contentColor = Colors.black; // Max contrast
    } else if (theme.name.contains('Studio Pro')) {
      bgColor = theme.mainColor;
      contentColor = theme.brightness == Brightness.light ? Colors.white : Colors.black;
    } else {
      bgColor = theme.mainColor;
      contentColor = Colors.white;
    }

    buttonDec = BoxDecoration(
      color: bgColor,
      borderRadius: btnRadius,
      border: Border.all(color: Colors.black, width: 2.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          offset: const Offset(4, 4),
          blurRadius: 0, // Sharp cartoon shadow
        ),
      ],
    );

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isVeryNarrow = screenWidth < 380;
    final bool isNarrow = screenWidth < 480;
    final bool isTablet = screenWidth >= 600;

    final double horizPadding = isVeryNarrow ? 8.0 : (isNarrow ? 12.0 : (isTablet ? 30.0 : 22.0));
    final double vertPadding = isVeryNarrow ? 10.0 : (isNarrow ? 12.0 : (isTablet ? 16.0 : 12.0));
    final double iconSize = isVeryNarrow ? 14.0 : (isNarrow ? 16.0 : (isTablet ? 22.0 : 18.0));
    final double fontSize = isVeryNarrow ? 10.0 : (isNarrow ? 12.0 : (isTablet ? 16.0 : 14.0));
    final double spacing = isVeryNarrow ? 4.0 : (isNarrow ? 6.0 : (isTablet ? 10.0 : 8.0));

    final bool isEnabled = widget.onTap != null;
    final double opacity = isEnabled ? 1.0 : 0.5;

    Widget buttonBody = RepaintBoundary(
      child: Container(
        decoration: buttonDec is BoxDecoration 
            ? buttonDec.copyWith(
                color: buttonDec.color?.withValues(alpha: buttonDec.color!.a * opacity),
              )
            : buttonDec,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: btnRadius,
            onTap: isEnabled ? widget.onTap : null,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizPadding,
                vertical: vertPadding,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: iconSize, color: contentColor.withValues(alpha: opacity)),
                  SizedBox(width: spacing),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: contentColor.withValues(alpha: 0.95 * opacity),
                      fontWeight: FontWeight.w900,
                      fontSize: fontSize,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double angle = _controller.value * 2 * pi;
        final double dx = sin(angle) * 3.0;
        final double dy = cos(angle * 0.8) * 4.0;
        
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: child,
          ),
        );
      },
      child: buttonBody,
    );
  }
}
