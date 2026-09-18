import '../../core/topic_names.dart';
import '../../domain/entities/haj_question.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/local_questions_data_source.dart';

/// 🧩 يربط الطبقة الدومينية بمصدر البيانات المحلي (ملف JSON)
class QuizRepositoryImpl implements QuizRepository {
  final LocalQuestionsDataSource local;

  QuizRepositoryImpl(this.local);

  @override
  Future<List<HajQuestion>> getAllQuestions() async {
    final models = await local.getQuestions();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<QuizTopic>> getTopics() async {
    final questions = await getAllQuestions();

    final counts = <String, int>{};
    for (final q in questions) {
      for (final t in q.topics) {
        if (t.isEmpty) continue;
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }

    // العرض يتبع ترتيب أعمال الحج لا ترتيب ظهور المواضيع في الملف
    final topics = counts.entries
        .map((e) => QuizTopic(name: e.key, questionCount: e.value))
        .toList()
      ..sort((a, b) {
        final r = TopicNames.rank(a.name).compareTo(TopicNames.rank(b.name));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
    return topics;
  }

  @override
  Future<List<HajQuestion>> getQuestionsByTopic(String topic) async {
    final questions = await getAllQuestions();
    return questions.where((q) => q.topics.contains(topic)).toList();
  }
}
