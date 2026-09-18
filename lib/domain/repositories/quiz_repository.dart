import '../entities/haj_question.dart';

abstract class QuizRepository {
  /// كل الأسئلة الموجودة في الملف
  Future<List<HajQuestion>> getAllQuestions();

  /// المواضيع مع عدد أسئلة كل موضوع (بحسب ترتيب ظهورها في الملف)
  Future<List<QuizTopic>> getTopics();

  /// أسئلة موضوع محدد
  Future<List<HajQuestion>> getQuestionsByTopic(String topic);
}
