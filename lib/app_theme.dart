import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color mainColor;

  const AppTheme({required this.name, required this.mainColor});
}

final List<AppTheme> appThemes = [
  const AppTheme(name: 'Default', mainColor: Color(0xFFE0E0E0)),
  const AppTheme(name: 'Teal', mainColor: Color(0xFF4DB6AC)),
  const AppTheme(name: 'Deep Purple', mainColor: Color(0xFF7E57C2)),
  const AppTheme(name: 'Orange', mainColor: Color(0xFFFFB74D)),
  const AppTheme(name: 'Steel Blue', mainColor: Color(0xFF6483A3)),
  const AppTheme(name: 'Dark', mainColor: Color(0xFF121212)),
  
// Vibrant & Playful
const AppTheme(name: 'Coral Sunset', mainColor: Color(0xFFFF6B6B)),
const AppTheme(name: 'Ocean Blue', mainColor: Color(0xFF4ECDC4)),
const AppTheme(name: 'Lavender Dream', mainColor: Color(0xFFB794F4)),
const AppTheme(name: 'Mint Fresh', mainColor: Color(0xFF48BB78)),

// Professional & Modern
const AppTheme(name: 'Slate Gray', mainColor: Color(0xFF64748B)),
const AppTheme(name: 'Indigo Night', mainColor: Color(0xFF5B21B6)),
const AppTheme(name: 'Forest Green', mainColor: Color(0xFF2D6A4F)),
const AppTheme(name: 'Crimson Red', mainColor: Color(0xFFDC2626)),

// Soft & Elegant
const AppTheme(name: 'Rose Gold', mainColor: Color(0xFFE8B4B8)),
const AppTheme(name: 'Sage Green', mainColor: Color(0xFF9CA986)),
const AppTheme(name: 'Sky Blue', mainColor: Color(0xFF87CEEB)),
const AppTheme(name: 'Peach', mainColor: Color(0xFFFFDAB9)),

// Bold & Energetic
const AppTheme(name: 'Electric Violet', mainColor: Color(0xFF8B5CF6)),
const AppTheme(name: 'Cyber Yellow', mainColor: Color(0xFFFBBF24)),
const AppTheme(name: 'Neon Pink', mainColor: Color(0xFFEC4899)),
const AppTheme(name: 'Turquoise', mainColor: Color(0xFF06B6D4)),

// Sophisticated & Dark
const AppTheme(name: 'Midnight Blue', mainColor: Color(0xFF1E293B)),
const AppTheme(name: 'Charcoal', mainColor: Color(0xFF2D3748)),
const AppTheme(name: 'Deep Emerald', mainColor: Color(0xFF064E3B)),
const AppTheme(name: 'Burgundy', mainColor: Color(0xFF7F1D1D)),

];

ThemeData generateTheme(Color seedColor) {
  final isDark = ThemeData.estimateBrightnessForColor(seedColor) == Brightness.dark;
  final primaryTextColor = isDark ? Colors.white : Colors.black;

  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).copyWith(
      onPrimary: primaryTextColor,
    ),
    scaffoldBackgroundColor: seedColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: primaryTextColor),
      titleTextStyle: TextStyle(
        color: primaryTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    useMaterial3: true,
  );
}