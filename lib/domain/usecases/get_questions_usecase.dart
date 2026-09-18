import 'dart:math';

import '../entities/haj_question.dart';
import '../repositories/quiz_repository.dart';

/// 📥 حالات الاستخدام الخاصة بجلب الأسئلة
class GetQuestionsUseCase {
  final QuizRepository repo;
  GetQuestionsUseCase(this.repo);

  Future<List<QuizTopic>> topics() => repo.getTopics();

  Future<List<HajQuestion>> byTopic(String topic) =>
      repo.getQuestionsByTopic(topic);

  Future<List<HajQuestion>> all() => repo.getAllQuestions();

  /// كل الأسئلة بترتيب عشوائي (للمراجعة العشوائية)
  Future<List<HajQuestion>> shuffledAll([Random? random]) async {
    final list = List<HajQuestion>.from(await repo.getAllQuestions());
    list.shuffle(random ?? Random());
    return list;
  }
}
