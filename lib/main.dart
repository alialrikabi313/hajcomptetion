import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/constants.dart';
import 'core/settings_service.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/homepage.dart';
import 'presentation/pages/levels_page.dart';
import 'presentation/pages/question_page.dart';
import 'presentation/pages/result_page.dart';
import 'presentation/pages/about_page.dart';
import 'presentation/pages/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 تحميل الإعدادات المحفوظة عند تشغيل التطبيق
  final settings = await SettingsService.loadSettings();
  K.passScore = settings['passScore'];
  K.showTimer = settings['showTimer'];
  K.fontsize = settings['fontSize'];

  runApp(const ProviderScope(child: QuizApp()));
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مسابقة الحج',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.levels: (_) => const LevelsPage(),
        AppRoutes.question: (_) => const QuestionPage(),
        AppRoutes.result: (_) => const ResultPage(),
        AppRoutes.about: (_) => const AboutPage(),
        AppRoutes.settings: (_) => const SettingsPage(),
      },
    );
  }
}
