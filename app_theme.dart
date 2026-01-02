import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color mainColor;
  final Color gradientStart;
  final Color gradientEnd;

  const AppTheme({
    required this.name,
    required this.mainColor,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

final List<AppTheme> appThemes = [
  const AppTheme(
    name: 'Forest Green',
    mainColor: Color(0xFF228B22),
    gradientStart: Color(0xFF2E8B57),
    gradientEnd: Color(0xFF3CB371),
  ),
  const AppTheme(
    name: 'Ocean Blue',
    mainColor: Color(0xFF1E90FF),
    gradientStart: Color(0xFF4682B4),
    gradientEnd: Color(0xFFADD8E6),
  ),
  const AppTheme(
    name: 'Sunset Orange',
    mainColor: Color(0xFFFF4500),
    gradientStart: Color(0xFFFF8C00),
    gradientEnd: Color(0xFFFFA500),
  ),
  const AppTheme(
    name: 'Royal Purple',
    mainColor: Color(0xFF8A2BE2),
    gradientStart: Color(0xFF9370DB),
    gradientEnd: Color(0xFFBA55D3),
  ),
];

ThemeData generateTheme(Color mainColor) {
  return ThemeData(
    primaryColor: mainColor,
    colorScheme: ColorScheme.fromSeed(seedColor: mainColor),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(mainColor),
      ),
    ),
  );
}
