import 'package:flutter/material.dart';
import '../../core/app_theme.dart';

/// 🕋 شعار التطبيق: أيقونة التطبيق الأصلية داخل حلقة ذهبية
class AppMark extends StatelessWidget {
  final double size;
  final bool ring;

  const AppMark({super.key, this.size = 46, this.ring = true});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final logo = Image.asset(
      'assets/images/icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );

    if (!ring) {
      return SizedBox(width: size, height: size, child: logo);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: p.gold.withValues(alpha: 0.45)),
      ),
      child: ClipOval(child: logo),
    );
  }
}
