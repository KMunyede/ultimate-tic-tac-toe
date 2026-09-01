import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Gradient gradient;
  final Widget child;
  final Color textColor;
  final EdgeInsetsGeometry? padding;

  const GradientButton({
    super.key,
    this.onPressed,
    required this.gradient,
    required this.child,
    required this.textColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final double opacity = isEnabled ? 1.0 : 0.5;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isEnabled ? 8 : 0,
        shadowColor: Colors.black.withAlpha(102),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient.colors.map((c) => c.withValues(alpha: opacity)).toList(),
            begin: (gradient as LinearGradient).begin,
            end: (gradient as LinearGradient).end,
            stops: (gradient as LinearGradient).stops,
            tileMode: (gradient as LinearGradient).tileMode,
            transform: (gradient as LinearGradient).transform,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          constraints: const BoxConstraints(minHeight: 36),
          alignment: Alignment.center,
          child: DefaultTextStyle(
            style: TextStyle(color: textColor.withValues(alpha: opacity)),
            child: child,
          ),
        ),
      ),
    );
  }
}
