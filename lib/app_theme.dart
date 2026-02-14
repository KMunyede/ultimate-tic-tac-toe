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
  const AppTheme(
    name: 'Charcoal',
    mainColor: Color(0xFF424242), // True Neutral Grey
    gradientStart: Color(0xFF424242),
    gradientEnd: Color(0xFF616161),
    textColor: Colors.white,
  ),
  const AppTheme(
    name: 'Deep Emerald',
    mainColor: Color(0xFF064E3B),
    gradientStart: Color(0xFF064E3B),
    gradientEnd: Color(0xFF047857),
    textColor: Colors.white,
  ),
  const AppTheme(
    name: 'Burgundy',
    mainColor: Color(0xFF7F1D1D),
    gradientStart: Color(0xFF7F1D1D),
    gradientEnd: Color(0xFFB91C1C),
    textColor: Colors.white,
  ),
];

ThemeData generateTheme(Color seedColor) {
  final hsl = HSLColor.fromColor(seedColor);
  
  // Logic to determine background saturation:
  // If the seed is a neutral color (low saturation), keep the background desaturated.
  // This prevents Charcoal (grey) from looking like a faint blue theme.
  final double targetSaturation = hsl.saturation < 0.15 ? hsl.saturation.clamp(0.0, 0.1) : 0.35;
  
  final Color bgColor = hsl.withLightness(0.85).withSaturation(targetSaturation).toColor();
  
  return ThemeData(
    useMaterial3: true,
    primaryColor: seedColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: bgColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(seedColor),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: Colors.black87),
      displayLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    ),
    scaffoldBackgroundColor: bgColor,
    appBarTheme: AppBarTheme(
      backgroundColor: seedColor,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class NeumorphicColors {
  static Color getLightShadow(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor().withValues(alpha: 1.0);
  }

  static Color getDarkShadow(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl
        .withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.5);
  }
}
