// lib/features/settings/widgets/setting_toggles.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class IconToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final AppTheme theme;
  final VoidCallback onTap;

  const IconToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? theme.mainColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? theme.mainColor.withValues(alpha: 0.4) : theme.textColor.withValues(alpha: 0.1),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? theme.mainColor : theme.textColor.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? theme.textColor : theme.textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
