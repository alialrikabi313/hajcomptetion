import 'dart:math' as math;
import 'package:flutter/material.dart';

class ProgressTimer extends StatelessWidget {
  final int remaining;
  final int total;

  const ProgressTimer({
    super.key,
    required this.remaining,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    // اجعل الحجم متناسبًا مع الشاشة أو مع الحاوية الأب
    return LayoutBuilder(
      builder: (context, constraints) {
        // الحجم الأصغر من العرض أو الارتفاع
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final progress = remaining / total;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الخلفية الرمادية
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: size * 0.1,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.1)),
                ),
              ),
              // المؤشر المتحرك
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: size * 0.1,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                  backgroundColor: Colors.transparent,
                ),
              ),
              // الرقم في الوسط
              Text(
                remaining.toString(),
                style: TextStyle(
                  color: remaining <= 5 ? Colors.redAccent : Colors.white,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


