import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Brightness brightness;
  final Color mainColor;       // Button/Appbar/Main highlight color
  final Color scaffoldBg;      // Base background color
  final Color boardBg;         // Core tactile sub-board background
  final Color accentGlow;      // special effects and locks golden glow
  final Color textColor;
  final List<Color> bgGradient;

  const AppTheme({
    required this.name,
    required this.brightness,
    required this.mainColor,
    required this.scaffoldBg,
    required this.boardBg,
    required this.accentGlow,
    required this.textColor,
    required this.bgGradient,
  });

  Color get colorX {
    if (name.contains('Neon Cyberpulse')) return accentGlow; // Neon Pink
    if (name.contains('Candy Meadow')) return accentGlow;    // Ladybug Red
    if (name.contains('Woodville Carve')) return const Color(0xFF8A8A8A); // Slate Grey Stone
    return mainColor;
  }

  Color get colorO {
    if (name.contains('Neon Cyberpulse')) return mainColor;  // Neon Cyan
    if (name.contains('Candy Meadow')) return mainColor;     // Donut Pink
    if (name.contains('Woodville Carve')) return const Color(0xFFFFFFFF); // White Plaster Stone
    return accentGlow;
  }
}

final List<AppTheme> appThemes = [
  const AppTheme(
    name: 'Cyberpunk Neon Cyberpulse (Dark)',
    brightness: Brightness.dark,
    mainColor: Color(0xFF00FFCC), // Neon Cyan
    scaffoldBg: Color(0xFF0A0B10), // Cyber Black
    boardBg: Color(0xFF121420), // Dark Cyber Card
    accentGlow: Color(0xFFFF007F), // Neon Pink/Magenta
    textColor: Colors.white,
    bgGradient: [Color(0xFF08090E), Color(0xFF121422), Color(0xFF040508)],
  ),
  const AppTheme(
    name: 'Ladybug Sugar Candy Meadow (Light)',
    brightness: Brightness.light,
    mainColor: Color(0xFFFF4081), // Donut Frosting Pink
    scaffoldBg: Color(0xFFE2F1E8), // Sky/Meadow pastel base
    boardBg: Color(0xFFFBE9E7), // Cozy Wooden cake/peach base
    accentGlow: Color(0xFFE53935), // Ladybug Red
    textColor: Color(0xFF3E2723), // Wood dark brown
    bgGradient: [Color(0xFFE1F5FE), Color(0xFFE8F5E9), Color(0xFFFFF9C4)], // Sky, meadow & sun colors
  ),
  const AppTheme(
    name: 'Rustic Mahogany Woodville Carve (Warm)',
    brightness: Brightness.light,
    mainColor: Color(0xFFD84315), // Copper Gold
    scaffoldBg: Color(0xFF4E342E), // Deep Mahogany scaffolding
    boardBg: Color(0xFF6D4C41), // Medium warm wood board plate
    accentGlow: Color(0xFFFFB300), // Carved Amber Glow
    textColor: Color(0xFFFFE0B2), // Light wood grain text
    bgGradient: [Color(0xFF3E2723), Color(0xFF4E342E), Color(0xFF5D4037)], // Warm wood grains
  ),
];

ThemeData generateTheme(AppTheme theme) {
  final primaryColor = theme.mainColor;
  final isDark = theme.brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: theme.brightness,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: theme.brightness,
      surface: theme.boardBg,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(primaryColor),
        foregroundColor: WidgetStateProperty.all(isDark ? Colors.black : Colors.white),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: isDark ? Colors.white60 : Colors.black87),
      displayLarge: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.bold,
      ),
    ),
    scaffoldBackgroundColor: theme.scaffoldBg,
    appBarTheme: AppBarTheme(
      backgroundColor: theme.scaffoldBg,
      foregroundColor: isDark ? Colors.white : Colors.black87,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class NeumorphicColors {
  static Color getLightShadow(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    final isDark = hsl.lightness < 0.35;
    
    if (isDark) {
      // In dark mode, light shadow needs to stand out as a soft neon glow
      return hsl
          .withLightness((hsl.lightness + 0.16).clamp(0.0, 1.0))
          .toColor()
          .withValues(alpha: 0.7);
    }
    // In light mode, return a very soft, diffused ambient light sheen (no blinding pure white glare)
    return hsl
        .withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.9);
  }

  static Color getDarkShadow(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    final isDark = hsl.lightness < 0.35;
    
    if (isDark) {
      // In dark mode, dark shadow is deep pitch black
      return const Color(0xFF000000).withValues(alpha: 0.85);
    }
    // In light mode, return a highly-diluted, low-contrast ambient occlusion shadow
    return hsl
        .withLightness((hsl.lightness - 0.09).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.05).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.22);
  }
}
