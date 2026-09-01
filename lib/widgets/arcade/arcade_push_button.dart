// lib/widgets/arcade/arcade_push_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArcadePushButton extends StatefulWidget {
  final String label;
  final String actionText;
  final Color buttonColor;
  final VoidCallback onTap;
  final double size;

  const ArcadePushButton({
    super.key,
    required this.label,
    required this.actionText,
    required this.buttonColor,
    required this.onTap,
    this.size = 56.0,
  });

  @override
  State<ArcadePushButton> createState() => _ArcadePushButtonState();
}

class _ArcadePushButtonState extends State<ArcadePushButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late double _currentPressedOffset;

  @override
  void initState() {
    super.initState();
    _currentPressedOffset = 0.0;
  }

  void _handleTapDown() {
    setState(() {
      _isPressed = true;
      _currentPressedOffset = 3.5;
    });
    HapticFeedback.mediumImpact();
  }

  void _handleTapUp() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
        _currentPressedOffset = 0.0;
      });
      widget.onTap();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
        _currentPressedOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final Color buttonColor = widget.buttonColor;
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    final isLight = theme.brightness == Brightness.light;
    
    final rimColor = isLight 
        ? Color.lerp(theme.scaffoldBackgroundColor, Colors.grey.shade400, 0.45)!
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade400);
    final socketColor = isLight
        ? Color.lerp(theme.scaffoldBackgroundColor, Colors.grey.shade500, 0.7)!
        : (isDark ? Colors.black87 : Colors.grey.shade300);

    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _handleTapCancel(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: size + 12,
            height: size + 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size + 10,
                  height: size + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rimColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: size + 2,
                  height: size + 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: socketColor,
                  ),
                ),
                Positioned(
                  top: 6.0 + _currentPressedOffset,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 60),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          buttonColor,
                          Color.lerp(buttonColor, isLight ? Colors.white : Colors.black, isLight ? 0.22 : 0.45)!,
                        ],
                        center: const Alignment(-0.25, -0.25),
                        radius: 0.85,
                      ),
                      boxShadow: _isPressed
                          ? []
                          : [
                              BoxShadow(
                                color: buttonColor.withValues(alpha: isLight ? 0.35 : 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: isLight 
                                    ? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.12) ?? Colors.black12
                                    : Colors.black.withValues(alpha: 0.7),
                                blurRadius: 4,
                                offset: const Offset(0, 3.5),
                              ),
                            ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: size * 0.08,
                          left: size * 0.18,
                          child: Container(
                            width: size * 0.64,
                            height: size * 0.28,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.all(
                                Radius.elliptical(size * 0.32, size * 0.14),
                              ),
                            ),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              widget.actionText.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    offset: const Offset(0, 1.5),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
