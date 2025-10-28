import 'package:flutter/material.dart';

class LevelCard extends StatelessWidget {
  final String title;
  final bool unlocked;
  final VoidCallback? onTap;

  const LevelCard({
    super.key,
    required this.title,
    required this.unlocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? const Color(0xFF00ADB5) : const Color(0xFF393E46);
    final icon  = unlocked ? Icons.lock_open_rounded : Icons.lock_rounded;

    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: unlocked ? Colors.cyanAccent.withOpacity(0.5) : Colors.black38,
              blurRadius: 8, offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
