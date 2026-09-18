import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

/// 💡 لوحة سفلية تعرض الجواب الصحيح + مستند (مصدر) الجواب
Future<void> showReferenceSheet(
  BuildContext context, {
  required String correctAnswer,
  required String reference,
}) {
  HapticFeedback.selectionClick();
  final p = context.p;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.58,
        minChildSize: 0.28,
        maxChildSize: 0.88,
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.gold.withValues(alpha: 0.45)),
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: p.gold,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'مستند الجواب',
                      style: TextStyle(
                        fontFamily: fontDisplay,
                        color: p.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'إغلاق',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: p.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Block(
                title: 'الجواب الصحيح',
                icon: Icons.check_circle_rounded,
                color: p.correct,
                body: correctAnswer,
              ),
              const SizedBox(height: 14),
              _Block(
                title: 'المصدر',
                icon: Icons.menu_book_rounded,
                color: p.info,
                body: reference.trim().isEmpty
                    ? 'لا يوجد مستند مسجّل لهذا السؤال.'
                    : reference,
                selectable: reference.trim().isNotEmpty,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.done_rounded),
                  label: const Text('فهمت'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Block extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String body;
  final bool selectable;

  const _Block({
    required this.title,
    required this.icon,
    required this.color,
    required this.body,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final style = TextStyle(
      color: p.textPrimary,
      fontSize: K.fontSize,
      height: 1.8,
      fontWeight: FontWeight.w500,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          selectable
              ? SelectableText(body, style: style, textAlign: TextAlign.justify)
              : Text(body, style: style, textAlign: TextAlign.justify),
        ],
      ),
    );
  }
}
