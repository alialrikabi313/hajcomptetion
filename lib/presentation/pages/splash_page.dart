import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/app_routes.dart';
import '../../core/audio_service.dart';

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
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A3D2E),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/kaaba_bg.jpg', // غيّر الامتداد حسب الصورة لديك
                fit: BoxFit.cover,
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.5),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie.asset(
                //   'assets/lottie/intro_kaaba.json', // أنيميشن مقدمة جميل
                //   height: h * 0.25,
                // ),
                const SizedBox(height: 20),
                Text(
                  'مسابقة الحج الكبرى 🕋',
                  style: TextStyle(
                    fontSize: w * 0.07,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(2, 3))
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'اختبر وراجع لإمتحان مناسك الحج',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: w * 0.045,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
