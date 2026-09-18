import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// 🔖 شريحة إحصائية صغيرة (أيقونة + رقم + تسمية)
class StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool compact;

  const StatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 7 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 15 : 18, color: color),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              value,
              key: ValueKey('$label-$value'),
              style: TextStyle(
                color: p.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 14 : 16,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: p.textSecondary, fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// 🥧 دائرة نسبة مئوية متحركة
class PercentRing extends StatelessWidget {
  final double value; // 0..1
  final double size;
  final Color color;
  final Widget? center;
  final double stroke;

  const PercentRing({
    super.key,
    required this.value,
    this.size = 120,
    required this.color,
    this.center,
    this.stroke = 10,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: stroke,
                valueColor: AlwaysStoppedAnimation(p.stroke),
              ),
            ),
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: stroke,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (center != null) center!,
          ],
        ),
      ),
    );
  }
}
