import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/progress_service.dart';
import '../../core/session_store.dart';
import '../../data/datasources/local_questions_data_source.dart';
import '../../data/repositories/quiz_repository_impl.dart';
import '../../domain/entities/haj_question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../../domain/usecases/get_questions_usecase.dart';

/// 💉 مصدر البيانات المحلي (مع تخزين مؤقت داخلي)
final localDataSourceProvider = Provider<LocalQuestionsDataSource>(
  (ref) => LocalQuestionsDataSourceImpl(),
);

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepositoryImpl(ref.watch(localDataSourceProvider)),
);

final getQuestionsUseCaseProvider = Provider<GetQuestionsUseCase>(
  (ref) => GetQuestionsUseCase(ref.watch(quizRepositoryProvider)),
);

/// 📚 كل الأسئلة (تُستعمل في البحث ومراجعة الأخطاء)
final allQuestionsProvider = FutureProvider<List<HajQuestion>>(
  (ref) => ref.watch(getQuestionsUseCaseProvider).all(),
);

/// 📚 قائمة المواضيع مع عدد أسئلة كل موضوع
final topicsProvider = FutureProvider<List<QuizTopic>>(
  (ref) => ref.watch(getQuestionsUseCaseProvider).topics(),
);

/// 🔢 العدد الكلي للأسئلة في الملف
final totalQuestionsProvider = FutureProvider<int>((ref) async {
  final all = await ref.watch(allQuestionsProvider.future);
  return all.length;
});

/// 📊 أرقام بنك الأسئلة (تُعرض في صفحة «حول التطبيق»)
class BankStats {
  final int total;
  final int withReference;
  final int topics;

  const BankStats({
    required this.total,
    required this.withReference,
    required this.topics,
  });

  int get withoutReference => total - withReference;
}

final bankStatsProvider = FutureProvider<BankStats>((ref) async {
  final all = await ref.watch(allQuestionsProvider.future);
  final topics = await ref.watch(topicsProvider.future);
  return BankStats(
    total: all.length,
    withReference: all.where((q) => q.hasReference).length,
    topics: topics.length,
  );
});

/// ❌ عدد الأسئلة التي آخر إجابة عليها كانت خاطئة
final mistakesCountProvider = FutureProvider<int>((ref) async {
  await ProgressService.instance.load();
  final ids = ProgressService.instance.mistakeIds();
  if (ids.isEmpty) return 0;
  final all = await ref.watch(allQuestionsProvider.future);
  return all.where((q) => ids.contains(q.id)).length;
});

/// 💾 جلسة محفوظة يمكن استئنافها
final savedSessionProvider = FutureProvider<SavedSession?>(
  (ref) => SessionStore.instance.read(),
);

/// 👁️ عدد الأسئلة التي ظهرت للمستخدم في كل موضوع (التغطية)
final seenByTopicProvider = FutureProvider<Map<String, int>>((ref) async {
  await ProgressService.instance.load();
  final seen = ProgressService.instance.seenIds();
  if (seen.isEmpty) return const {};
  final all = await ref.watch(allQuestionsProvider.future);
  final map = <String, int>{};
  for (final q in all) {
    if (seen.contains(q.id)) {
      map[q.topic] = (map[q.topic] ?? 0) + 1;
    }
  }
  return map;
});
