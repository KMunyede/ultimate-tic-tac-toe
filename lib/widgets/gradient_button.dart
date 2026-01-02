import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Widget child;
  final Color textColor;

  const GradientButton({
    super.key,
    this.onPressed,
    required this.gradient,
    required this.child,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: Colors.black.withAlpha(102),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            constraints: const BoxConstraints(minHeight: 36),
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: TextStyle(color: textColor),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
