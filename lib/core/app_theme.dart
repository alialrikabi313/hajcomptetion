import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const primary = Color(0xFF16213E);
  const secondary = Color(0xFF0F3460);
  const accent = Color(0xFF00ADB5);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light),
    scaffoldBackgroundColor: secondary,
    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 2,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
      titleLarge: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00ADB5),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1F4068),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    ),
  );
}
