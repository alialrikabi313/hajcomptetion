import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/constants.dart';
import '../models/haj_question_model.dart';

/// 🧠 واجهة مصدر الأسئلة المحلي
abstract class LocalQuestionsDataSource {
  Future<List<HajQuestionModel>> getQuestions();
}

/// 💾 قراءة ملفات الأسئلة من الأصول (مرة واحدة ثم تُخزّن مؤقتاً)
///
/// الملف الأول: أسئلة مع مستند الجواب.
/// الملف الثاني: أسئلة المراحل القديمة، بلا مستند.
class LocalQuestionsDataSourceImpl implements LocalQuestionsDataSource {
  List<HajQuestionModel>? _cache;

  @override
  Future<List<HajQuestionModel>> getQuestions() async {
    if (_cache != null) return _cache!;

    final all = <HajQuestionModel>[];
    for (final asset in K.questionAssets) {
      all.addAll(await _load(asset));
    }
    _cache = all;
    return _cache!;
  }

  Future<List<HajQuestionModel>> _load(String asset) async {
    try {
      final raw = await rootBundle.loadString(asset);
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => HajQuestionModel.fromMap(e as Map<String, dynamic>))
          .where((m) => m.isValid)
          .toList();
    } catch (_) {
      // ملف مفقود أو تالف: لا نُسقط بقية البنك
      return const [];
    }
  }
}
