// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  final String name;
  final Brightness brightness;
  final Color mainColor;
  final Color scaffoldBg;
  final Color boardBg;
  final Color accentGlow;
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
    mainColor: Color(0xFF33691E), // Dimmed Green (X)
    scaffoldBg: Color(0xFFC5E1A5), // Dimmed Mint
    boardBg: Color(0xFF9CCC65), // Dimmed Board
    accentGlow: Color(0xFFFFD54F), // Gold Contrast (O)
    textColor: Color(0xFF1B5E20),
    bgGradient: [Color(0xFFC5E1A5), Color(0xFFAED581)],
  ),
  const AppTheme(
    name: 'Amazon Jungle',
    brightness: Brightness.dark,
    mainColor: Color(0xFF2E7D32), // Dimmed Jungle Green (X)
    scaffoldBg: Color(0xFF003300), // Dimmed Forest
    boardBg: Color(0xFF3E2723), // Dimmed Wood
    accentGlow: Color(0xFFFF8F00), // Amber Contrast (O)
    textColor: Color(0xFFC8E6C9),
    bgGradient: [Color(0xFF003300), Color(0xFF002200)],
  ),
  const AppTheme(
    name: 'Pacific Waves',
    brightness: Brightness.light,
    mainColor: Color(0xFFE65100), // Dimmed Orange (X)
    scaffoldBg: Color(0xFF81D4FA), // Dimmed Sky
    boardBg: Color(0xFF6D4C41), // Dimmed Bamboo
    accentGlow: Color(0xFFFFEB3B), // Fixed: Yellow Contrast (O)
    textColor: Color(0xFFFFFFFF), // Fixed: White for high contrast on Brown/Orange
    bgGradient: [Color(0xFF81D4FA), Color(0xFF4FC3F7)],
  ),
  const AppTheme(
    name: 'River Flow',
    brightness: Brightness.dark,
    mainColor: Color(0xFF00838F), // Dimmed Cyan (X)
    scaffoldBg: Color(0xFF004D40), // Dimmed Deep Teal
    boardBg: Color(0xFF2D1B14), // Dimmed Wet Wood
    accentGlow: Color(0xFF9E9D24), // Mossy Lime Contrast (O)
    textColor: Color(0xFFB2DFDB),
    bgGradient: [Color(0xFF004D40), Color(0xFF00332E)],
  ),
  const AppTheme(
    name: 'Drifting Cloud',
    brightness: Brightness.dark, // Changed to Dark for Slate Contrast
    mainColor: Color(0xFFFFFFFF), // Pure White (X)
    scaffoldBg: Color(0xFF263238), // Stormy Slate
    boardBg: Color(0xFF455A64), // Deep Blue Grey
    accentGlow: Color(0xFF81D4FA), // Sky Blue (O)
    textColor: Color(0xFFECEFF1), // Off-white
    bgGradient: [Color(0xFF263238), Color(0xFF10191E)],
  ),
  const AppTheme(
    name: 'Crimson Leaf',
    brightness: Brightness.dark, // Changed to Dark for Brown Contrast
    mainColor: Color(0xFFFFEB3B), // Vibrant Yellow (X)
    scaffoldBg: Color(0xFF3E2723), // Earth Brown
    boardBg: Color(0xFF5D4037), // Warm Terracotta
    accentGlow: Color(0xFFFF7043), // Bright Coral (O)
    textColor: Color(0xFFFFF3E0), // Cream
    bgGradient: [Color(0xFF3E2723), Color(0xFF2D1B14)],
  ),
  const AppTheme(
    name: 'Studio Pro Light',
    brightness: Brightness.light,
    mainColor: Color(0xFF00796B), // Deep Teal (X)
    scaffoldBg: Color(0xFFECEFF1), // Soft Off-white
    boardBg: Color(0xFFCFD8DC), // Cool Light Grey
    accentGlow: Color(0xFFD32F2F), // Pro Red (O)
    textColor: Color(0xFF263238), // Dark Slate
    bgGradient: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
  ),
  const AppTheme(
    name: 'Studio Pro Dark',
    brightness: Brightness.dark,
    mainColor: Color(0xFF4FC3F7), // Safety Blue (X)
    scaffoldBg: Color(0xFF101214), // Deep Navy Black
    boardBg: Color(0xFF263238), // Matte Slate
    accentGlow: Color(0xFF80CBC4), // Mint Teal (O)
    textColor: Color(0xFFECEFF1), // Off-white
    bgGradient: [Color(0xFF101214), Color(0xFF000000)],
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
        elevation: WidgetStateProperty.all(0.0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: theme.textColor, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(color: theme.textColor.withValues(alpha: 0.8)),
      displayLarge: TextStyle(color: theme.textColor, fontWeight: FontWeight.w900),
      headlineSmall: TextStyle(
        color: theme.textColor,
        fontWeight: FontWeight.w900,
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
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class NeumorphicColors {
  static Color getLightShadow(Color baseColor) {
    if (baseColor.computeLuminance() > 0.5) {
      return Colors.white.withValues(alpha: 0.7);
    }
    return baseColor.withValues(alpha: 0.2);
  }

  static Color getDarkShadow(Color baseColor) {
    if (baseColor.computeLuminance() > 0.5) {
      return Colors.black.withValues(alpha: 0.2);
    }
    return Colors.black.withValues(alpha: 0.3);
  }
}
