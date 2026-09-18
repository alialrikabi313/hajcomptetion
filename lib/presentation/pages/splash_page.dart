import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import '../../core/app_routes.dart';
import '../../core/app_theme.dart';
import '../../core/audio_service.dart';
import '../../core/progress_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_mark.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    AudioService.instance.init();
    ProgressService.instance.load();
    Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: AppBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // صورة خفيفة جداً كخامة خلفية
            Opacity(
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.10
                  : 0.05,
              child: Image.asset(
                'assets/images/kaaba_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  ZoomIn(
                    duration: const Duration(milliseconds: 700),
                    child: const AppMark(size: 108),
                  ),
                  const SizedBox(height: 26),
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      'مسابقة الحج الكبرى',
                      style: TextStyle(
                        fontFamily: fontDisplay,
                        fontSize: w * 0.085,
                        fontWeight: FontWeight.bold,
                        color: p.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 800),
                    child: Text(
                      'استعد لامتحان إرشاد الحج بأسلوب تفاعلي',
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: p.gold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '© مكتبة القائم',
                    style: TextStyle(color: p.textMuted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
