import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/arabic.dart';

/// ⏱️ مؤقّت دائري مصغّر
class ProgressTimer extends StatelessWidget {
  final int remaining;
  final int total;

  const ProgressTimer({super.key, required this.remaining, required this.total});

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final progress = total == 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
        final danger = remaining <= 5;
        final color = danger ? p.wrong : p.gold;

        return Semantics(
          label: 'الوقت المتبقي $remaining ثانية',
          child: SizedBox(
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
                    strokeWidth: size * 0.09,
                    valueColor: AlwaysStoppedAnimation(p.stroke),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: progress, end: progress),
                  duration: const Duration(milliseconds: 400),
                  builder: (_, v, __) => SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: size * 0.09,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                Text(
                  Ar.n(remaining),
                  style: TextStyle(
                    color: danger ? p.wrong : p.textPrimary,
                    fontSize: size * 0.33,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
