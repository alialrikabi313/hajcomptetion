import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/audio_service.dart';
import '../../core/constants.dart';
import '../../data/datasources/local_questions_data_source.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/entities/level.dart';
import '../../domain/entities/question.dart';
import '../../domain/usecases/get_levels_usecase.dart';

/// ---------------------------
/// 🧠 حالة المسابقة
/// ---------------------------
class QuizState {
  final List<Level> levels;
  final int currentLevelIndex;
  final int currentQuestionIndex;
  final int scoreInLevel;
  final bool isAnswered;
  final int remainingSeconds;
  final int? selectedOptionIndex; // رقم الخيار الذي اختاره المستخدم (1، 2، 3)

  const QuizState({
    required this.levels,
    required this.currentLevelIndex,
    required this.currentQuestionIndex,
    required this.scoreInLevel,
    required this.isAnswered,
    required this.remainingSeconds,
    this.selectedOptionIndex,
  });

  Level get currentLevel => levels[currentLevelIndex];
  Question get currentQuestion => currentLevel.questions[currentQuestionIndex];
  bool get isLastQuestion =>
      currentQuestionIndex == currentLevel.questions.length - 1;

  QuizState copyWith({
    List<Level>? levels,
    int? currentLevelIndex,
    int? currentQuestionIndex,
    int? scoreInLevel,
    bool? isAnswered,
    int? remainingSeconds,
    int? selectedOptionIndex,
  }) {
    return QuizState(
      levels: levels ?? this.levels,
      currentLevelIndex: currentLevelIndex ?? this.currentLevelIndex,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      scoreInLevel: scoreInLevel ?? this.scoreInLevel,
      isAnswered: isAnswered ?? this.isAnswered,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      selectedOptionIndex: selectedOptionIndex,
    );
  }

  static QuizState initial() => const QuizState(
    levels: [],
    currentLevelIndex: 0,
    currentQuestionIndex: 0,
    scoreInLevel: 0,
    isAnswered: false,
    remainingSeconds: K.secondsPerQuestion,
    selectedOptionIndex: null,
  );
}

/// ---------------------------
/// 💉 المزودات
/// ---------------------------
final _dataSourceProvider = Provider<LocalQuestionsDataSource>(
      (ref) => LocalQuestionsDataSourceImpl(),
);

final _repoProvider = Provider<QuizRepositoryImpl>(
      (ref) => QuizRepositoryImpl(ref.read(_dataSourceProvider)),
);

final _usecaseProvider = Provider<GetLevelsUseCase>(
      (ref) => GetLevelsUseCase(ref.read(_repoProvider)),
);

/// ---------------------------
/// 🕹️ المتحكم الرئيسي بالمنطق
/// ---------------------------
class QuizController extends StateNotifier<QuizState> {
  QuizController(this._getLevels) : super(QuizState.initial());

  final GetLevelsUseCase _getLevels;
  Timer? _timer;
  final audio = AudioService.instance;

  /// تحميل المراحل من JSON
  Future<void> loadLevels() async {
    final levels = await _getLevels();
    state = state.copyWith(levels: levels);
  }

  /// بدء مرحلة جديدة
  void selectLevel(int index) {
    if (index < 0 || index >= state.levels.length) return;

    state = state.copyWith(
      currentLevelIndex: index,
      currentQuestionIndex: 0,
      scoreInLevel: 0,
      isAnswered: false,
      remainingSeconds: K.secondsPerQuestion,
      selectedOptionIndex: null,
    );

    _startTimer();
  }

  /// ---------------------------
  /// ⏱️ المؤقت الزمني
  /// ---------------------------
  void _startTimer() {
    _timer?.cancel();
    state = state.copyWith(remainingSeconds: K.secondsPerQuestion);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        _timer?.cancel();
        _handleAnswer(correct: false, auto: true);
      } else {
        state = state.copyWith(remainingSeconds: next);
      }
    });
  }

  /// ---------------------------
  /// ✅ معالجة الإجابة
  /// ---------------------------
  void answer(int selectedIndex) {
    if (state.isAnswered) return;

    final correctIndex = state.currentQuestion.correctAnswer;
    final isCorrect = selectedIndex == correctIndex;

    _handleAnswer(correct: isCorrect, selected: selectedIndex);
  }

  void _handleAnswer({required bool correct, bool auto = false, int? selected}) {
    _timer?.cancel();

    if (correct) {
      audio.play(K.sfxCorrect);
      state = state.copyWith(
        isAnswered: true,
        scoreInLevel: state.scoreInLevel + 1,
        selectedOptionIndex: selected != null ? selected - 1 : null,
      );
    } else {
      if (!auto) audio.play(K.sfxWrong);
      state = state.copyWith(
        isAnswered: true,
        selectedOptionIndex: selected != null ? selected - 1 : null,
      );
    }
  }

  /// ---------------------------
  /// ⏭️ الانتقال للسؤال التالي
  /// ---------------------------
  bool next() {
    if (!state.isLastQuestion) {
      final nextIndex = state.currentQuestionIndex + 1;
      state = state.copyWith(
        currentQuestionIndex: nextIndex,
        isAnswered: false,
        remainingSeconds: K.secondsPerQuestion,
        selectedOptionIndex: null,
      );
      _startTimer();
      return true;
    } else {
      return false;
    }
  }

  void disposeTimers() {
    _timer?.cancel();
  }

  /// ---------------------------
  /// 💾 حفظ التقدّم
  /// ---------------------------
  Future<void> saveProgress(int completedLevelIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUnlocked = prefs.getInt('maxLevelUnlocked') ?? 0;

    if (completedLevelIndex >= currentUnlocked) {
      await prefs.setInt('maxLevelUnlocked', completedLevelIndex + 1);
    }
  }

  /// ---------------------------
  /// 📤 تحميل التقدّم
  /// ---------------------------
  Future<int> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('maxLevelUnlocked') ?? 0;
  }

  /// ---------------------------
  /// 🧹 إعادة التهيئة الكاملة
  /// ---------------------------
  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('maxLevelUnlocked');
  }

  /// ---------------------------
  /// 🟡 Getter مخصص للوصول إلى الخيار الذي اختاره المستخدم
  /// ---------------------------
  int? get selectedOptionIndex => state.selectedOptionIndex;
}

/// ---------------------------
/// 🔗 مزود Riverpod
/// ---------------------------
final quizControllerProvider =
StateNotifierProvider<QuizController, QuizState>((ref) {
  final usecase = ref.read(_usecaseProvider);
  final ctrl = QuizController(usecase);
  unawaited(ctrl.loadLevels());
  return ctrl;
});
