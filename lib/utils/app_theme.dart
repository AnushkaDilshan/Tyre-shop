import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFFE94560);
  static const Color secondaryColor = Color(0xFF16213E);
  static const Color cardColor = Color(0xFF0F3460);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color textLight = Color(0xFFECECEC);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color goldColor = Color(0xFFFFD700);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: accentColor,
        secondary: cardColor,
        surface: secondaryColor,         // 'background' removed (deprecated)
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textLight,
        displayColor: textLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: secondaryColor,
        foregroundColor: textLight,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: textLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(           // CardTheme → CardThemeData
        color: secondaryColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
        labelStyle: const TextStyle(color: textMuted),
        hintStyle: const TextStyle(color: textMuted),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: secondaryColor,
        selectedItemColor: accentColor,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}