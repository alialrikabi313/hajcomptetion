import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_routes.dart';
import '../../core/app_theme.dart';
import '../../core/arabic.dart';
import '../../core/progress_service.dart';
import '../../domain/entities/haj_question.dart';
import '../providers/quiz_providers.dart';
import '../providers/review_controller.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_chip.dart';

/// 📈 إحصائياتي التراكمية
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  late Future<_StatsBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StatsBundle> _load() async {
    final progress = ProgressService.instance;
    await progress.load();
    final topics = await ref.read(getQuestionsUseCaseProvider).topics();
    final all = await ref.read(allQuestionsProvider.future);
    final seenIds = progress.seenIds();
    final mistakeIds = progress.mistakeIds();

    final seenByTopic = <String, int>{};
    for (final q in all) {
      if (seenIds.contains(q.id)) {
        seenByTopic[q.topic] = (seenByTopic[q.topic] ?? 0) + 1;
      }
    }

    return _StatsBundle(
      topics: topics,
      overall: await progress.overall(),
      perTopic: await progress.forTopics(topics.map((e) => e.name).toList()),
      sessions: await progress.sessions(),
      bestStreak: await progress.bestStreak(),
      seenByTopic: seenByTopic,
      seenTotal: all.where((q) => seenIds.contains(q.id)).length,
      bankTotal: all.length,
      mistakes: all.where((q) => mistakeIds.contains(q.id)).length,
      activity: progress.recentActivity(7),
      dayStreak: progress.dayStreak(),
    );
  }

  Future<void> _reset(List<QuizTopic> topics) async {
    final p = context.p;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: Icon(Icons.delete_forever_rounded, color: p.wrong, size: 32),
          title: const Text('تصفير الإحصائيات'),
          content: const Text(
            'سيتم حذف كل الإحصائيات وسجل الأسئلة (بما فيه قائمة الأخطاء). هل أنت متأكد؟',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: p.wrong,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    await ProgressService.instance.resetAll(
      topics.map((e) => e.name).toList(),
    );
    if (!mounted) return;
    ref.invalidate(mistakesCountProvider);
    ref.invalidate(seenByTopicProvider);
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('إحصائياتي')),
        body: AppBackground(
          child: SafeArea(
            child: FutureBuilder<_StatsBundle>(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: p.gold),
                  );
                }
                final b = snap.data!;
                final o = b.overall;
                final tone = o.accuracy >= 0.7
                    ? p.correct
                    : o.accuracy >= 0.4
                    ? p.gold
                    : p.wrong;

                final active = b.topics
                    .where(
                      (t) =>
                          (b.perTopic[t.name]?.answered ?? 0) > 0 ||
                          (b.seenByTopic[t.name] ?? 0) > 0,
                    )
                    .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    kToolbarHeight + 6,
                    18,
                    26,
                  ),
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          PercentRing(
                            value: o.accuracy,
                            size: 132,
                            color: tone,
                            center: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${Ar.n(o.accuracyPercent)}٪',
                                  style: TextStyle(
                                    color: p.textPrimary,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'الدقة الكلية',
                                  style: TextStyle(
                                    color: p.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              StatChip(
                                icon: Icons.visibility_rounded,
                                value: Ar.n(o.answered),
                                label: 'إجابة',
                                color: p.info,
                              ),
                              StatChip(
                                icon: Icons.check_circle_rounded,
                                value: Ar.n(o.correct),
                                label: 'صحيحة',
                                color: p.correct,
                              ),
                              StatChip(
                                icon: Icons.cancel_rounded,
                                value: Ar.n(o.wrong),
                                label: 'خاطئة',
                                color: p.wrong,
                              ),
                              StatChip(
                                icon: Icons.play_circle_rounded,
                                value: Ar.n(b.sessions),
                                label: 'جلسة',
                                color: p.gold,
                              ),
                              StatChip(
                                icon: Icons.local_fire_department_rounded,
                                value: Ar.n(b.bestStreak),
                                label: 'أفضل سلسلة',
                                color: p.flame,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // نشاط الأسبوع
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: p.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'نشاط الأسبوع',
                                  style: TextStyle(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (b.dayStreak > 0)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 17,
                                      color: p.flame,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${Ar.n(b.dayStreak)} يوماً متتالياً',
                                      style: TextStyle(
                                        color: p.flame,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _WeekChart(activity: b.activity),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // تغطية بنك الأسئلة
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.donut_large_rounded,
                                size: 18,
                                color: p.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'تغطية بنك الأسئلة',
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: b.bankTotal == 0
                                  ? 0
                                  : b.seenTotal / b.bankTotal,
                              minHeight: 8,
                              backgroundColor: p.stroke,
                              valueColor: AlwaysStoppedAnimation(p.gold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'رأيت ${Ar.n(b.seenTotal)} سؤالاً من ${Ar.n(b.bankTotal)}',
                            style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (b.mistakes > 0) ...[
                      const SizedBox(height: 14),
                      GlassCard(
                        tint: p.wrong,
                        onTap: () {
                          ref
                              .read(reviewControllerProvider.notifier)
                              .start(mode: ReviewMode.mistakes);
                          Navigator.pushNamed(context, AppRoutes.review);
                        },
                        child: Row(
                          children: [
                            Icon(Icons.replay_rounded, color: p.wrong, size: 26),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مراجعة الأخطاء',
                                    style: TextStyle(
                                      color: p.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${Ar.n(b.mistakes)} سؤالاً بانتظار التصحيح',
                                    style: TextStyle(
                                      color: p.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 15,
                              color: p.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),
                    Text(
                      'حسب الموضوع',
                      style: TextStyle(
                        fontFamily: fontDisplay,
                        color: p.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (active.isEmpty)
                      GlassCard(
                        child: Text(
                          'لم تبدأ أي مراجعة بعد. ابدأ الآن وستظهر تفاصيل تقدّمك هنا.',
                          style: TextStyle(
                            color: p.textSecondary,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...active.map((t) {
                        final s = b.perTopic[t.name] ?? const TopicStats();
                        final seen = b.seenByTopic[t.name] ?? 0;
                        final acc = s.accuracy;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: TextStyle(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.5,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: s.answered == 0 ? 0 : acc,
                                    minHeight: 7,
                                    backgroundColor: p.stroke,
                                    valueColor: AlwaysStoppedAnimation(
                                      acc >= 0.7
                                          ? p.correct
                                          : acc >= 0.4
                                          ? p.gold
                                          : p.wrong,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  s.answered == 0
                                      ? 'رأيت ${Ar.n(seen)} من ${Ar.n(t.questionCount)}'
                                      : '${Ar.n(s.correct)} صحيحة من ${Ar.n(s.answered)} · الدقة ${Ar.n(s.accuracyPercent)}٪ · رأيت ${Ar.n(seen)} من ${Ar.n(t.questionCount)}',
                                  style: TextStyle(
                                    color: p.textMuted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _reset(b.topics),
                      icon: Icon(Icons.restart_alt_rounded, color: p.wrong),
                      label: Text(
                        'تصفير كل الإحصائيات',
                        style: TextStyle(color: p.wrong),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// مخطط بسيط لعدد الإجابات في آخر سبعة أيام
class _WeekChart extends StatelessWidget {
  final List<({DateTime day, int count})> activity;
  const _WeekChart({required this.activity});

  static const _names = ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final max = activity.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    final today = DateTime.now();

    return SizedBox(
      height: 108,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: activity.map((e) {
          final isToday =
              e.day.year == today.year &&
              e.day.month == today.month &&
              e.day.day == today.day;
          final ratio = max == 0 ? 0.0 : e.count / max;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    e.count == 0 ? '' : Ar.n(e.count),
                    style: TextStyle(
                      color: isToday ? p.gold : p.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Container(
                      height: 8 + 54 * v,
                      decoration: BoxDecoration(
                        color: e.count == 0
                            ? p.stroke
                            : (isToday
                                  ? p.gold
                                  : p.gold.withValues(alpha: 0.45)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _names[e.day.weekday - 1],
                    style: TextStyle(
                      color: isToday ? p.textPrimary : p.textMuted,
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatsBundle {
  final List<QuizTopic> topics;
  final TopicStats overall;
  final Map<String, TopicStats> perTopic;
  final int sessions;
  final int bestStreak;
  final Map<String, int> seenByTopic;
  final int seenTotal;
  final int bankTotal;
  final int mistakes;
  final List<({DateTime day, int count})> activity;
  final int dayStreak;

  _StatsBundle({
    required this.topics,
    required this.overall,
    required this.perTopic,
    required this.sessions,
    required this.bestStreak,
    required this.seenByTopic,
    required this.seenTotal,
    required this.bankTotal,
    required this.mistakes,
    required this.activity,
    required this.dayStreak,
  });
}
