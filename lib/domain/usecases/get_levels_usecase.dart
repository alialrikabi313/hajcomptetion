import '../entities/level.dart';
import '../repositories/quiz_repository.dart';

class GetLevelsUseCase {
  final QuizRepository repo;
  GetLevelsUseCase(this.repo);

  Future<List<Level>> call() => repo.getLevels();
}
