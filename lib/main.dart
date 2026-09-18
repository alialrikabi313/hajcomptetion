import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'core/progress_service.dart';
import 'core/reminder_service.dart';
import 'core/settings_service.dart';
import 'presentation/pages/about_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/review_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/search_page.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/stats_page.dart';
import 'presentation/pages/summary_page.dart';
import 'presentation/pages/topics_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 تحميل الإعدادات المحفوظة عند تشغيل التطبيق
  await SettingsService.load();
  await ProgressService.instance.load();
  unawaited(ReminderService.instance.rescheduleIfEnabled());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const ProviderScope(child: QuizApp()));
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, _) => MaterialApp(
      title: 'مسابقة الحج',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      // 🔒 تثبيت اتجاه النص عربياً في كل التطبيق
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.topics: (_) => const TopicsPage(),
        AppRoutes.review: (_) => const ReviewPage(),
        AppRoutes.summary: (_) => const SummaryPage(),
        AppRoutes.stats: (_) => const StatsPage(),
        AppRoutes.about: (_) => const AboutPage(),
        AppRoutes.settings: (_) => const SettingsPage(),
        AppRoutes.search: (_) => const SearchPage(),
      },
      ),
    );
  }
}
