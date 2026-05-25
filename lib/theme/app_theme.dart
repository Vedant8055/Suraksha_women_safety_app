import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2C79C9);
  static const Color secondaryColor = Color(0xFF53A7F5);
  static const Color accentColor = Color(0xFFE35D63);
  static const Color backgroundColor = Color(0xFF0A1530);
  static const Color cardColor = Color(0xFF16274A);
  static const Color surfaceSoft = Color(0xFF223A67);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFD3DFEF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: accentColor,
        surface: cardColor,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
          bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: cardColor.withValues(alpha: 0.9),
        shadowColor: Colors.black.withValues(alpha: 0.35),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    const softBg = Color(0xFFF4F7FB);
    const softCard = Color(0xFFEAF0F8);
    const softSurface = Color(0xFFDDE8F6);
    const softText = Color(0xFF1F2C40);
    const softTextMuted = Color(0xFF5E6E88);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: softBg,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: accentColor,
        surface: softCard,
        onSurface: softText,
      ),
      textTheme: GoogleFonts.manropeTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: softText,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: softText,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: softText),
          bodyMedium: TextStyle(fontSize: 14, color: softTextMuted),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: softText,
      ),
      cardTheme: CardThemeData(
        color: softCard,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: softSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
