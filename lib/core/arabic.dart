/// 🔤 أدوات نصية عربية: تطبيع للبحث، ومعرّف ثابت لكل سؤال
class Ar {
  Ar._();

  static final _diacritics = RegExp(r'[ً-ْٰـ]');

  /// تطبيع النص ليسهل البحث: حذف التشكيل وتوحيد الهمزات والألف المقصورة والتاء المربوطة
  static String normalize(String input) {
    var s = input.replaceAll(_diacritics, '');
    s = s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ء', '');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }

  static const _indic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// تحويل الأرقام إلى أرقام عربية (٠١٢٣) لتتناسق مع نصوص الأسئلة
  static String n(Object value) {
    final s = value.toString();
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final code = ch.codeUnitAt(0);
      if (code >= 48 && code <= 57) {
        b.write(_indic[code - 48]);
      } else {
        b.write(ch);
      }
    }
    return b.toString();
  }

  /// معرّف ثابت (FNV-1a 32bit) لا يتغيّر بين التشغيلات ولا بين الأجهزة
  static int stableId(String text) {
    const int prime = 0x01000193;
    int hash = 0x811C9DC5;
    for (final unit in text.codeUnits) {
      hash = (hash ^ unit) & 0xFFFFFFFF;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    return hash;
  }
}
