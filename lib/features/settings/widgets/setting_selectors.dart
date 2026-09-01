// lib/features/settings/widgets/setting_selectors.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../logic/settings_controller.dart';

class ThemeSelector extends StatelessWidget {
  final SettingsController settings;
  final AppTheme currentTheme;

  const ThemeSelector({super.key, required this.settings, required this.currentTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('VISUAL THEME', currentTheme),
        const SizedBox(height: 4),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: currentTheme.scaffoldBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: currentTheme.mainColor.withValues(alpha: 0.2)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: appThemes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final theme = appThemes[index];
              final isSelected = theme.name == currentTheme.name;
              return GestureDetector(
                onTap: () => settings.changeTheme(theme),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? currentTheme.mainColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    theme.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : currentTheme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.mainColor, letterSpacing: 1.0),
      ),
    );
  }
}

class GenericSelector<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T selectedValue;
  final Function(T) onSelected;
  final String Function(T) labelBuilder;
  final AppTheme theme;

  const GenericSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.labelBuilder,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label, theme),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: theme.scaffoldBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.mainColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: options.map((option) {
              final isSelected = option == selectedValue;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(option),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.mainColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      labelBuilder(option),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : theme.textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: theme.mainColor, letterSpacing: 1.0),
      ),
    );
  }
}
