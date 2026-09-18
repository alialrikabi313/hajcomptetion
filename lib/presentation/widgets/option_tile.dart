import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/constants.dart';

/// 🔘 خيار إجابة بحالات: عادي / مُختار خاطئ / صحيح / معطّل
class OptionTile extends StatelessWidget {
  final String text;
  final String badge; // أ، ب، ج، د
  final bool answered;
  final bool isCorrect;
  final bool isSelected;
  final VoidCallback? onTap;

  const OptionTile({
    super.key,
    required this.text,
    required this.badge,
    required this.answered,
    required this.isCorrect,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final bool showCorrect = answered && isCorrect;
    final bool showWrong = answered && isSelected && !isCorrect;
    final bool dimmed = answered && !showCorrect && !showWrong;

    final Color bg = showCorrect
        ? p.correct.withValues(alpha: dark ? 0.92 : 0.12)
        : showWrong
        ? p.wrong.withValues(alpha: dark ? 0.92 : 0.12)
        : (dark ? p.surfaceHigh : p.surface);

    final Color borderColor = showCorrect
        ? p.correct
        : showWrong
        ? p.wrong
        : p.stroke;

    final Color fg = (showCorrect || showWrong)
        ? (dark ? Colors.white : (showCorrect ? p.correct : p.wrong))
        : p.textPrimary;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 260),
      opacity: dimmed ? 0.55 : 1,
      child: Semantics(
        button: !answered,
        selected: isSelected,
        label: 'الخيار $badge: $text',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: borderColor,
                  width: showCorrect || showWrong ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Badge(
                    label: badge,
                    highlighted: showCorrect || showWrong,
                    color: showCorrect
                        ? p.correct
                        : showWrong
                        ? p.wrong
                        : p.gold,
                    dark: dark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: fg,
                        fontSize: K.fontSize,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (showCorrect || showWrong) ...[
                    const SizedBox(width: 8),
                    Icon(
                      showCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: fg,
                      size: 23,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool highlighted;
  final Color color;
  final bool dark;

  const _Badge({
    required this.label,
    required this.highlighted,
    required this.color,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = highlighted && dark
        ? Colors.white.withValues(alpha: 0.22)
        : color.withValues(alpha: dark ? 0.18 : 0.14);
    final fg = highlighted && dark ? Colors.white : color;

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: fg.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
