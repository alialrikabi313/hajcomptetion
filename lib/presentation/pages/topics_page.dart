import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// 📚 قائمة المواضيع المستخرجة من ملف الأسئلة
class TopicsPage extends ConsumerStatefulWidget {
  const TopicsPage({super.key});

  @override
  ConsumerState<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends ConsumerState<TopicsPage> {
  Map<String, TopicStats> _stats = {};
  bool _statsRequested = false;

  Future<void> _loadStats(List<QuizTopic> topics) async {
    await ProgressService.instance.load();
    final s = await ProgressService.instance.forTopics(
      topics.map((t) => t.name).toList(),
    );
    if (mounted) setState(() => _stats = s);
  }

  Future<void> _open(QuizTopic topic) async {
    HapticFeedback.selectionClick();
    ref
        .read(reviewControllerProvider.notifier)
        .start(mode: ReviewMode.topic, topic: topic.name);
    await Navigator.pushNamed(context, AppRoutes.review);
    if (!mounted) return;
    ref.invalidate(seenByTopicProvider);
    final topics = ref.read(topicsProvider).asData?.value ?? const <QuizTopic>[];
    await _loadStats(topics);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final topicsAsync = ref.watch(topicsProvider);
    final seen = ref.watch(seenByTopicProvider).asData?.value ?? const {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('المواضيع')),
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: topicsAsync.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: p.gold)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: p.wrong,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'تعذّر تحميل المواضيع',
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$e',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.textMuted, fontSize: 12.5),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.invalidate(allQuestionsProvider);
                            ref.invalidate(topicsProvider);
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (topics) {
                  if (!_statsRequested && topics.isNotEmpty) {
                    _statsRequested = true;
                    _loadStats(topics);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: topics.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final t = topics[i];
                      return _TopicCard(
                        topic: t,
                        stats: _stats[t.name] ?? const TopicStats(),
                        seen: seen[t.name] ?? 0,
                        onTap: () => _open(t),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final QuizTopic topic;
  final TopicStats stats;
  final int seen;
  final VoidCallback onTap;

  const _TopicCard({
    required this.topic,
    required this.stats,
    required this.seen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final coverage = topic.questionCount == 0
        ? 0.0
        : (seen / topic.questionCount).clamp(0.0, 1.0);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  topic.name,
                  style: TextStyle(
                    fontFamily: fontDisplay,
                    color: p.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.play_arrow_rounded, color: p.gold, size: 26),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: coverage,
              minHeight: 6,
              backgroundColor: p.stroke,
              valueColor: AlwaysStoppedAnimation(p.gold),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                seen == 0
                    ? '${Ar.n(topic.questionCount)} سؤال'
                    : 'رأيت ${Ar.n(seen)} من ${Ar.n(topic.questionCount)}',
                style: TextStyle(color: p.textSecondary, fontSize: 13),
              ),
              if (stats.answered > 0) ...[
                Text(
                  '  ·  ',
                  style: TextStyle(color: p.textMuted, fontSize: 13),
                ),
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: stats.accuracy >= 0.7 ? p.correct : p.gold,
                ),
                const SizedBox(width: 4),
                Text(
                  'دقتك ${Ar.n(stats.accuracyPercent)}٪',
                  style: TextStyle(color: p.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
