import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// 🪟 بطاقة موحّدة الشكل تعمل في الوضعين الفاتح والداكن
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double radius;
  final Color? tint;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.onTap,
    this.radius = 22,
    this.tint,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final borderRadius = BorderRadius.circular(radius);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final gradient = tint != null
        ? LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              tint!.withValues(alpha: dark ? 0.22 : 0.16),
              tint!.withValues(alpha: dark ? 0.08 : 0.06),
            ],
          )
        : LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [p.glassTop, p.glassBottom],
          );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: gradient,
          border: border ?? Border.all(color: p.stroke),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            splashColor: p.gold.withValues(alpha: 0.12),
            highlightColor: p.gold.withValues(alpha: 0.06),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
