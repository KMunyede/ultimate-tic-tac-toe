import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color mainColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color textColor;

  const AppTheme({
    required this.name,
    required this.mainColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.textColor,
  });
}

final List<AppTheme> appThemes = [
  const AppTheme(
    name: 'Forest Green',
    mainColor: Color(0xFF228B22),
    gradientStart: Color(0xFF2E8B57),
    gradientEnd: Color(0xFF3CB371),
    textColor: Colors.white,
  ),
  const AppTheme(
    name: 'Ocean Blue',
    mainColor: Color(0xFF1E90FF),
    gradientStart: Color(0xFF4682B4),
    gradientEnd: Color(0xFFADD8E6),
    textColor: Colors.white,
  ),
  const AppTheme(
    name: 'Sunset Orange',
    mainColor: Color(0xFFFF4500),
    gradientStart: Color(0xFFFF8C00),
    gradientEnd: Color(0xFFFFA500),
    textColor: Colors.white,
  ),
  const AppTheme(
    name: 'Royal Purple',
    mainColor: Color(0xFF8A2BE2),
    gradientStart: Color(0xFF9370DB),
    gradientEnd: Color(0xFFBA55D3),
    textColor: Colors.white,
  ),
   const AppTheme(name: 'Charcoal', mainColor: Color(0xFF2D3748), gradientStart: Color(0xFF2D3748), gradientEnd: Color(0xFF4A5568), textColor: Colors.white),
   const AppTheme(name: 'Deep Emerald', mainColor: Color(0xFF064E3B), gradientStart: Color(0xFF064E3B), gradientEnd: Color(0xFF047857), textColor: Colors.white),
   const AppTheme(name: 'Burgundy', mainColor: Color(0xFF7F1D1D), gradientStart: Color(0xFF7F1D1D), gradientEnd: Color(0xFFB91C1C), textColor: Colors.white),
];

ThemeData generateTheme(Color seedColor) {
  final isDark = ThemeData.estimateBrightnessForColor(seedColor) == Brightness.dark;
  final primaryTextColor = isDark ? Colors.white : Colors.black;
  
  return ThemeData(
    primaryColor: seedColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(seedColor),
        foregroundColor: WidgetStateProperty.all(primaryTextColor),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: primaryTextColor),
      bodyMedium: TextStyle(color: primaryTextColor),
    )
  );
}
