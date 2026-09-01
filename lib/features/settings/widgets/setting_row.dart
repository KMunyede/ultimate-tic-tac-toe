// lib/features/settings/widgets/setting_row.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SettingRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final DropdownMenuItem<T> Function(T item) itemBuilder;
  final AppTheme theme;

  const SettingRow({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRushingWind = theme.name == 'Rushing Wind';

    final Widget content = Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: theme.textColor.withValues(alpha: 0.85),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 6,
          child: Align(
            alignment: Alignment.centerRight,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down_rounded, color: theme.mainColor, size: 20),
                dropdownColor: theme.boardBg,
                alignment: Alignment.centerRight,
                borderRadius: BorderRadius.circular(12),
                items: items.map(itemBuilder).toList(),
                onChanged: onChanged,
                style: TextStyle(
                  color: theme.textColor,
                  fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (isRushingWind) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: theme.scaffoldBg.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.textColor.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 14.0),
      child: content,
    );
  }
}
