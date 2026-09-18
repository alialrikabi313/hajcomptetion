import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'constants.dart';

/// ⚙️ حفظ وتحميل إعدادات التطبيق
class SettingsService {
  static const _keyTimer = 'showTimer';
  static const _keySeconds = 'secondsPerQuestion';
  static const _keyFontSize = 'fontSize';
  static const _keySound = 'soundEnabled';
  static const _keyTheme = 'themeMode';

  /// تحميل الإعدادات وتطبيقها مباشرة على [K] و[appThemeMode]
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    K.showTimer = prefs.getBool(_keyTimer) ?? false;
    K.secondsPerQuestion = prefs.getInt(_keySeconds) ?? 45;
    K.fontSize = prefs.getDouble(_keyFontSize) ?? 19;
    K.soundEnabled = prefs.getBool(_keySound) ?? true;
    appThemeMode.value = _decodeTheme(prefs.getString(_keyTheme));
  }

  /// حفظ القيم الحالية
  static Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTimer, K.showTimer);
    await prefs.setInt(_keySeconds, K.secondsPerQuestion);
    await prefs.setDouble(_keyFontSize, K.fontSize);
    await prefs.setBool(_keySound, K.soundEnabled);
    await prefs.setString(_keyTheme, _encodeTheme(appThemeMode.value));
  }

  static ThemeMode _decodeTheme(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String _encodeTheme(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
