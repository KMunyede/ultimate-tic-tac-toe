// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Color get colorX => mainColor;
  Color get colorO => accentGlow;
}

final List<AppTheme> appThemes = [
  const AppTheme(
    name: 'Rushing Wind',
    brightness: Brightness.light,
    mainColor: Color(0xFF70806A), // Hand-drawn organic sage green
    scaffoldBg: Color(0xFFBDC7BC), // Midpoint serene eye-friendly misty sage green
    boardBg: Color(0xFFE4E1DA), // Tactile warm cream clay board
    accentGlow: Color(0xFFC6A476), // Warm sandy ochre
    textColor: Color(0xFF384335), // Nature deep forest-charcoal-sage
    bgGradient: [Color(0xFFC3CEC2), Color(0xFFBAC7B8), Color(0xFFB0BEAE)],
  ),
  const AppTheme(
    name: 'Floating Feather',
    brightness: Brightness.light,
    mainColor: Color(0xFFD37E65), // Soft Peach Blossom / Terracotta
    scaffoldBg: Color(0xFFFDF6F0), // Creamy Apricot Blush
    boardBg: Color(0xFFF3E4D9), // Powdery Silk Card
    accentGlow: Color(0xFFB5937E), // Soft Clay Rose
    textColor: Color(0xFF5E4B43), // Gentle Deep Earth
    bgGradient: [Color(0xFFFEF8F5), Color(0xFFF8EEE4), Color(0xFFF3E4D9)],
  ),
  const AppTheme(
    name: 'Rising Moon',
    brightness: Brightness.light,
    mainColor: Color(0xFF8B7AA0), // Soft Dusty Lavender
    scaffoldBg: Color(0xFFF5F3F8), // Creamy Lavender Mist
    boardBg: Color(0xFFE7E2EE), // Powdery Lavender Card
    accentGlow: Color(0xFFAB9993), // Soft Dusty Rose-Beige
    textColor: Color(0xFF453D4D), // Gentle Deep Plum
    bgGradient: [Color(0xFFFAF8FC), Color(0xFFF1EDF5), Color(0xFFE7E2EE)],
  ),
  const AppTheme(
    name: 'Drifting Cloud',
    brightness: Brightness.light,
    mainColor: Color(0xFF5C8A97), // Muted Powder Jade Blue
    scaffoldBg: Color(0xFFF3F7F8), // Creamy Soft Pearl White
    boardBg: Color(0xFFE3ECEF), // Soft Powdery Blue-Grey Card
    accentGlow: Color(0xFFD4B38A), // Gentle Warm Ochre/Sand Glow
    textColor: Color(0xFF384F56), // Gentle Soft Slate Blue
    bgGradient: [Color(0xFFF6FAF9), Color(0xFFEDF3F2), Color(0xFFE3ECEF)],
  ),
  const AppTheme(
    name: 'Crimson Leaf',
    brightness: Brightness.light,
    mainColor: Color(0xFFC26D6D), // Muted Dusty Autumn Crimson
    scaffoldBg: Color(0xFFFCF5F5), // Soft Powdery Blossom Cream
    boardBg: Color(0xFFF0E0E0), // Soft Clay Rose Card
    accentGlow: Color(0xFFCCA67C), // Gentle Antique Gold Glow
    textColor: Color(0xFF563A3A), // Gentle Deep Walnut Rosewood
    bgGradient: [Color(0xFFFAF6F6), Color(0xFFF3EDED), Color(0xFFF0E0E0)],
  ),
];

ThemeData generateTheme(AppTheme theme) {
  final primaryColor = theme.mainColor;

  return ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.outfit().fontFamily,
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
        foregroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(2.0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: theme.textColor.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: theme.textColor.withValues(alpha: 0.75)),
      displayLarge: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(
        color: theme.textColor,
        fontWeight: FontWeight.bold,
      ),
    ),
    scaffoldBackgroundColor: theme.scaffoldBg,
    appBarTheme: AppBarTheme(
      backgroundColor: theme.scaffoldBg,
      foregroundColor: theme.textColor,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: theme.textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class NeumorphicColors {
  static Color getLightShadow(Color baseColor) {
    if (baseColor == const Color(0xFF323D2E)) {
      return const Color(0xFF43523F).withValues(alpha: 0.85); // Rushing Wind - Soft lightened sage highlight
    }
    if (baseColor == const Color(0xFFE4E1DA)) {
      return const Color(0xFFFFFDF8).withValues(alpha: 0.90); // Rushing Wind (Midpoint)
    }
    // Pure bright white sheen creates the premium frosted glass/clay edge glare
    return Colors.white.withValues(alpha: 0.95);
  }

  static Color getDarkShadow(Color baseColor) {
    if (baseColor == const Color(0xFF323D2E)) {
      return const Color(0xFF1B2219).withValues(alpha: 0.85); // Rushing Wind - Soft lightened deep forest shadow
    } else if (baseColor == const Color(0xFFE4E1DA)) {
      return const Color(0xFFC4C1B6).withValues(alpha: 0.55); // Rushing Wind - Deeper shadow (Midpoint)
    } else if (baseColor == const Color(0xFFF3E4D9)) {
      return const Color(0xFFCBB6A6).withValues(alpha: 0.55); // Floating Feather
    } else if (baseColor == const Color(0xFFE7E2EE)) {
      return const Color(0xFFC0B6CA).withValues(alpha: 0.55); // Rising Moon
    } else if (baseColor == const Color(0xFFE3ECEF)) {
      return const Color(0xFFBCCCD0).withValues(alpha: 0.55); // Drifting Cloud
    } else if (baseColor == const Color(0xFFF0E0E0)) {
      return const Color(0xFFCBB5B5).withValues(alpha: 0.55); // Crimson Leaf
    }

    final hsl = HSLColor.fromColor(baseColor);
    // Increase lightness reduction and saturation slightly for solid volumetric 3D clay shadow thickness
    return hsl
        .withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation + 0.10).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.55);
  }
}
