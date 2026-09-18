import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';
import '../../core/arabic.dart';
import '../providers/quiz_providers.dart';
import '../widgets/app_background.dart';
import '../widgets/app_mark.dart';
import '../widgets/glass_card.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  Future<void> _openTelegram() async {
    const url = 'https://t.me/sahibalzaman313';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final bank = ref.watch(bankStatsProvider).asData?.value;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('حول التطبيق')),
        body: AppBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 8, 20, 28),
              children: [
                Column(
                  children: [
                    const AppMark(size: 84),
                    const SizedBox(height: 14),
                    Text(
                      'تطبيق مسابقة الحج',
                      style: TextStyle(
                        fontFamily: fontDisplay,
                        color: p.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم برمجة هذا التطبيق لخدمة الإخوة مرشدي الحج، لمساعدتهم في '
                        'الاستعداد لامتحان إرشاد الحج بشكل علمي وتفاعلي.',
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 15.5,
                          height: 1.8,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        bank == null
                            ? 'يتضمن التطبيق بنك أسئلة موزّعاً على عدة مواضيع فقهية.'
                            : 'يتضمن التطبيق ${Ar.n(bank.total)} سؤالاً فقهياً '
                                  'موزعة على ${Ar.n(bank.topics)} موضوعاً.',
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 15.5,
                          height: 1.8,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const _SectionTitle('بنك الأسئلة'),
                const SizedBox(height: 10),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Count(
                              value: bank?.total,
                              label: 'مجموع الأسئلة',
                              icon: Icons.library_books_rounded,
                            ),
                          ),
                          _Divider(color: p.stroke),
                          Expanded(
                            child: _Count(
                              value: bank?.withReference,
                              label: 'مع مستند',
                              icon: Icons.menu_book_rounded,
                            ),
                          ),
                          _Divider(color: p.stroke),
                          Expanded(
                            child: _Count(
                              value: bank?.withoutReference,
                              label: 'بلا مستند',
                              icon: Icons.help_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        bank == null
                            ? 'أغلب الأسئلة مذكور فيها مستند (مصدر) الجواب.'
                            : '${Ar.n(bank.withReference)} سؤالاً مذكور فيه مستند '
                                  '(مصدر) الجواب من كتاب المناسك، و${Ar.n(bank.withoutReference)} '
                                  'سؤالاً بلا مستند.',
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 15.5,
                          height: 1.8,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: p.gold.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: p.gold.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: p.gold,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'وجميع الأسئلة التي لا مستند لها مطابقة لأجوبة '
                                'دائرة الإرشاد.',
                                style: TextStyle(
                                  color: p.textPrimary,
                                  fontSize: 14.5,
                                  height: 1.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const _SectionTitle('مزايا التطبيق'),
                const SizedBox(height: 10),
                const _Feature(
                  icon: Icons.category_rounded,
                  title: 'مراجعة حسب الموضوع',
                  body:
                      'اختر موضوعاً محدداً (الطواف، السعي، الرمي، الذبح…) وراجع أسئلته كلّها.',
                ),
                const _Feature(
                  icon: Icons.shuffle_rounded,
                  title: 'مراجعة عشوائية',
                  body: 'أسئلة عشوائية من جميع المواضيع دون التقيّد بموضوع واحد.',
                ),
                const _Feature(
                  icon: Icons.lightbulb_rounded,
                  title: 'زر المصباح — مستند الجواب',
                  body:
                      'بعد الإجابة على أي سؤال يمكنك عرض المسألة أو الصفحة التي أُخذ منها الجواب.',
                ),
                const _Feature(
                  icon: Icons.insights_rounded,
                  title: 'إحصائيات دقيقة',
                  body:
                      'عدد الأسئلة التي ظهرت لك، الصحيحة والخاطئة، ونسبة الدقة لكل موضوع.',
                ),
                const _Feature(
                  icon: Icons.replay_rounded,
                  title: 'مراجعة الأخطاء',
                  body:
                      'التطبيق يحفظ كل سؤال أخطأت فيه، ويجمعها لك في مراجعة خاصة حتى تتقنها.',
                ),
                const _Feature(
                  icon: Icons.search_rounded,
                  title: 'بحث في بنك الأسئلة',
                  body: 'ابحث بكلمة واحدة في نصوص الأسئلة والخيارات والمستندات.',
                ),
                const _Feature(
                  icon: Icons.notifications_active_rounded,
                  title: 'تذكير يومي',
                  body:
                      'إشعار يومي في الوقت الذي تختاره، مع تتبّع سلسلة أيام مراجعتك.',
                ),
                const _Feature(
                  icon: Icons.tune_rounded,
                  title: 'إعدادات مرنة',
                  body:
                      'مظهر فاتح وداكن، المؤقّت ومدّته، المؤثرات الصوتية، وحجم الخط.',
                ),

                const SizedBox(height: 18),
                GlassCard(
                  child: Column(
                    children: [
                      Text(
                        'قد يتم تحديث التطبيق لاحقاً بإضافة المزيد من الأسئلة والمحتوى. '
                        'للمزيد من التطبيقات ولمتابعة التحديثات انضم إلى قناتنا:',
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 15,
                          height: 1.8,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openTelegram,
                          icon: const Icon(Icons.telegram_rounded, size: 24),
                          label: const Text('الانضمام إلى القناة'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                GlassCard(
                  child: Column(
                    children: [
                      Icon(Icons.code_rounded, color: p.gold, size: 22),
                      const SizedBox(height: 10),
                      Text(
                        'التطبيق من برمجة وتطوير',
                        style: TextStyle(color: p.textMuted, fontSize: 13.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الشيخ علي هاشم الركابي',
                        style: TextStyle(
                          fontFamily: fontDisplay,
                          color: p.gold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),
                Center(
                  child: Text(
                    '© مكتبة القائم - جميع الحقوق محفوظة',
                    style: TextStyle(color: p.textMuted, fontSize: 12.5),
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

/// رقم واحد من أرقام بنك الأسئلة
class _Count extends StatelessWidget {
  final int? value;
  final String label;
  final IconData icon;

  const _Count({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(
      children: [
        Icon(icon, color: p.gold, size: 18),
        const SizedBox(height: 6),
        Text(
          value == null ? '—' : Ar.n(value!),
          style: TextStyle(
            fontFamily: fontDisplay,
            color: p.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: p.textMuted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 44, color: color);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: p.gold,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontFamily: fontDisplay,
            color: p.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Feature({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 18,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: p.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: p.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: p.textMuted,
                      fontSize: 13.5,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
