import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/constants.dart';
import '../providers/quiz_controller.dart';
import '../../core/app_routes.dart';
import '../../core/audio_service.dart';

class ResultPage extends ConsumerWidget {
  const ResultPage({super.key});

  Future<bool> _canLoadAsset(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final ctrl = ref.read(quizControllerProvider.notifier);

    final total = state.currentLevel.questions.length;
    final score = state.scoreInLevel;
    final passed = score >= K.passScore;

    final successPath = 'assets/lottie/success.json';
    final failPath = 'assets/lottie/fail.json';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFF062B4E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF07395C),
            title: const Text('نتيجة المرحلة'),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: FutureBuilder<bool>(
                      future: _canLoadAsset(successPath),
                      builder: (context, snap) {
                        final ok = snap.data ?? false;
                        final path = passed && ok ? successPath : failPath;
                        return Lottie.asset(
                          path,
                          repeat: false,
                          height: 220,
                          errorBuilder: (_, __, ___) => Icon(
                            passed ? Icons.emoji_events : Icons.close_rounded,
                            size: 120,
                            color: passed ? Colors.amber : Colors.redAccent,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // العنوان
                Text(
                  passed ? 'أحسنت! لقد اجتزت المرحلة 🎉' : 'لم تنجح هذه المرة 😞',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.amber : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),

                // تفاصيل النتيجة بالألوان
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    children: [
                      const TextSpan(text: 'نتيجتك: '),
                      TextSpan(
                        text: '$score',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' من $total'),
                      const TextSpan(text: '\n(الحد الأدنى للنجاح: '),
                      TextSpan(
                        text: '${K.passScore}',
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(text: ')'),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      passed ? Colors.amber : Colors.tealAccent[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      if (passed) {
                        // ✅ نجاح — احفظ التقدم وارجع للمراحل
                        await ctrl.saveProgress(state.currentLevelIndex);
                      //  await AudioService.instance.play(K.sfxLevelUp);
                      } else {
                        // ❌ فشل — لا تحفظ التقدم، فقط صوت الفشل
                        await AudioService.instance.play(K.sfxWrong);
                      }

                      // 🔁 في الحالتين، العودة لقائمة المراحل
                      if (context.mounted) {
                        Navigator.popUntil(context, (r) => r.isFirst);
                        Navigator.pushNamed(context, AppRoutes.levels);
                      }
                    },
                    child: Text(passed ? 'العودة إلى المراحل' : 'إعادة المحاولة'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
