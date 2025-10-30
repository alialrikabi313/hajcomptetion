import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../providers/quiz_controller.dart';
import '../widgets/progress_timer.dart';


class QuestionPage extends ConsumerWidget {
  const QuestionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final ctrl = ref.read(quizControllerProvider.notifier);

    if (state.levels.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = state.currentQuestion; // يحتوي: question, options, correctAnswer(1..3)
    final options = q.options;
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFF0A3D2E),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: const Color(0xFF06442E),
              titleSpacing: 0,
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final timerSize = (width * 0.10).clamp(38.0, 60.0);

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            state.currentLevel.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (K.showTimer)
                        SizedBox(
                          width: timerSize,
                          height: timerSize,
                          child: ProgressTimer(
                            remaining: state.remainingSeconds,
                            total: K.secondsPerQuestion,
                          ),
                        )
                      else
                        const SizedBox(width: 0, height: 0),

                      const SizedBox(width: 10),
                    ],
                  );
                },
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StageProgress(
                  currentIndex: state.currentQuestionIndex + 1,
                  total: state.currentLevel.questions.length,
                ),
                const SizedBox(height: 18),

                // بطاقة السؤال
                SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF155A45), Color(0xFF0A3D2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 8)
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: size.height * 0.6
                      ),
                      child: Text(
                        q.question,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: K.fontsize,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // الخيارات
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final isAnswered = state.isAnswered;
                      final selected0 = ctrl.selectedOptionIndex; // 0-based
                      final correctIndex = q.correctAnswer - 1;   // لأن correctAnswer يبدأ من 1

                      Color bg = const Color(0xFF008C74); // اللون الافتراضي

                      if (isAnswered && selected0 != null) {
                        // ✅ إذا أجاب المستخدم بشكل صحيح
                        if (selected0 == correctIndex) {
                          if (i == correctIndex) {
                            bg = Colors.greenAccent.shade700; // الجواب الصحيح فقط أخضر
                          }
                        }
                        // ❌ إذا أجاب المستخدم بشكل خاطئ
                        else {
                          if (i == selected0) {
                            bg = Colors.redAccent.shade200; // الجواب الذي اختاره المستخدم أحمر
                          } else if (i == correctIndex) {
                            bg = Colors.greenAccent.shade700; // الجواب الصحيح أخضر
                          }
                        }
                      }

                      return GestureDetector(
                        onTap: isAnswered ? null : () => ctrl.answer(i + 1),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            options[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: K.fontsize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDAA520),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: !state.isAnswered
                        ? null
                        : () {
                      final hasNext = ctrl.next();
                      if (!hasNext) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.result);
                      }
                    },
                    child:
                    Text(state.isLastQuestion ? 'عرض النتيجة' : 'التالي'),
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

class _StageProgress extends StatelessWidget {
  final int currentIndex;
  final int total;
  const _StageProgress({required this.currentIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    final value = currentIndex / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.white24,
          color: Colors.amberAccent,
          minHeight: 10,
        ),
        const SizedBox(height: 8),
        const Text(
          'تقدم المرحلة',
          style: TextStyle(color: Colors.white54, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        Text(
          'السؤال $currentIndex من $total',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
