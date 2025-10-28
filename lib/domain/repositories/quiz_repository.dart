import '../entities/level.dart';

abstract class QuizRepository {
  Future<List<Level>> getLevels();
}
