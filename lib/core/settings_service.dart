import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyDifficulty = 'difficulty';
  static const _keyTimer = 'showTimer';
  static const _keyFontSize = 'fontSize';
  static const _keyPassScore = 'passScore';

  static Future<void> saveSettings({
    required String difficulty,
    required bool showTimer,
    required double fontSize,
    required int passScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDifficulty, difficulty);
    await prefs.setBool(_keyTimer, showTimer);
    await prefs.setDouble(_keyFontSize, fontSize);
    await prefs.setInt(_keyPassScore, passScore);
  }

  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'difficulty': prefs.getString(_keyDifficulty) ?? 'سهل',
      'showTimer': prefs.getBool(_keyTimer) ?? true,
      'fontSize': prefs.getDouble(_keyFontSize) ?? 20.0,
      'passScore': prefs.getInt(_keyPassScore) ?? 15,
    };
  }
}
