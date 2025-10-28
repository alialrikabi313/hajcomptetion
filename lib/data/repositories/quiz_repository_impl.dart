import '../../domain/entities/level.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/local_questions_data_source.dart';
import '../models/level_model.dart';

/// 🧩 المستودع الذي يربط الطبقة الدومينية بمصدر البيانات المحلي
class QuizRepositoryImpl implements QuizRepository {
  final LocalQuestionsDataSource local;

  QuizRepositoryImpl(this.local);

  @override
  Future<List<Level>> getLevels() async {
    // تحميل قائمة النماذج من المصدر المحلي
    final List<LevelModel> models = await local.getLevels();

    // تحويل كل LevelModel إلى كيان Level (Entity)
    final List<Level> levels = models.map((m) => m.toEntity()).toList();

    return levels;
  }
}
