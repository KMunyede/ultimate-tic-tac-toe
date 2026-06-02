// lib/features/game/widgets/floating_cloud_button.dart

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../settings/logic/settings_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/board/clay_bevel_painter.dart';

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
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
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
    BorderRadius btnRadius = BorderRadius.circular(30.0);

    if (theme.name == 'Rushing Wind') {
      // Warm Clay button style
      btnRadius = BorderRadius.circular(20.0);
      buttonDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: btnRadius,
        boxShadow: [
          BoxShadow(
            color: NeumorphicColors.getDarkShadow(theme.boardBg),
            offset: const Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: NeumorphicColors.getLightShadow(theme.boardBg),
            offset: const Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      );
      contentColor = theme.mainColor; // Muted Sage Green
    } else if (theme.name == 'Amazon Jungle') {
      // Lush mossy canopy green button with warm gold trim
      btnRadius = BorderRadius.circular(14.0);
      buttonDec = BoxDecoration(
        color: const Color(0xFF2E5A27),
        borderRadius: btnRadius,
        border: Border.all(color: theme.accentGlow.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            offset: const Offset(0, 4),
            blurRadius: 8.0,
          ),
        ],
      );
      contentColor = theme.accentGlow; // warm gold text
    } else if (theme.name == 'Rising Moon') {
      // Frosted twilight neon glass button
      btnRadius = BorderRadius.circular(30.0);
      buttonDec = BoxDecoration(
        color: const Color(0xFF453D4D).withValues(alpha: 0.30),
        borderRadius: btnRadius,
        border: Border.all(color: theme.mainColor.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: theme.mainColor.withValues(alpha: 0.20),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
      contentColor = theme.mainColor;
    } else if (theme.name == 'Drifting Cloud') {
      // Blocky stone button
      btnRadius = BorderRadius.circular(8.0);
      buttonDec = BoxDecoration(
        color: theme.boardBg,
        borderRadius: btnRadius,
        border: Border.all(color: theme.textColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: theme.textColor,
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      );
      contentColor = theme.mainColor;
    } else if (theme.name == 'Crimson Leaf') {
      // Red lacquer button with gold trim
      btnRadius = BorderRadius.circular(12.0);
      buttonDec = BoxDecoration(
        color: theme.mainColor, // Autumn Crimson
        borderRadius: btnRadius,
        border: Border.all(color: theme.accentGlow, width: 1.5), // Gold trim
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      );
      contentColor = theme.accentGlow; // glistening gold text!
    } else {
      // Fallback: Default powdery soft cloud button
      buttonDec = BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: btnRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 10),
            blurRadius: 18.0,
            spreadRadius: 1.0,
          ),
        ],
      );
      contentColor = theme.mainColor;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isVeryNarrow = screenWidth < 380;
    final bool isNarrow = screenWidth < 480;
    final bool isTablet = screenWidth >= 600;

    final double horizPadding = isVeryNarrow ? 6.0 : (isNarrow ? 10.0 : (isTablet ? 30.0 : 22.0));
    final double vertPadding = isVeryNarrow ? 8.0 : (isNarrow ? 10.0 : (isTablet ? 16.0 : 12.0));
    final double iconSize = isVeryNarrow ? 12.0 : (isNarrow ? 15.0 : (isTablet ? 22.0 : 18.0));
    final double fontSize = isVeryNarrow ? 9.2 : (isNarrow ? 11.0 : (isTablet ? 16.0 : 14.0));
    final double spacing = isVeryNarrow ? 2.0 : (isNarrow ? 4.0 : (isTablet ? 10.0 : 8.0));

    final bool isEnabled = widget.onTap != null;

    Widget buttonBody = Opacity(
      opacity: isEnabled ? 1.0 : 0.42,
      child: Container(
        decoration: buttonDec,
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
                  Icon(widget.icon, size: iconSize, color: contentColor),
                  SizedBox(width: spacing),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: contentColor.withValues(alpha: 0.95),
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      letterSpacing: isNarrow ? 0.6 : 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Apply BackdropFilter blur only for Rising Moon (neon glass) to achieve premium frosted tab glass!
    if (theme.name == 'Rising Moon') {
      buttonBody = ClipRRect(
        borderRadius: btnRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: buttonBody,
        ),
      );
    } else if (theme.name == 'Rushing Wind') {
      // Wrap Rushing Wind buttons in a ClayBevelPainter to match the clay cards!
      buttonBody = CustomPaint(
        painter: ClayBevelPainter(
          borderRadius: 20.0,
          baseColor: theme.boardBg,
          themeName: theme.name,
        ),
        child: buttonBody,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double offset = sin(_controller.value * 2 * pi) * 4.0;
        return Transform.translate(
          offset: Offset(0, offset),
          child: child,
        );
      },
      child: buttonBody,
    );
  }
}
