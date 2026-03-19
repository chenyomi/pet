import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const seed = Color(0xFFE0A83E);

  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
    surface: const Color(0xFFFFF5DA),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF5E5AA),
    fontFamily: 'monospace',
    cardTheme: const CardThemeData(
      color: Color(0xFFFFF8E6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        side: BorderSide(color: Color(0xFF20363A), width: 3),
      ),
    ),
  );
}
