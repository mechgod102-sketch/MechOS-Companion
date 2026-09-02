import 'package:flutter/material.dart';

class MechTheme {
  static const bg = Color(0xFF090B13);
  static const panel = Color(0xFF111625);
  static const panel2 = Color(0xFF171D31);
  static const border = Color(0xFF2D3552);
  static const primary = Color(0xFF6E70FF);
  static const text = Color(0xFFF2F4FF);
  static const subtle = Color(0xFF9CA7C6);
  static const success = Color(0xFF5BD6A2);
  static const warning = Color(0xFFFFC857);
  static const danger = Color(0xFFFF6B7A);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: panel,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      cardTheme: const CardThemeData(
        color: panel,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF0D1220),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF0D101B),
        indicatorColor: Color(0xFF252B55),
      ),
    );
  }
}
