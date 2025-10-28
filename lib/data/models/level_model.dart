import '../../domain/entities/level.dart';
import '../../domain/entities/question.dart';
import 'question_model.dart';

class LevelModel {
  final int id;
  final String name;
  final List<QuestionModel> questions;

  const LevelModel({
    required this.id,
    required this.name,
    required this.questions,
  });

  factory LevelModel.fromMap(Map<String, dynamic> map) {
    final qs = (map['questions'] as List)
        .map((e) => QuestionModel.fromMap(e as Map<String, dynamic>))
        .toList();

    return LevelModel(
      id: (map['id'] as num).toInt(),
      name: (map['name'] ?? '').toString(),
      questions: qs,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'questions': questions.map((e) => e.toMap()).toList(),
  };

  Level toEntity() => Level(
    id: id,
    name: name,
    questions: questions.map<Question>((qm) => qm.toEntity()).toList(),
  );
}
