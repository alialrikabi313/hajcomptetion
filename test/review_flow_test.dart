import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_levels_clean/core/app_theme.dart';
import 'package:quiz_levels_clean/core/constants.dart';
import 'package:quiz_levels_clean/presentation/pages/review_page.dart';
import 'package:quiz_levels_clean/presentation/providers/review_controller.dart';
import 'package:quiz_levels_clean/presentation/widgets/option_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    K.soundEnabled = false; // لا مؤثرات صوتية داخل الاختبارات
    K.showTimer = false;
    SharedPreferences.setMockInitialValues({});
  });

  /// تشغيل عدة إطارات (لا نستعمل pumpAndSettle بسبب أنيميشن النبض اللانهائي)
  Future<void> settle(WidgetTester tester, [int frames = 8]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  Future<ProviderContainer> pumpReview(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // قراءة ملف الأصول تحتاج تنفيذاً حقيقياً خارج الزمن الوهمي
    await tester.runAsync(
      () => container
          .read(reviewControllerProvider.notifier)
          .start(mode: ReviewMode.random),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildDarkTheme(), home: const ReviewPage()),
      ),
    );
    await settle(tester);
    return container;
  }

  testWidgets('الإجابة تُظهر زر المصباح وتفتح مستند الجواب', (tester) async {
    final container = await pumpReview(tester);

    final state = container.read(reviewControllerProvider);
    expect(state.loading, isFalse);
    expect(state.current, isNotNull);
    expect(find.byType(OptionTile), findsWidgets);

    // لا يُعرض موضوع السؤال في المراجعة العشوائية
    expect(find.text(state.current!.topic), findsNothing);
    expect(find.text('مراجعة عشوائية'), findsOneWidget); // عنوان الصفحة فقط

    // لا مصباح قبل الإجابة
    expect(find.byTooltip('عرض مستند الجواب'), findsNothing);

    // الإجابة بالخيار الصحيح
    final correctFinder = find.byType(OptionTile).at(state.current!.correctIndex);
    await tester.ensureVisible(correctFinder);
    await tester.pump();
    await tester.tap(correctFinder);
    await settle(tester);

    final answered = container.read(reviewControllerProvider);
    expect(answered.isAnswered, isTrue);
    expect(answered.shown, 1);
    expect(answered.correct, 1);
    expect(answered.wrong, 0);

    // ظهر زر المصباح
    final lamp = find.byTooltip('عرض مستند الجواب');
    expect(lamp, findsOneWidget);

    // الضغط عليه يفتح لوحة مستند الجواب
    await tester.tap(lamp);
    await settle(tester);

    expect(container.read(reviewControllerProvider).referenceShown, isTrue);
    expect(find.text('مستند الجواب'), findsOneWidget);
    expect(find.text('الجواب الصحيح'), findsOneWidget);
    expect(find.text(answered.current!.source.correctAnswer), findsWidgets);

    // «المصدر» قد يحتاج تمريراً داخل اللوحة
    await tester.scrollUntilVisible(
      find.text('المصدر'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await settle(tester, 3);
    expect(find.text('المصدر'), findsOneWidget);
  });

  testWidgets('زر «إنهاء المراجعة» ظاهر ويعرض تأكيداً', (tester) async {
    final container = await pumpReview(tester);

    final correct = container.read(reviewControllerProvider).current!.correctIndex;
    final tile = find.byType(OptionTile).at(correct);
    await tester.ensureVisible(tile);
    await tester.pump();
    await tester.tap(tile);
    await settle(tester);

    await tester.tap(find.text('إنهاء المراجعة'));
    await settle(tester);

    expect(find.text('إنهاء المراجعة؟'), findsOneWidget);
    expect(find.textContaining('أجبت على ١ سؤالاً'), findsOneWidget);

    await tester.tap(find.text('متابعة'));
    await settle(tester);
    expect(container.read(reviewControllerProvider).finished, isFalse);
  });

  testWidgets('شريط الإحصائيات يعرض عدد الظهور والصحيح والخاطئ', (
    tester,
  ) async {
    final container = await pumpReview(tester);
    final ctrl = container.read(reviewControllerProvider.notifier);

    // إجابة صحيحة ثم خاطئة
    ctrl.answer(container.read(reviewControllerProvider).current!.correctIndex);
    await settle(tester, 3);
    ctrl.next();
    await settle(tester, 3);

    final q = container.read(reviewControllerProvider).current!;
    ctrl.answer((q.correctIndex + 1) % q.options.length);
    await settle(tester, 3);

    final s = container.read(reviewControllerProvider);
    expect(s.shown, 2);
    expect(s.correct, 1);
    expect(s.wrong, 1);

    // فتح تفاصيل الإحصائيات بالضغط على شريط الرأس (يعرض الموقع من المجموع)
    final header = find.textContaining('السؤال ٢ من');
    expect(header, findsOneWidget);
    await tester.tap(header);
    await settle(tester);

    expect(find.text('إحصائيات هذه الجلسة'), findsOneWidget);
    expect(find.text('عدد الأسئلة التي ظهرت'), findsOneWidget);
    expect(find.text('الإجابات الصحيحة'), findsOneWidget);
    expect(find.text('الإجابات الخاطئة'), findsOneWidget);
  });
}
