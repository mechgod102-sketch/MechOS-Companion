import 'package:flutter/material.dart';

class MechTheme {
  static const bg = Color(0xFF050914);
  static const panel = Color(0xFF0B1220);
  static const panel2 = Color(0xFF111C2E);
  static const border = Color(0xFF20314A);
  static const primary = Color(0xFF168BFF);
  static const glow = Color(0xFF45C7FF);
  static const accent = Color(0xFF7B61FF);
  static const text = Color(0xFFF5F9FF);
  static const subtle = Color(0xFF9BB0C9);
  static const success = Color(0xFF35E6A5);
  static const warning = Color(0xFFFFC857);
  static const danger = Color(0xFFFF6475);

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: primary,
      secondary: glow,
      surface: panel,
      error: danger,
      onPrimary: Colors.white,
      onSecondary: Color(0xFF00131E),
      onSurface: text,
      onError: Colors.white,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF091321),
        labelStyle: TextStyle(color: subtle),
        hintStyle: TextStyle(color: Color(0xFF6E839C)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: glow, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: glow,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: const Color(0xFF07101C),
        indicatorColor: primary.withValues(alpha: .22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected) ? glow : subtle,
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? glow : subtle,
            )),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF132238),
        contentTextStyle: TextStyle(color: text),
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: border,
    );
  }
}
