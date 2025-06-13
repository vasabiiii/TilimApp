import 'package:flutter/material.dart';

extension CustomColorScheme on ColorScheme {
  Color get quaternary => AppTheme.quaternary;
}

class AppTheme {
  static const Color primary = Color(0xFF0A0178);
  static const Color secondary = Color(0xFFFFD700);
  static const Color tertiary = Color(0xFF4169E1);
  static const Color quaternary = Color.fromARGB(255, 10, 131, 83);
  static const Color background = Color(0xFF000080);
  static const Color text = Colors.white;
  static const Color error = Color(0xFFE53935);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      splashFactory: NoSplash.splashFactory,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: tertiary,
        background: background,
        error: error,
        onBackground: text,
        surfaceTint: quaternary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: text),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: text,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: text,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: text,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color.fromARGB(255, 2, 20, 80),
      ),
    );
  }
} 