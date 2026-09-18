import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_routes.dart';
import '../../core/app_theme.dart';
import '../../core/arabic.dart';
import '../../core/constants.dart';
import '../providers/review_controller.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/option_tile.dart';
import '../widgets/progress_timer.dart';
import '../widgets/reference_sheet.dart';

const _badges = ['أ', 'ب', 'ج', 'د', 'هـ', 'و'];

/// 🧩 صفحة المراجعة (للأنواع الثلاثة: موضوع / عشوائية / أخطاء)
class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  Future<bool> _confirmEnd(BuildContext context, ReviewState s) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إنهاء المراجعة؟'),
          content: Text(
            s.shown == 0
                ? 'لم تجب على أي سؤال بعد. هل تريد الخروج؟'
                : 'أجبت على ${Ar.n(s.shown)} سؤالاً: ${Ar.n(s.correct)} صحيحة و${Ar.n(s.wrong)} خاطئة.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('متابعة'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('إنهاء'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _endSession(BuildContext context, WidgetRef ref) async {
    final state = ref.read(reviewControllerProvider);
    if (!await _confirmEnd(context, state)) return;
    await ref.read(reviewControllerProvider.notifier).finish();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.summary);
  }

  void _showSessionStats(BuildContext context, ReviewState s) {
    final p = context.p;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: p.stroke,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'إحصائيات هذه الجلسة',
                style: TextStyle(
                  fontFamily: fontDisplay,
                  color: p.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              _StatRow(
                icon: Icons.visibility_outlined,
                label: 'عدد الأسئلة التي ظهرت',
                value: Ar.n(s.shown),
                color: p.info,
              ),
              _StatRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'الإجابات الصحيحة',
                value: Ar.n(s.correct),
                color: p.correct,
              ),
              _StatRow(
                icon: Icons.cancel_outlined,
                label: 'الإجابات الخاطئة',
                value: Ar.n(s.wrong),
                color: p.wrong,
              ),
              _StatRow(
                icon: Icons.percent_rounded,
                label: 'نسبة الدقة',
                value: '${Ar.n(s.accuracyPercent)}٪',
                color: p.gold,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('متابعة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final state = ref.watch(reviewControllerProvider);
    final ctrl = ref.read(reviewControllerProvider.notifier);
    final q = state.current;

    // نفدت أسئلة الموضوع ⇒ المتحكم أنهى الجلسة، ننتقل إلى الملخّص
    ref.listen<ReviewState>(reviewControllerProvider, (prev, next) {
      if (next.completedAll && !(prev?.completedAll ?? false)) {
        Navigator.pushReplacementNamed(context, AppRoutes.summary);
      }
    });

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (state.shown == 0) {
            await ctrl.finish();
            if (context.mounted) Navigator.pop(context);
            return;
          }
          if (context.mounted) await _endSession(context, ref);
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'رجوع',
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: () => _endSession(context, ref),
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                state.title.isEmpty ? 'المراجعة' : state.title,
                style: const TextStyle(fontSize: 19),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextButton.icon(
                  onPressed: () => _endSession(context, ref),
                  icon: const Icon(Icons.stop_circle_outlined, size: 19),
                  label: const Text('إنهاء المراجعة'),
                  style: TextButton.styleFrom(
                    foregroundColor: p.gold,
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: AppBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight),
                child: state.loading
                    ? Center(child: CircularProgressIndicator(color: p.gold))
                    : q == null
                    ? _EmptyPool(mode: state.mode)
                    : Column(
                        children: [
                          _Header(
                            state: state,
                            onTap: () => _showSessionStats(context, state),
                          ),
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                              children: [
                                _QuestionCard(question: q),
                                const SizedBox(height: 14),
                                ...List.generate(
                                  q.options.length,
                                  (i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: OptionTile(
                                      text: q.options[i],
                                      badge: i < _badges.length
                                          ? _badges[i]
                                          : '${i + 1}',
                                      answered: state.isAnswered,
                                      isCorrect: i == q.correctIndex,
                                      isSelected: state.selectedIndex == i,
                                      onTap: state.isAnswered
                                          ? null
                                          : () {
                                              HapticFeedback.lightImpact();
                                              ctrl.answer(i);
                                            },
                                    ),
                                  ),
                                ),
                                if (state.isAnswered)
                                  _FeedbackBanner(state: state),
                              ],
                            ),
                          ),
                          _BottomBar(
                            state: state,
                            onReference: () {
                              ctrl.revealReference();
                              showReferenceSheet(
                                context,
                                correctAnswer: q.source.correctAnswer,
                                reference: q.reference,
                              );
                            },
                            onNext: () {
                              HapticFeedback.selectionClick();
                              ctrl.next();
                            },
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPool extends StatelessWidget {
  final ReviewMode mode;
  const _EmptyPool({required this.mode});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final isMistakes = mode == ReviewMode.mistakes;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMistakes
                  ? Icons.verified_rounded
                  : Icons.inbox_outlined,
              size: 54,
              color: isMistakes ? p.correct : p.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              isMistakes
                  ? 'لا توجد أخطاء مسجّلة'
                  : 'لا توجد أسئلة متاحة',
              style: TextStyle(
                fontFamily: fontDisplay,
                color: p.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isMistakes
                  ? 'كل ما أخطأت فيه صحّحته لاحقاً. راجع موضوعاً أو ابدأ مراجعة عشوائية.'
                  : 'تعذّر تحميل أسئلة هذه المراجعة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textSecondary, height: 1.7),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }
}

/// سطر واحد هادئ: رقم السؤال + الصحيح/الخطأ + المؤقّت (اضغط للتفاصيل)
class _Header extends StatelessWidget {
  final ReviewState state;
  final VoidCallback onTap;

  const _Header({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Text(
                state.poolSize > 0
                    ? 'السؤال ${Ar.n(state.shown + (state.isAnswered ? 0 : 1))}'
                          ' من ${Ar.n(state.poolSize)}'
                    : 'السؤال ${Ar.n(state.shown + (state.isAnswered ? 0 : 1))}',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 14),
              _Score(
                icon: Icons.check_rounded,
                value: state.correct,
                color: p.correct,
                label: 'إجابات صحيحة',
              ),
              const SizedBox(width: 10),
              _Score(
                icon: Icons.close_rounded,
                value: state.wrong,
                color: p.wrong,
                label: 'إجابات خاطئة',
              ),
              if (state.streak >= 5) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: p.flame.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: p.flame,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        Ar.n(state.streak),
                        style: TextStyle(
                          color: p.flame,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (K.showTimer)
                SizedBox(
                  width: 34,
                  height: 34,
                  child: ProgressTimer(
                    remaining: state.remainingSeconds,
                    total: K.secondsPerQuestion,
                  ),
                )
              else
                Icon(Icons.expand_more_rounded, color: p.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Score extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  final String label;

  const _Score({
    required this.icon,
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 3),
          Text(
            Ar.n(value),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final ReviewQuestion question;

  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Text(
        question.text,
        style: TextStyle(
          fontFamily: fontDisplay,
          color: p.textPrimary,
          fontSize: K.fontSize + 3,
          height: 1.75,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final ReviewState state;
  const _FeedbackBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final correct =
        state.selectedIndex != null &&
        state.selectedIndex == state.current?.correctIndex;

    final color = correct ? p.correct : p.wrong;
    final text = state.timedOut
        ? 'انتهى الوقت — الجواب الصحيح موضّح بالأخضر.'
        : correct
        ? 'إجابة صحيحة.'
        : 'إجابة غير صحيحة — الجواب الصحيح موضّح بالأخضر.';

    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            state.timedOut
                ? Icons.timer_off_outlined
                : correct
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// الشريط السفلي: زر المصباح (بعد الإجابة) + زر السؤال التالي
class _BottomBar extends StatelessWidget {
  final ReviewState state;
  final VoidCallback onReference;
  final VoidCallback onNext;

  const _BottomBar({
    required this.state,
    required this.onReference,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.75),
        border: Border(top: BorderSide(color: p.stroke)),
      ),
      child: Row(
        children: [
          if (state.isAnswered) ...[
            Tooltip(
              message: 'عرض مستند الجواب',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onReference,
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    width: 56,
                    height: 52,
                    decoration: BoxDecoration(
                      color: p.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: p.gold.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: p.gold,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: state.isAnswered ? onNext : null,
                child: Text(
                  state.isAnswered ? 'السؤال التالي' : 'اختر إجابة',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: p.textSecondary, fontSize: 15),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
