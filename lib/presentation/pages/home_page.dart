import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_routes.dart';
import '../../core/app_theme.dart';
import '../../core/arabic.dart';
import '../../core/progress_service.dart';
import '../../core/session_store.dart';
import '../providers/quiz_providers.dart';
import '../providers/review_controller.dart';
import '../widgets/app_background.dart';
import '../widgets/app_mark.dart';
import '../widgets/glass_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late Future<TopicStats> _overall;

  @override
  void initState() {
    super.initState();
    _overall = _loadOverall();
  }

  Future<TopicStats> _loadOverall() async {
    await ProgressService.instance.load();
    return ProgressService.instance.overall();
  }

  void _refresh() {
    setState(() => _overall = _loadOverall());
    ref.invalidate(mistakesCountProvider);
    ref.invalidate(savedSessionProvider);
    ref.invalidate(seenByTopicProvider);
  }

  Future<void> _openReview() async {
    await Navigator.pushNamed(context, AppRoutes.review);
    if (mounted) _refresh();
  }

  Future<void> _startRandom() async {
    HapticFeedback.selectionClick();
    ref.read(reviewControllerProvider.notifier).start(mode: ReviewMode.random);
    await _openReview();
  }

  Future<void> _startMistakes() async {
    HapticFeedback.selectionClick();
    ref.read(reviewControllerProvider.notifier).start(mode: ReviewMode.mistakes);
    await _openReview();
  }

  Future<void> _resume(SavedSession s) async {
    HapticFeedback.selectionClick();
    final ok = await ref.read(reviewControllerProvider.notifier).resume(s);
    if (!mounted) return;
    if (!ok) {
      _refresh();
      return;
    }
    await _openReview();
  }

  Future<void> _openTopics() async {
    HapticFeedback.selectionClick();
    await Navigator.pushNamed(context, AppRoutes.topics);
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final totalAsync = ref.watch(totalQuestionsProvider);
    final topicsCount = ref.watch(topicsProvider).asData?.value.length;
    final mistakes = ref.watch(mistakesCountProvider).asData?.value ?? 0;
    final saved = ref.watch(savedSessionProvider).asData?.value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                // ===== الترويسة =====
                Row(
                  children: [
                    const AppMark(size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'مسابقة فقه الحج',
                            style: TextStyle(
                              fontFamily: fontDisplay,
                              color: p.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            totalAsync.when(
                              data: (t) =>
                                  '${Ar.n(t)} سؤالاً في ${Ar.n(topicsCount ?? 0)} مواضيع',
                              loading: () => 'جارٍ تحميل بنك الأسئلة…',
                              error: (_, __) => 'تعذّر تحميل بنك الأسئلة',
                            ),
                            style: TextStyle(color: p.textMuted, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'البحث في الأسئلة',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.search),
                      icon: Icon(Icons.search_rounded, color: p.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ===== استئناف جلسة =====
                if (saved != null) ...[
                  _ResumeCard(session: saved, onTap: () => _resume(saved)),
                  const SizedBox(height: 14),
                ],

                // ===== أنواع المراجعة =====
                _ModeCard(
                  title: 'مراجعة حسب الموضوع',
                  subtitle: 'اختر موضوعاً وراجع أسئلته',
                  icon: Icons.category_outlined,
                  primary: true,
                  onTap: _openTopics,
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  title: 'مراجعة عشوائية',
                  subtitle: 'أسئلة من جميع المواضيع بترتيب عشوائي',
                  icon: Icons.shuffle_rounded,
                  primary: false,
                  onTap: _startRandom,
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  title: 'مراجعة الأخطاء',
                  subtitle: mistakes == 0
                      ? 'لا توجد أخطاء مسجّلة — أحسنت'
                      : 'الأسئلة التي أخطأت فيها آخر مرة',
                  icon: Icons.replay_rounded,
                  primary: false,
                  badge: mistakes == 0 ? null : Ar.n(mistakes),
                  enabled: mistakes > 0,
                  onTap: _startMistakes,
                ),

                const SizedBox(height: 24),

                // ===== ملخص الإحصائيات =====
                FutureBuilder<TopicStats>(
                  future: _overall,
                  builder: (context, snap) {
                    final s = snap.data ?? const TopicStats();
                    return GlassCard(
                      onTap: () async {
                        await Navigator.pushNamed(context, AppRoutes.stats);
                        if (mounted) _refresh();
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.insights_outlined,
                                size: 18,
                                color: p.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'إحصائياتي',
                                  style: TextStyle(
                                    color: p.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 14,
                                color: p.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _MiniStat(
                                value: Ar.n(s.answered),
                                label: 'سؤال',
                                color: p.info,
                              ),
                              _divider(p),
                              _MiniStat(
                                value: Ar.n(s.correct),
                                label: 'صحيحة',
                                color: p.correct,
                              ),
                              _divider(p),
                              _MiniStat(
                                value: '${Ar.n(s.accuracyPercent)}٪',
                                label: 'الدقة',
                                color: p.gold,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _SmallAction(
                        icon: Icons.search_rounded,
                        label: 'بحث',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.search),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallAction(
                        icon: Icons.tune_rounded,
                        label: 'الإعدادات',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.settings),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallAction(
                        icon: Icons.info_outline_rounded,
                        label: 'حول',
                        onTap: () =>
                            Navigator.pushNamed(context, AppRoutes.about),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),
                Center(
                  child: Text(
                    '© مكتبة القائم - جميع الحقوق محفوظة',
                    style: TextStyle(color: p.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(AppPalette p) =>
      Container(width: 1, height: 30, color: p.stroke);
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: p.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final SavedSession session;
  final VoidCallback onTap;

  const _ResumeCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GlassCard(
      onTap: onTap,
      tint: p.info,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.play_circle_fill_rounded, color: p.info, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'متابعة المراجعة',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.title} · أجبت على ${Ar.n(session.shown)} سؤالاً',
                  style: TextStyle(color: p.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: p.textMuted),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool primary;
  final VoidCallback onTap;
  final String? badge;
  final bool enabled;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primary,
    required this.onTap,
    this.badge,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = primary ? p.gold : (dark ? p.surfaceHigh : p.surface);
    final fg = primary ? p.onGold : p.textPrimary;
    final sub = primary
        ? p.onGold.withValues(alpha: 0.78)
        : p.textSecondary;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: primary ? null : Border.all(color: p.stroke),
              boxShadow: [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              child: Row(
                children: [
                  Icon(icon, color: fg, size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: fg,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(color: sub, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: p.wrong.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: p.wrong.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: p.wrong,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: fg.withValues(alpha: 0.7),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      radius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: p.textSecondary, size: 19),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
