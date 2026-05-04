import 'package:flutter/material.dart';

class StressSenseTheme {
  static ThemeData get lightTheme {
    const base = Color(0xFFE6F5EE);
    const card = Color(0xFFF6FCF9);
    const accent = Color(0xFF6CB593);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: base,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFD9F0E8),
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A9B78),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF14221C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1D3128),
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF243A30),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

