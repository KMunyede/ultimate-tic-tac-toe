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
}

final List<AppTheme> appThemes = [
  const AppTheme(
    name: 'Midnight Cyber (Dark)',
    brightness: Brightness.dark,
    mainColor: Color(0xFF00FFCC), // Electric Cyan
    scaffoldBg: Color(0xFF0A031A), // Dark Space Violet
    boardBg: Color(0xFF1E0E3D), // Deep Violet Neumorphic Card
    accentGlow: Color(0xFFFF007F), // Neon Magenta
    textColor: Colors.white,
    bgGradient: [Color(0xFF0A031A), Color(0xFF1C0A3B), Color(0xFF050110)],
  ),
  const AppTheme(
    name: 'Vaporwave Dream (Dark)',
    brightness: Brightness.dark,
    mainColor: Color(0xFFFF71CE), // Fluorescent Pink
    scaffoldBg: Color(0xFF001733), // Midnight Blue
    boardBg: Color(0xFF05122E), // Translucent Sapphire Card
    accentGlow: Color(0xFF01FFC3), // Fluorescent Cyan
    textColor: Colors.white,
    bgGradient: [Color(0xFF0A001F), Color(0xFF1D0E47), Color(0xFF000E26)],
  ),
  const AppTheme(
    name: 'Retro Arcade (Dark)',
    brightness: Brightness.dark,
    mainColor: Color(0xFF39FF14), // Electric Green
    scaffoldBg: Color(0xFF000000), // Pure Pitch Black
    boardBg: Color(0xFF111111), // Charcoal Grid Card
    accentGlow: Color(0xFFFF2A2A), // Arcade Red
    textColor: Colors.white,
    bgGradient: [Color(0xFF000000), Color(0xFF0D0D0D), Color(0xFF000000)],
  ),
  const AppTheme(
    name: 'Solar Eclipse (Dark)',
    brightness: Brightness.dark,
    mainColor: Color(0xFFFF8C00), // Fire Amber
    scaffoldBg: Color(0xFF121212), // Charcoal Dark
    boardBg: Color(0xFF1E1E1E), // Soft Obsidian Card
    accentGlow: Color(0xFFFFD700), // Gold Flare
    textColor: Colors.white,
    bgGradient: [Color(0xFF121212), Color(0xFF261908), Color(0xFF121212)],
  ),
  const AppTheme(
    name: 'Sunset Glass (Light)',
    brightness: Brightness.light,
    mainColor: Color(0xFFD84315), // Deep Sunset Rust Orange (soft low-glare)
    scaffoldBg: Color(0xFFFCE4D6), // Muted pastel warm clay
    boardBg: Color(0xFFF5C2B1), // Elegant Frosted Peach-Glass Card (No blinding white!)
    accentGlow: Color(0xFFFF8F00), // Vibrant amber flare
    textColor: Color(0xFF3E2723), // Highly visible warm dark chocolate text
    bgGradient: [Color(0xFFFBE9E7), Color(0xFFFFCCBC), Color(0xFFFFD180)],
  ),
  const AppTheme(
    name: 'Ocean Glass (Light)',
    brightness: Brightness.light,
    mainColor: Color(0xFF1565C0), // Calming Deep Ocean Blue
    scaffoldBg: Color(0xFFE1F5FE), // Muted pastel sky blue
    boardBg: Color(0xFFB3E5FC), // Frosted Ice-Blue Glass Card (No blinding white!)
    accentGlow: Color(0xFF00ACC1), // Rich teal water flare
    textColor: Color(0xFF0D47A1), // Highly visible deep navy text
    bgGradient: [Color(0xFFE0F7FA), Color(0xFFB2EBF2), Color(0xFFE1F5FE)],
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
    return hsl
        .withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 1.0);
  }

  static Color getDarkShadow(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    final isDark = hsl.lightness < 0.35;
    
    if (isDark) {
      // In dark mode, dark shadow is deep pitch black
      return const Color(0xFF000000).withValues(alpha: 0.85);
    }
    return hsl
        .withLightness((hsl.lightness - 0.20).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.1).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.5);
  }
}

