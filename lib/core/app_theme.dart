import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// وضع السمة الحالي (نظام / فاتح / داكن) — يُعاد بناء التطبيق عند تغييره
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.system);

/// 🎨 ألوان التطبيق لكل سمة، عبر ThemeExtension حتى تعمل الواجهة في الوضعين
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bgTop;
  final Color bgMid;
  final Color bgBottom;
  final Color surface;
  final Color surfaceHigh;
  final Color stroke;
  final Color gold;
  final Color goldLight;
  final Color goldDark;
  final Color onGold;
  final Color correct;
  final Color wrong;
  final Color info;
  final Color flame;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color shadow;
  final Color glassTop;
  final Color glassBottom;

  const AppPalette({
    required this.bgTop,
    required this.bgMid,
    required this.bgBottom,
    required this.surface,
    required this.surfaceHigh,
    required this.stroke,
    required this.gold,
    required this.goldLight,
    required this.goldDark,
    required this.onGold,
    required this.correct,
    required this.wrong,
    required this.info,
    required this.flame,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.shadow,
    required this.glassTop,
    required this.glassBottom,
  });

  static const dark = AppPalette(
    bgTop: Color(0xFF072A20),
    bgMid: Color(0xFF0A3D2E),
    bgBottom: Color(0xFF06231B),
    surface: Color(0xFF10241B),
    surfaceHigh: Color(0xFF14624A),
    stroke: Color(0x2AFFFFFF),
    gold: Color(0xFFE7B84B),
    goldLight: Color(0xFFF7DE9A),
    goldDark: Color(0xFFC79328),
    onGold: Color(0xFF20180A),
    correct: Color(0xFF19B36B),
    wrong: Color(0xFFE0574F),
    info: Color(0xFF4FB6E8),
    flame: Color(0xFFFF8A3D),
    textPrimary: Color(0xFFF1F8F3),
    textSecondary: Color(0xCCFFFFFF),
    textMuted: Color(0x99FFFFFF),
    shadow: Color(0x66000000),
    glassTop: Color(0x1AFFFFFF),
    glassBottom: Color(0x0DFFFFFF),
  );

  static const light = AppPalette(
    bgTop: Color(0xFFF7FAF5),
    bgMid: Color(0xFFEFF5EC),
    bgBottom: Color(0xFFE6EEE2),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEAF3E9),
    stroke: Color(0x1F0B3B2A),
    gold: Color(0xFFB4861E),
    goldLight: Color(0xFF8A6512),
    goldDark: Color(0xFF8A6512),
    onGold: Color(0xFFFFFFFF),
    correct: Color(0xFF157F4B),
    wrong: Color(0xFFB4342C),
    info: Color(0xFF1E6FA0),
    flame: Color(0xFFC1611B),
    textPrimary: Color(0xFF10251C),
    textSecondary: Color(0xFF3F5147),
    textMuted: Color(0xFF6C7D73),
    shadow: Color(0x14103A28),
    glassTop: Color(0xFFFFFFFF),
    glassBottom: Color(0xFFF7FAF6),
  );

  @override
  AppPalette copyWith({
    Color? bgTop,
    Color? bgMid,
    Color? bgBottom,
    Color? surface,
    Color? surfaceHigh,
    Color? stroke,
    Color? gold,
    Color? goldLight,
    Color? goldDark,
    Color? onGold,
    Color? correct,
    Color? wrong,
    Color? info,
    Color? flame,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? shadow,
    Color? glassTop,
    Color? glassBottom,
  }) {
    return AppPalette(
      bgTop: bgTop ?? this.bgTop,
      bgMid: bgMid ?? this.bgMid,
      bgBottom: bgBottom ?? this.bgBottom,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      stroke: stroke ?? this.stroke,
      gold: gold ?? this.gold,
      goldLight: goldLight ?? this.goldLight,
      goldDark: goldDark ?? this.goldDark,
      onGold: onGold ?? this.onGold,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      info: info ?? this.info,
      flame: flame ?? this.flame,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      shadow: shadow ?? this.shadow,
      glassTop: glassTop ?? this.glassTop,
      glassBottom: glassBottom ?? this.glassBottom,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bgTop: c(bgTop, other.bgTop),
      bgMid: c(bgMid, other.bgMid),
      bgBottom: c(bgBottom, other.bgBottom),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      stroke: c(stroke, other.stroke),
      gold: c(gold, other.gold),
      goldLight: c(goldLight, other.goldLight),
      goldDark: c(goldDark, other.goldDark),
      onGold: c(onGold, other.onGold),
      correct: c(correct, other.correct),
      wrong: c(wrong, other.wrong),
      info: c(info, other.info),
      flame: c(flame, other.flame),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      shadow: c(shadow, other.shadow),
      glassTop: c(glassTop, other.glassTop),
      glassBottom: c(glassBottom, other.glassBottom),
    );
  }
}

extension PaletteContext on BuildContext {
  /// ألوان السمة الحالية
  AppPalette get p =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

/// الخط الأساسي للواجهة، وخط العناوين ونصوص الأسئلة
const String fontUi = 'Tajawal';
const String fontDisplay = 'Amiri';

ThemeData _theme(AppPalette p, Brightness brightness) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: fontUi,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.gold,
      brightness: brightness,
    ).copyWith(
      primary: p.gold,
      onPrimary: p.onGold,
      secondary: p.surfaceHigh,
      surface: p.surface,
      onSurface: p.textPrimary,
      error: p.wrong,
    ),
    scaffoldBackgroundColor: p.bgMid,
  );

  return base.copyWith(
    extensions: [p],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.textPrimary,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: fontDisplay,
        color: p.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    ),
    dividerTheme: DividerThemeData(color: p.stroke, space: 32),
    iconTheme: IconThemeData(color: p.textSecondary),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.gold,
        foregroundColor: p.onGold,
        disabledBackgroundColor: p.stroke,
        disabledForegroundColor: p.textMuted,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: fontUi,
          fontSize: 16.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.goldLight),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.textPrimary,
        side: BorderSide(color: p.stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontFamily: fontUi,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surfaceHigh,
      contentTextStyle: TextStyle(color: p.textPrimary, fontFamily: fontUi),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
        fontFamily: fontDisplay,
        color: p.textPrimary,
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        fontFamily: fontUi,
        color: p.textSecondary,
        fontSize: 15.5,
        height: 1.7,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.gold,
      inactiveTrackColor: p.stroke,
      thumbColor: p.gold,
      valueIndicatorColor: p.goldDark,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}

ThemeData buildDarkTheme() => _theme(AppPalette.dark, Brightness.dark);
ThemeData buildLightTheme() => _theme(AppPalette.light, Brightness.light);
