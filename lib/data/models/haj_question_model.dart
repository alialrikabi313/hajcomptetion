import '../../core/topic_names.dart';
import '../../domain/entities/haj_question.dart';

class HajQuestionModel {
  final String topic;
  final List<String> topics;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String answerReference;

  const HajQuestionModel({
    required this.topic,
    required this.topics,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.answerReference,
  });

  factory HajQuestionModel.fromMap(Map<String, dynamic> map) {
    final primary = (map['topic'] ?? '').toString().trim();
    final extra = ((map['topics'] as List?) ?? const [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return HajQuestionModel(
      topic: primary,
      topics: [
        if (primary.isNotEmpty) primary,
        ...extra.where((e) => e != primary),
      ],
      question: (map['question'] ?? '').toString().trim(),
      options: ((map['options'] as List?) ?? const [])
          .map((e) => e.toString().trim())
          .toList(),
      correctAnswer: (map['correct_answer'] ?? '').toString().trim(),
      answerReference: (map['answer_reference'] ?? '').toString().trim(),
    );
  }

  /// السؤال صالح للعرض فقط إذا كان له نص وخيارات وجواب موجود ضمنها
  bool get isValid =>
      question.isNotEmpty &&
      options.length >= 2 &&
      options.contains(correctAnswer);

  HajQuestion toEntity() => HajQuestion(
    // اسم الموضوع المختصر (بدون «جميع اسئلة…» وأرقام المسائل)
    topic: TopicNames.clean(topic),
    topics: topics.map(TopicNames.clean).toSet().toList(),
    question: question,
    options: options,
    correctAnswer: correctAnswer,
    answerReference: answerReference,
  );
}
