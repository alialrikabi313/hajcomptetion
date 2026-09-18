import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio_service.dart';
import '../../core/constants.dart';
import '../../core/progress_service.dart';
import '../../core/session_store.dart';
import '../../domain/entities/haj_question.dart';
import '../../domain/usecases/get_questions_usecase.dart';
import 'quiz_providers.dart';

/// نوع المراجعة
enum ReviewMode { topic, random, mistakes }

extension ReviewModeX on ReviewMode {
  String get key => switch (this) {
    ReviewMode.topic => 'topic',
    ReviewMode.random => 'random',
    ReviewMode.mistakes => 'mistakes',
  };

  static ReviewMode fromKey(String k) => switch (k) {
    'topic' => ReviewMode.topic,
    'mistakes' => ReviewMode.mistakes,
    _ => ReviewMode.random,
  };
}

/// 🧾 السؤال كما يُعرض على الشاشة
class ReviewQuestion {
  final HajQuestion source;
  final List<String> options;
  final int correctIndex;

  const ReviewQuestion({
    required this.source,
    required this.options,
    required this.correctIndex,
  });

  String get text => source.question;
  String get topic => source.topic;
  String get reference => source.answerReference;
  bool get hasReference => source.hasReference;
}

/// خطأ مسجّل في هذه الجلسة، لعرضه في الملخص
class SessionMistake {
  final HajQuestion question;
  final String? chosen;

  const SessionMistake({required this.question, this.chosen});
}

/// 🧠 حالة جلسة المراجعة
class ReviewState {
  final bool loading;
  final ReviewMode mode;
  final String title;

  final ReviewQuestion? current;
  final int? selectedIndex;
  final bool isAnswered;
  final bool timedOut;
  final bool referenceShown;

  final int shown;
  final int correct;
  final int wrong;
  final int streak;
  final int bestStreak;

  final int poolSize;
  final int positionInRound;

  final int remainingSeconds;
  final bool finished;

  /// انتهت الجلسة لأن أسئلة الموضوع (أو البنك) نفدت، لا بإنهاء المستخدم
  final bool completedAll;

  /// أخطاء هذه الجلسة (بترتيب حدوثها)
  final List<SessionMistake> mistakes;

  const ReviewState({
    this.loading = true,
    this.mode = ReviewMode.random,
    this.title = '',
    this.current,
    this.selectedIndex,
    this.isAnswered = false,
    this.timedOut = false,
    this.referenceShown = false,
    this.shown = 0,
    this.correct = 0,
    this.wrong = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.poolSize = 0,
    this.positionInRound = 0,
    this.remainingSeconds = 0,
    this.finished = false,
    this.completedAll = false,
    this.mistakes = const [],
  });

  int get answeredTotal => correct + wrong;

  double get accuracy => answeredTotal == 0 ? 0 : correct / answeredTotal;

  int get accuracyPercent => (accuracy * 100).round();

  ReviewState copyWith({
    bool? loading,
    ReviewMode? mode,
    String? title,
    ReviewQuestion? current,
    int? selectedIndex,
    bool clearSelection = false,
    bool? isAnswered,
    bool? timedOut,
    bool? referenceShown,
    int? shown,
    int? correct,
    int? wrong,
    int? streak,
    int? bestStreak,
    int? poolSize,
    int? positionInRound,
    int? remainingSeconds,
    bool? finished,
    bool? completedAll,
    List<SessionMistake>? mistakes,
  }) {
    return ReviewState(
      loading: loading ?? this.loading,
      mode: mode ?? this.mode,
      title: title ?? this.title,
      current: current ?? this.current,
      selectedIndex: clearSelection
          ? null
          : (selectedIndex ?? this.selectedIndex),
      isAnswered: isAnswered ?? this.isAnswered,
      timedOut: timedOut ?? this.timedOut,
      referenceShown: referenceShown ?? this.referenceShown,
      shown: shown ?? this.shown,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      poolSize: poolSize ?? this.poolSize,
      positionInRound: positionInRound ?? this.positionInRound,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      finished: finished ?? this.finished,
      completedAll: completedAll ?? this.completedAll,
      mistakes: mistakes ?? this.mistakes,
    );
  }
}

/// 🕹️ متحكم جلسة المراجعة — تنتهي الجلسة بنفاد أسئلة الموضوع أو بإنهاء المستخدم
class ReviewController extends StateNotifier<ReviewState> {
  ReviewController(this._useCase) : super(const ReviewState(loading: false));

  final GetQuestionsUseCase _useCase;
  final _random = Random();
  final _audio = AudioService.instance;
  final _progress = ProgressService.instance;

  List<HajQuestion> _pool = const [];
  int _cursor = 0;
  Timer? _timer;

  /// بدء جلسة جديدة
  Future<void> start({required ReviewMode mode, String? topic}) async {
    _timer?.cancel();
    state = ReviewState(loading: true, mode: mode);

    await _progress.load();
    final List<HajQuestion> questions;
    switch (mode) {
      case ReviewMode.topic:
        questions = topic == null ? const [] : await _useCase.byTopic(topic);
      case ReviewMode.random:
        questions = await _useCase.all();
      case ReviewMode.mistakes:
        final ids = _progress.mistakeIds();
        final all = await _useCase.all();
        questions = all.where((q) => ids.contains(q.id)).toList();
    }

    _pool = List<HajQuestion>.from(questions)..shuffle(_random);
    _cursor = 0;

    state = ReviewState(
      loading: false,
      mode: mode,
      title: switch (mode) {
        ReviewMode.topic => topic ?? '',
        ReviewMode.random => 'مراجعة عشوائية',
        ReviewMode.mistakes => 'مراجعة الأخطاء',
      },
      poolSize: _pool.length,
      remainingSeconds: K.secondsPerQuestion,
    );

    if (_pool.isEmpty) return;
    _loadCurrent(firstOfSession: true);
  }

  /// استئناف جلسة محفوظة
  Future<bool> resume(SavedSession saved) async {
    _timer?.cancel();
    state = const ReviewState(loading: true);
    await _progress.load();

    final all = await _useCase.all();
    final byId = {for (final q in all) q.id: q};
    final pool = saved.remaining
        .map((id) => byId[id])
        .whereType<HajQuestion>()
        .toList();

    if (pool.isEmpty) {
      await SessionStore.instance.clear();
      state = const ReviewState(loading: false);
      return false;
    }

    _pool = pool;
    _cursor = 0;
    state = ReviewState(
      loading: false,
      mode: ReviewModeX.fromKey(saved.mode),
      title: saved.title,
      poolSize: saved.poolSize == 0 ? pool.length : saved.poolSize,
      shown: saved.shown,
      correct: saved.correct,
      wrong: saved.wrong,
      bestStreak: saved.bestStreak,
      remainingSeconds: K.secondsPerQuestion,
    );
    _loadCurrent();
    return true;
  }

  void _loadCurrent({bool firstOfSession = false}) {
    if (_cursor >= _pool.length) {
      unawaited(finish(completedAll: true));
      return;
    }

    final source = _pool[_cursor];

    // ترتيب الخيارات يبقى كما هو في الملف — المتغيّر هو ترتيب الأسئلة
    state = state.copyWith(
      current: ReviewQuestion(
        source: source,
        options: source.options,
        correctIndex: source.correctIndex,
      ),
      clearSelection: true,
      isAnswered: false,
      timedOut: false,
      referenceShown: false,
      positionInRound: _cursor + 1,
      remainingSeconds: K.secondsPerQuestion,
    );

    _startTimer();
    unawaited(_saveSession());
  }

  void _startTimer() {
    _timer?.cancel();
    if (!K.showTimer) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        _timer?.cancel();
        _register(correct: false, selected: null, timedOut: true);
      } else {
        state = state.copyWith(remainingSeconds: next);
      }
    });
  }

  /// إجابة المستخدم (فهرس الخيار 0-based)
  void answer(int index) {
    if (state.isAnswered || state.current == null) return;
    final isCorrect = index == state.current!.correctIndex;
    _register(correct: isCorrect, selected: index, timedOut: false);
  }

  void _register({
    required bool correct,
    required int? selected,
    required bool timedOut,
  }) {
    _timer?.cancel();
    final q = state.current;
    if (q == null) return;

    final streak = correct ? state.streak + 1 : 0;
    final mistakes = correct
        ? state.mistakes
        : [
            ...state.mistakes,
            SessionMistake(
              question: q.source,
              chosen: selected == null ? null : q.options[selected],
            ),
          ];

    state = state.copyWith(
      isAnswered: true,
      timedOut: timedOut,
      selectedIndex: selected,
      clearSelection: selected == null,
      shown: state.shown + 1,
      correct: correct ? state.correct + 1 : state.correct,
      wrong: correct ? state.wrong : state.wrong + 1,
      streak: streak,
      bestStreak: streak > state.bestStreak ? streak : state.bestStreak,
      mistakes: mistakes,
    );

    _audio.play(correct ? K.sfxCorrect : K.sfxWrong);

    // نتائج المراجعة العشوائية لا تُحتسب على إحصائيات المواضيع
    unawaited(
      _progress.recordAnswer(
        id: q.source.id,
        // في مراجعة الموضوع تُحتسب على الموضوع الجاري لا على الموضوع الأساسي
        topic: state.mode == ReviewMode.topic ? state.title : q.topic,
        correct: correct,
        trackTopic: state.mode == ReviewMode.topic,
      ),
    );
    unawaited(_saveSession());
  }

  /// إظهار مستند الجواب (زر المصباح)
  void revealReference() {
    if (!state.isAnswered) return;
    state = state.copyWith(referenceShown: true);
  }

  /// الانتقال للسؤال التالي
  void next() {
    if (_pool.isEmpty) return;
    _cursor += 1;
    _loadCurrent();
  }

  Future<void> _saveSession() async {
    if (_pool.isEmpty || state.finished) return;
    final remaining = _pool.sublist(_cursor.clamp(0, _pool.length));
    await SessionStore.instance.save(
      SavedSession(
        mode: state.mode.key,
        title: state.title,
        shown: state.shown,
        correct: state.correct,
        wrong: state.wrong,
        bestStreak: state.bestStreak,
        poolSize: state.poolSize,
        remaining: remaining.map((q) => q.id).toList(),
      ),
    );
    // انتهت الجلسة أثناء الحفظ ⇒ لا نُبقي جلسة محفوظة
    if (mounted && state.finished) await SessionStore.instance.clear();
  }

  /// إنهاء الجلسة (يدوياً، أو تلقائياً عند نفاد الأسئلة)
  Future<void> finish({bool completedAll = false}) async {
    _timer?.cancel();
    if (state.finished) return;
    state = state.copyWith(finished: true, completedAll: completedAll);
    await SessionStore.instance.clear();
    await _progress.recordSession(bestStreak: state.bestStreak);
  }

  /// إعادة تشغيل نفس نوع الجلسة من الصفر
  Future<void> restart() async {
    await start(
      mode: state.mode,
      topic: state.mode == ReviewMode.topic ? state.title : null,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final reviewControllerProvider =
    StateNotifierProvider<ReviewController, ReviewState>(
      (ref) => ReviewController(ref.watch(getQuestionsUseCaseProvider)),
    );
