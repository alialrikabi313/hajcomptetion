import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../models/level_model.dart';

/// 🧠 واجهة مصدر الأسئلة المحلي (تقرأ ملف JSON من assets)
abstract class LocalQuestionsDataSource {
  /// تحميل جميع المراحل من ملف JSON
  Future<List<LevelModel>> getLevels();
}

/// 💾 التطبيق الفعلي لقراءة الملف من الأصول
class LocalQuestionsDataSourceImpl implements LocalQuestionsDataSource {
  @override
  Future<List<LevelModel>> getLevels() async {
    // تحميل النص من ملف JSON المحدد في constants
    final raw = await rootBundle.loadString(K.levelsAsset);

    // فكّ الترميز وتحويله إلى خريطة
    final map = json.decode(raw) as Map<String, dynamic>;

    // تحويل كل عنصر في القائمة إلى LevelModel
    final levels = (map['levels'] as List)
        .map((e) => LevelModel.fromMap(e as Map<String, dynamic>))
        .toList();

    return levels;
  }
}
