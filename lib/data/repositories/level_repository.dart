import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/question_model.dart';

class Level {
  final int id;
  final String name;
  final List<QuestionModel> questions;

  Level({required this.id, required this.name, required this.questions});

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'],
      name: json['name'],
      questions: (json['questions'] as List)
          .map((q) => QuestionModel.fromMap(q))
          .toList(),
    );
  }
}

class LevelRepository {
  Future<List<Level>> loadLevels() async {
    final jsonString = await rootBundle.loadString('assets/levels/levels.json');
    final data = json.decode(jsonString);
    final levels = (data['levels'] as List)
        .map((level) => Level.fromJson(level))
        .toList();
    return levels;
  }
}
