import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 📊 إحصائيات موضوع واحد (أو الإجمالي)
class TopicStats {
  final int answered;
  final int correct;

  const TopicStats({this.answered = 0, this.correct = 0});

  int get wrong => answered - correct;

  double get accuracy => answered == 0 ? 0 : correct / answered;

  int get accuracyPercent => (accuracy * 100).round();
}

/// سجل سؤال واحد: كم مرة ظهر، كم مرة أجيب صحيحاً، وهل آخر إجابة كانت خاطئة
class QuestionRecord {
  final int seen;
  final int correct;
  final bool lastWrong;

  const QuestionRecord({
    this.seen = 0,
    this.correct = 0,
    this.lastWrong = false,
  });

  QuestionRecord next({required bool isCorrect}) => QuestionRecord(
    seen: seen + 1,
    correct: correct + (isCorrect ? 1 : 0),
    lastWrong: !isCorrect,
  );

  String encode() => '$seen,$correct,${lastWrong ? 1 : 0}';

  static QuestionRecord decode(String raw) {
    final parts = raw.split(',');
    if (parts.length < 3) return const QuestionRecord();
    return QuestionRecord(
      seen: int.tryParse(parts[0]) ?? 0,
      correct: int.tryParse(parts[1]) ?? 0,
      lastWrong: parts[2] == '1',
    );
  }
}

/// 💾 كل ما يُحفظ عن تقدّم المستخدم: سجل لكل سؤال + إحصائيات المواضيع
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const _keyHistory = 'q_history';
  static const _prefixAnswered = 'st_ans_';
  static const _prefixCorrect = 'st_cor_';
  static const _keyTotalAnswered = 'st_total_ans';
  static const _keyTotalCorrect = 'st_total_cor';
  static const _keySessions = 'st_sessions';
  static const _keyBestStreak = 'st_best_streak';
  static const _keyDaily = 'st_daily';

  final Map<int, QuestionRecord> _history = {};

  /// نشاط يومي: «yyyy-mm-dd» ← عدد الإجابات
  final Map<String, int> _daily = {};
  bool _loaded = false;
  bool _saving = false;
  bool _dirty = false;

  Map<int, QuestionRecord> get history => Map.unmodifiable(_history);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyHistory);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          final id = int.tryParse(k);
          if (id != null) _history[id] = QuestionRecord.decode(v.toString());
        });
      } catch (_) {
        // سجل تالف: نبدأ من جديد بدل أن نُفشل التطبيق
        _history.clear();
      }
    }
    final rawDaily = prefs.getString(_keyDaily);
    if (rawDaily != null && rawDaily.isNotEmpty) {
      try {
        (json.decode(rawDaily) as Map<String, dynamic>).forEach((k, v) {
          _daily[k] = (v as num).toInt();
        });
      } catch (_) {
        _daily.clear();
      }
    }
    _loaded = true;
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// عدد الإجابات في يوم معيّن
  int answersOn(DateTime day) => _daily[_dayKey(day)] ?? 0;

  /// نشاط آخر [days] يوماً، الأقدم أولاً
  List<({DateTime day, int count})> recentActivity([int days = 7]) {
    final today = DateTime.now();
    return List.generate(days, (i) {
      final d = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: days - 1 - i));
      return (day: d, count: _daily[_dayKey(d)] ?? 0);
    });
  }

  /// سلسلة الأيام المتتالية التي راجعت فيها (تشمل اليوم إن راجعت فيه)
  int dayStreak() {
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if ((_daily[_dayKey(cursor)] ?? 0) == 0) {
      cursor = cursor.subtract(const Duration(days: 1));
      if ((_daily[_dayKey(cursor)] ?? 0) == 0) return 0;
    }
    var streak = 0;
    while ((_daily[_dayKey(cursor)] ?? 0) > 0) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> _persistDaily() async {
    final prefs = await SharedPreferences.getInstance();
    // نحتفظ بآخر ٩٠ يوماً فقط
    if (_daily.length > 90) {
      final keys = _daily.keys.toList()..sort();
      for (final k in keys.take(_daily.length - 90)) {
        _daily.remove(k);
      }
    }
    await prefs.setString(_keyDaily, json.encode(_daily));
  }

  Future<void> _persistHistory() async {
    _dirty = true;
    if (_saving) return;
    _saving = true;
    while (_dirty) {
      _dirty = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _keyHistory,
        json.encode(_history.map((k, v) => MapEntry(k.toString(), v.encode()))),
      );
    }
    _saving = false;
  }

  /// تسجيل إجابة. [trackTopic] يكون false في المراجعة العشوائية،
  /// فلا تُحتسب على إحصائيات الموضوع، لكنها تُسجَّل في سجل السؤال.
  Future<void> recordAnswer({
    required int id,
    required String topic,
    required bool correct,
    bool trackTopic = true,
  }) async {
    await load();
    _history[id] = (_history[id] ?? const QuestionRecord()).next(
      isCorrect: correct,
    );
    final today = _dayKey(DateTime.now());
    _daily[today] = (_daily[today] ?? 0) + 1;
    await _persistHistory();
    await _persistDaily();

    final prefs = await SharedPreferences.getInstance();
    if (trackTopic) {
      await prefs.setInt(
        '$_prefixAnswered$topic',
        (prefs.getInt('$_prefixAnswered$topic') ?? 0) + 1,
      );
      if (correct) {
        await prefs.setInt(
          '$_prefixCorrect$topic',
          (prefs.getInt('$_prefixCorrect$topic') ?? 0) + 1,
        );
      }
    }
    await prefs.setInt(
      _keyTotalAnswered,
      (prefs.getInt(_keyTotalAnswered) ?? 0) + 1,
    );
    if (correct) {
      await prefs.setInt(
        _keyTotalCorrect,
        (prefs.getInt(_keyTotalCorrect) ?? 0) + 1,
      );
    }
  }

  /// معرّفات الأسئلة التي كانت آخر إجابة عليها خاطئة
  Set<int> mistakeIds() =>
      _history.entries.where((e) => e.value.lastWrong).map((e) => e.key).toSet();

  /// معرّفات كل سؤال ظهر للمستخدم مرة على الأقل
  Set<int> seenIds() => _history.keys.toSet();

  bool isMistake(int id) => _history[id]?.lastWrong ?? false;

  Future<void> recordSession({required int bestStreak}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySessions, (prefs.getInt(_keySessions) ?? 0) + 1);
    final best = prefs.getInt(_keyBestStreak) ?? 0;
    if (bestStreak > best) await prefs.setInt(_keyBestStreak, bestStreak);
  }

  Future<TopicStats> forTopic(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    return TopicStats(
      answered: prefs.getInt('$_prefixAnswered$topic') ?? 0,
      correct: prefs.getInt('$_prefixCorrect$topic') ?? 0,
    );
  }

  Future<Map<String, TopicStats>> forTopics(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final t in topics)
        t: TopicStats(
          answered: prefs.getInt('$_prefixAnswered$t') ?? 0,
          correct: prefs.getInt('$_prefixCorrect$t') ?? 0,
        ),
    };
  }

  Future<TopicStats> overall() async {
    final prefs = await SharedPreferences.getInstance();
    return TopicStats(
      answered: prefs.getInt(_keyTotalAnswered) ?? 0,
      correct: prefs.getInt(_keyTotalCorrect) ?? 0,
    );
  }

  Future<int> sessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySessions) ?? 0;
  }

  Future<int> bestStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBestStreak) ?? 0;
  }

  /// مسح كل شيء: السجل والإحصائيات
  Future<void> resetAll(List<String> topics) async {
    final prefs = await SharedPreferences.getInstance();
    for (final t in topics) {
      await prefs.remove('$_prefixAnswered$t');
      await prefs.remove('$_prefixCorrect$t');
    }
    await prefs.remove(_keyTotalAnswered);
    await prefs.remove(_keyTotalCorrect);
    await prefs.remove(_keySessions);
    await prefs.remove(_keyBestStreak);
    await prefs.remove(_keyHistory);
    await prefs.remove(_keyDaily);
    _history.clear();
    _daily.clear();
  }
}
