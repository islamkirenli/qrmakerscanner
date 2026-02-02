import 'package:flutter/material.dart';

ThemeData buildQrTheme() {
  const background = Color(0xFFF1E6D9);
  const primary = Color(0xFF6A704C);
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    secondary: primary,
    onSecondary: Colors.white,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    background: background,
    onBackground: Colors.black,
    surface: background,
    onSurface: Colors.black,
  );
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: colorScheme.onSurface,
      centerTitle: true,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: background,
      selectedItemColor: primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
      ),
    ),
    iconTheme: const IconThemeData(color: primary),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: const CardThemeData(
      color: background,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
