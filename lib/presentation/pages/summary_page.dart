import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../core/app_routes.dart';
import '../../core/app_theme.dart';
import '../../core/arabic.dart';
import '../providers/review_controller.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/reference_sheet.dart';
import '../widgets/stat_chip.dart';

/// 🏁 ملخص جلسة المراجعة، مع قائمة الأخطاء لمراجعتها
class SummaryPage extends ConsumerWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(reviewControllerProvider);
    final good = s.accuracy >= 0.7;
    final mid = s.accuracy >= 0.4 && !good;

    final Color tone = s.answeredTotal == 0
        ? p.info
        : good
        ? p.correct
        : mid
        ? p.gold
        : p.wrong;

    final String headline = s.answeredTotal == 0
        ? 'لم تجب على أي سؤال'
        : good
        ? 'ممتاز! مستواك جيد جداً'
        : mid
        ? 'جيد، وتحتاج مزيداً من المراجعة'
        : 'راجع هذا الموضوع مرة أخرى';

    final String? completedNote = s.completedAll
        ? (s.mode == ReviewMode.topic
              ? 'أكملت جميع أسئلة «${s.title}» (${Ar.n(s.poolSize)} سؤالاً).'
              : s.mode == ReviewMode.mistakes
              ? 'أكملت مراجعة جميع أخطائك المسجّلة.'
              : 'أكملت جميع أسئلة البنك (${Ar.n(s.poolSize)} سؤالاً).')
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('ملخص المراجعة'),
        ),
        body: AppBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                kToolbarHeight + 8,
                20,
                26,
              ),
              children: [
                if (s.answeredTotal > 0)
                  SizedBox(
                    height: 140,
                    child: Lottie.asset(
                      good
                          ? 'assets/lottie/success.json'
                          : 'assets/lottie/fail.json',
                      repeat: false,
                      errorBuilder: (_, __, ___) => Icon(
                        good
                            ? Icons.emoji_events_rounded
                            : Icons.menu_book_rounded,
                        size: 90,
                        color: tone,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontDisplay,
                    color: tone,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  switch (s.mode) {
                    ReviewMode.topic => 'موضوع: ${s.title}',
                    ReviewMode.random => 'مراجعة عشوائية من جميع المواضيع',
                    ReviewMode.mistakes => 'مراجعة الأخطاء السابقة',
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                if (completedNote != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: p.correct.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: p.correct.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag_circle_rounded,
                          color: p.correct,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            completedNote,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 14.5,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 18,
                  ),
                  child: Column(
                    children: [
                      PercentRing(
                        value: s.accuracy,
                        size: 138,
                        color: tone,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${Ar.n(s.accuracyPercent)}٪',
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'نسبة الدقة',
                              style: TextStyle(
                                color: p.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          _Cell(
                            value: Ar.n(s.shown),
                            label: 'ظهر لك',
                            icon: Icons.visibility_rounded,
                            color: p.info,
                          ),
                          _Cell(
                            value: Ar.n(s.correct),
                            label: 'صحيحة',
                            icon: Icons.check_circle_rounded,
                            color: p.correct,
                          ),
                          _Cell(
                            value: Ar.n(s.wrong),
                            label: 'خاطئة',
                            icon: Icons.cancel_rounded,
                            color: p.wrong,
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_fire_department_rounded,
                            color: p.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'أفضل سلسلة إجابات صحيحة: ${Ar.n(s.bestStreak)}',
                            style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (s.mistakes.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: p.wrong, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        'أخطاء هذه الجلسة (${Ar.n(s.mistakes.length)})',
                        style: TextStyle(
                          fontFamily: fontDisplay,
                          color: p.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'محفوظة في «مراجعة الأخطاء» حتى تجيب عليها صحيحاً.',
                    style: TextStyle(color: p.textMuted, fontSize: 12.5),
                  ),
                  const SizedBox(height: 12),
                  ...s.mistakes.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () => showReferenceSheet(
                          context,
                          correctAnswer: m.question.correctAnswer,
                          reference: m.question.answerReference,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.question.question,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 14.5,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 15,
                                  color: p.correct,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    m.question.correctAnswer,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: p.correct,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 14,
                                  color: p.gold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'اضغط لعرض المستند',
                                  style: TextStyle(
                                    color: p.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(reviewControllerProvider.notifier).restart();
                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.review,
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('إعادة المراجعة'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.popUntil(
                          context,
                          (r) =>
                              r.settings.name == AppRoutes.home || r.isFirst,
                        ),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('العودة إلى القائمة الرئيسية'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _Cell({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
