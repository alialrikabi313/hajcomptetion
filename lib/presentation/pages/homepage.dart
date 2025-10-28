import 'package:flutter/material.dart';
import '../../core/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A3D2E),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(
                  'مسابقة فقه الحج',
                  style: TextStyle(
                    color: Colors.amber.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width * 0.075,
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),

                _MainButton(
                  label: 'بدء المسابقة',
                  icon: Icons.play_arrow_rounded,
                  color1: const Color(0xFFDAA520),
                  color2: const Color(0xFFF4E07D),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.levels),
                ),
                const SizedBox(height: 20),


                _MainButton(
                  label: 'الإعدادات',
                  icon: Icons.settings_rounded,
                  color1: const Color(0xFF136356),
                  color2: const Color(0xFF0A3D2E),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.settings),
                ),
                const SizedBox(height: 20),

                _MainButton(
                  label: 'حول التطبيق',
                  icon: Icons.info_outline,
                  color1: const Color(0xFF136356),
                  color2: const Color(0xFF0A3D2E),
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.about),
                ),
                const SizedBox(height: 20),

                const Spacer(),
                const Text(
                  '© مكتبة القائم - جميع الحقوق محفوظة',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;

  const _MainButton({
    required this.label,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            vertical: size.height * 0.02, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: size.width * 0.07),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: size.width * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
