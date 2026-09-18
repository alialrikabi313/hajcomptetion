import '../../core/arabic.dart';

/// ❓ سؤال واحد كما هو في ملف haj_questions.json
class HajQuestion {
  /// الموضوع الأساسي (الأول في [topics])
  final String topic;

  /// كل المواضيع التي ينتمي إليها السؤال (سؤال واحد قد يظهر في أكثر من موضوع)
  final List<String> topics;
  final String question;
  final List<String> options;

  /// نص الجواب الصحيح (يطابق أحد عناصر [options])
  final String correctAnswer;

  /// مستند/مصدر الجواب (قد يكون فارغاً في حالات نادرة)
  final String answerReference;

  const HajQuestion({
    required this.topic,
    required this.topics,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.answerReference,
  });

  bool get hasReference => answerReference.trim().isNotEmpty;

  /// معرّف ثابت مشتق من نص السؤال (يُستعمل في سجل التقدّم)
  int get id => Ar.stableId(question);

  /// موقع الجواب الصحيح ضمن قائمة الخيارات الأصلية
  int get correctIndex {
    final i = options.indexOf(correctAnswer);
    return i >= 0 ? i : 0;
  }
}

/// 📚 موضوع (مجموعة أسئلة تحمل نفس الـ topic)
class QuizTopic {
  final String name;
  final int questionCount;

  const QuizTopic({required this.name, required this.questionCount});
}
