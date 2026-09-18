class K {
  // 📁 ملفات الأسئلة: الأول بمستندات، والثاني أسئلة المراحل القديمة بلا مستند
  static const String questionsAsset = 'assets/haj_questions.json';
  static const String levelsQuestionsAsset = 'assets/levels_questions.json';
  static const List<String> questionAssets = [
    questionsAsset,
    levelsQuestionsAsset,
  ];

  // 🔊 أسماء ملفات المؤثرات
  static const String sfxCorrect = 'assets/sfx/correct.mp3';
  static const String sfxWrong = 'assets/sfx/wrong.mp3';
  static const String sfxLevelUp = 'assets/sfx/level_up.mp3';

  // ⚙️ الإعدادات القابلة للتعديل من صفحة الإعدادات
  static bool showTimer = false;
  static int secondsPerQuestion = 45;
  static double fontSize = 19;
  static bool soundEnabled = true;

  // حدود شريط تمرير حجم الخط
  static const double minFontSize = 15;
  static const double maxFontSize = 28;

  // حدود مدة السؤال
  static const int minSeconds = 15;
  static const int maxSeconds = 120;
}
