class Question {
  final String question;
  final List<String> options;     // [أ، ب، ج]
  final int correctAnswer;        // 1..3 (ترقيم طبيعي)

  const Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  bool isCorrect(int selectedIndex1Based) => selectedIndex1Based == correctAnswer;
}
