import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../core/arabic.dart';
import '../../core/constants.dart';
import '../../domain/entities/haj_question.dart';
import '../providers/quiz_providers.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

/// 🔎 البحث في نصوص الأسئلة والخيارات والمستندات
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<HajQuestion> _filter(List<HajQuestion> all) {
    final q = Ar.normalize(_query);
    if (q.length < 2) return const [];
    final words = q.split(' ').where((w) => w.isNotEmpty).toList();
    bool matches(String text) {
      final n = Ar.normalize(text);
      return words.every(n.contains);
    }

    return all
        .where(
          (x) =>
              matches(x.question) ||
              x.options.any(matches) ||
              matches(x.answerReference),
        )
        .take(60)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final allAsync = ref.watch(allQuestionsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('البحث في الأسئلة')),
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: kToolbarHeight),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) => setState(() => _query = v),
                      style: TextStyle(color: p.textPrimary),
                      cursorColor: p.gold,
                      decoration: InputDecoration(
                        hintText: 'اكتب كلمة… مثل: الشاذروان، الاستحاضة، الهدي',
                        hintStyle: TextStyle(color: p.textMuted, fontSize: 14),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: p.textMuted,
                        ),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح',
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: p.textMuted,
                                ),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        filled: true,
                        fillColor: p.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: p.stroke),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: p.stroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: p.gold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: allAsync.when(
                      loading: () =>
                          Center(child: CircularProgressIndicator(color: p.gold)),
                      error: (e, _) => Center(
                        child: Text(
                          'تعذّر تحميل الأسئلة',
                          style: TextStyle(color: p.wrong),
                        ),
                      ),
                      data: (all) {
                        final results = _filter(all);
                        if (_query.trim().length < 2) {
                          return _Hint(
                            icon: Icons.manage_search_rounded,
                            text:
                                'اكتب حرفين على الأقل للبحث في ${Ar.n(all.length)} سؤالاً،\nويشمل البحث نصوص الخيارات والمستندات.',
                          );
                        }
                        if (results.isEmpty) {
                          return const _Hint(
                            icon: Icons.search_off_rounded,
                            text: 'لا توجد نتائج مطابقة.',
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: results.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${Ar.n(results.length)} نتيجة',
                                  style: TextStyle(
                                    color: p.textMuted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              );
                            }
                            final q = results[i - 1];
                            return GlassCard(
                              padding: const EdgeInsets.all(14),
                              onTap: () => _showQuestion(context, q),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    q.question,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: p.textPrimary,
                                      fontSize: 15,
                                      height: 1.6,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bookmark_outline_rounded,
                                        size: 14,
                                        color: p.gold,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        q.topic,
                                        style: TextStyle(
                                          color: p.textSecondary,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
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

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: p.textMuted),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة تفصيلية للسؤال: الخيارات مع تمييز الصحيح + المستند
void _showQuestion(BuildContext context, HajQuestion q) {
  final p = context.p;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: p.gold, width: 2)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: p.stroke,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.bookmark_rounded, size: 15, color: p.gold),
                  const SizedBox(width: 6),
                  Text(
                    q.topic,
                    style: TextStyle(color: p.gold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                q.question,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: K.fontSize + 1,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...q.options.map((o) {
                final isCorrect = o == q.correctAnswer;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? p.correct.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCorrect ? p.correct : p.stroke,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isCorrect) ...[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 19,
                          color: p.correct,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          o,
                          style: TextStyle(
                            color: isCorrect ? p.correct : p.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: isCorrect
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.info.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.info.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 17, color: p.info),
                        const SizedBox(width: 7),
                        Text(
                          'المستند',
                          style: TextStyle(
                            color: p.info,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      q.hasReference
                          ? q.answerReference
                          : 'لا يوجد مستند مسجّل لهذا السؤال.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 15,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
