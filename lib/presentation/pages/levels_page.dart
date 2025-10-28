import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/app_routes.dart';
import '../providers/quiz_controller.dart';

class LevelsPage extends ConsumerWidget {
  const LevelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizControllerProvider);
    final ctrl = ref.read(quizControllerProvider.notifier);
    final levels = state.levels;
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A3D2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF06442E),
          title: const Text(
            'المراحل',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          centerTitle: true,
          elevation: 4,
        ),
        body: levels.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : FutureBuilder<int>(
          future: ctrl.loadProgress(),
          builder: (context, snap) {
            final unlockedUntil = snap.data ?? 0;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: levels.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size.width < 400 ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, i) {
                  final unlocked = i <= unlockedUntil;
                  return FadeInUp(
                    // delay: Duration(milliseconds: 100 * i),
                    duration: const Duration(milliseconds: 1000),
                    child: GestureDetector(
                      onTap: unlocked
                          ? () {
                        ctrl.selectLevel(i);
                        Navigator.pushNamed(
                            context, AppRoutes.question);
                      }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: unlocked
                              ? const LinearGradient(
                            colors: [
                              Color(0xFFDAA520),
                              Color(0xFFF4E07D)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : const LinearGradient(
                            colors: [
                              Color(0xFF364B42),
                              Color(0xFF1F2B26)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: unlocked
                                  ? Colors.amber.withOpacity(0.5)
                                  : Colors.black45,
                              blurRadius: 8,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 10,
                              right: 12,
                              child: Icon(
                                unlocked
                                    ? Icons.lock_open_rounded
                                    : Icons.lock_rounded,
                                color: unlocked
                                    ? Colors.white
                                    : Colors.white54,
                                size: 22,
                              ),
                            ),
                            Center(
                              child: Text(
                                levels[i].name,
                                style: TextStyle(
                                  color: unlocked
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: size.width * 0.045,
                                  shadows: unlocked
                                      ? [
                                    const Shadow(
                                        color: Colors.white,
                                        blurRadius: 4)
                                  ]
                                      : [],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
