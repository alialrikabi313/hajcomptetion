import 'package:flutter/material.dart';

class AnswerTile extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool locked;       // هل تعطيل الزر مطلوب؟
  final bool showAsCorrect; // لتمييز الصحيح بعد الإجابة
  final bool showAsWrong;   // لتمييز الخطأ بعد الإجابة

  const AnswerTile({
    super.key,
    required this.text,
    required this.onTap,
    required this.locked,
    required this.showAsCorrect,
    required this.showAsWrong,
  });

  @override
  Widget build(BuildContext context) {
    Color bg() {
      if (!locked) return const Color(0xFF00ADB5);
      if (showAsCorrect) return Colors.green;
      if (showAsWrong) return Colors.redAccent;
      return const Color(0xFF393E46);
    }

    return InkWell(
      onTap: locked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bg(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(1, 2))
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
