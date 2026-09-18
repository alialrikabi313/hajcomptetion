/// 🏷️ تنظيف أسماء المواضيع القادمة من ملف الأسئلة
///
/// مثال: «جميع اسئلة الطواف» ← «الطواف»
///       «اسئلة الارشاد حول الذبح من مسالة 384 الى 395» ← «الذبح»
class TopicNames {
  TopicNames._();

  static final List<RegExp> _prefixes = [
    RegExp(r'^(جميع|كل|اخر|آخر)\s+'),
    RegExp(r'^(اسئلة|أسئلة)\s+'),
    RegExp(r'^(الارشاد|الإرشاد)\s+'),
    RegExp(r'^(حول|بخصوص|عن|في|من)\s+'),
  ];

  /// حذف تحديد أرقام المسائل من آخر الاسم
  static final RegExp _rangeSuffix = RegExp(
    r'\s*(من\s+)?(مسالة|مسألة|المسالة|المسألة|ص|صفحة)\s*[٠-٩\d].*$',
  );

  /// ترتيب عرض المواضيع في التطبيق (حسب ترتيب أعمال الحج لا حسب ترتيب الملف)
  static const List<String> order = [
    'النيابة في الحج',
    'الاستطاعة ووجوب الحج',
    'العمرة المفردة',
    'حج التمتع وأحكامه',
    'احرام الحج',
    'محرمات الإحرام',
    'المخيط',
    'الطواف',
    'صلاة الطواف',
    'السعي',
    'التقصير',
    'موقف عرفات',
    'مزدلفة',
    'رمي جمرة العقبة',
    'الذبح',
    'المبيت في منى',
    'أحكام الحائض والمستحاضة',
  ];

  /// موقع الموضوع في ترتيب العرض (وما لا يُعرف يُدفع إلى الآخر)
  static int rank(String name) {
    final i = order.indexOf(name);
    return i < 0 ? order.length : i;
  }

  static String clean(String raw) {
    var s = raw.trim();

    // إزالة المقدمات المتكررة بشكل تراكمي
    var changed = true;
    while (changed) {
      changed = false;
      for (final p in _prefixes) {
        final next = s.replaceFirst(p, '');
        if (next != s) {
          s = next.trim();
          changed = true;
        }
      }
    }

    s = s.replaceFirst(_rangeSuffix, '').trim();

    return s.isEmpty ? raw.trim() : s;
  }
}
