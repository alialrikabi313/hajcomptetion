import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 💾 جلسة مراجعة محفوظة، لاستئنافها بعد إغلاق التطبيق
class SavedSession {
  final String mode; // topic | random | mistakes
  final String title;
  final int shown;
  final int correct;
  final int wrong;
  final int bestStreak;
  final int poolSize;

  /// معرّفات الأسئلة المتبقية بالترتيب (أولها هو السؤال الحالي)
  final List<int> remaining;

  const SavedSession({
    required this.mode,
    required this.title,
    required this.shown,
    required this.correct,
    required this.wrong,
    required this.bestStreak,
    required this.poolSize,
    required this.remaining,
  });

  Map<String, dynamic> toMap() => {
    'mode': mode,
    'title': title,
    'shown': shown,
    'correct': correct,
    'wrong': wrong,
    'best': bestStreak,
    'pool': poolSize,
    'rem': remaining,
  };

  static SavedSession? fromMap(Map<String, dynamic> m) {
    try {
      return SavedSession(
        mode: (m['mode'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
        shown: (m['shown'] as num?)?.toInt() ?? 0,
        correct: (m['correct'] as num?)?.toInt() ?? 0,
        wrong: (m['wrong'] as num?)?.toInt() ?? 0,
        bestStreak: (m['best'] as num?)?.toInt() ?? 0,
        poolSize: (m['pool'] as num?)?.toInt() ?? 0,
        remaining: ((m['rem'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}

class SessionStore {
  SessionStore._();
  static final SessionStore instance = SessionStore._();

  static const _key = 'saved_session';

  Future<void> save(SavedSession s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(s.toMap()));
  }

  Future<SavedSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final s = SavedSession.fromMap(json.decode(raw) as Map<String, dynamic>);
      if (s == null || s.remaining.isEmpty) return null;
      return s;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
