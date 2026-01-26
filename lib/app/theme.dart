import 'package:flutter/material.dart';

ThemeData buildQrTheme() {
  const seed = Color(0xFF1E6B5A);
  final colorScheme = ColorScheme.fromSeed(seedColor: seed);
  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF7F6F2),
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: true,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
