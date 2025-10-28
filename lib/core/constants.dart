class K {
  // الوقت المخصص لكل سؤال (ثوانٍ)
  static const int secondsPerQuestion = 30;

  static const double passThreshold = 0.7;

  // أسماء ملفات المؤثرات
  static const String sfxCorrect = 'assets/sfx/correct.mp3';
  static const String sfxWrong   = 'assets/sfx/wrong.mp3';
  static const String sfxLevelUp = 'assets/sfx/level_up.mp3';

  // المتغيرات العامة القابلة للتعديل
  static int passScore = 15;   // سهل افتراضياً
  static bool showTimer = true;
  static double fontsize = 20;

  // مسار ملف الأسئلة
  static const String levelsAsset = 'assets/levels/levels.json';
}
