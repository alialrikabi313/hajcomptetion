import '../../domain/entities/question.dart';

class QuestionModel {
  final String question;
  final List<String> options; // 3 عناصر
  final int correctAnswer;    // 1..3

  const QuestionModel({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      question: (map['question'] ?? '').toString(),
      options: (map['options'] as List).map((e) => e.toString()).toList(),
      correctAnswer: (map['correctAnswer'] as num).toInt(),
    );
    // ملاحظة: لا نقوم بأي shuffle هنا — ترتيب الخيارات كما في الملف.
  }

  Map<String, dynamic> toMap() => {
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
  };

  Question toEntity() => Question(
    question: question,
    options: options,
    correctAnswer: correctAnswer,
  );
}
