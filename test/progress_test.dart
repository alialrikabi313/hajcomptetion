import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_levels_clean/core/arabic.dart';
import 'package:quiz_levels_clean/core/constants.dart';
import 'package:quiz_levels_clean/core/progress_service.dart';
import 'package:quiz_levels_clean/core/session_store.dart';
import 'package:quiz_levels_clean/presentation/providers/quiz_providers.dart';
import 'package:quiz_levels_clean/presentation/providers/review_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() async {
    K.soundEnabled = false;
    K.showTimer = false;
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.resetAll(const []);
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  ReviewState read() => container.read(reviewControllerProvider);
  ReviewController ctrl() => container.read(reviewControllerProvider.notifier);

  group('تطبيع النص العربي والمعرّف الثابت', () {
    test('التطبيع يوحّد الهمزات والتشكيل', () {
      expect(Ar.normalize('الإحرام'), Ar.normalize('الاحرام'));
      expect(Ar.normalize('الحجّة'), Ar.normalize('الحجه'));
      expect(Ar.normalize('  مِنى   '), 'مني');
    });

    test('المعرّف ثابت لنفس النص ومختلف لغيره', () {
      expect(Ar.stableId('طواف النساء'), Ar.stableId('طواف النساء'));
      expect(Ar.stableId('طواف النساء'), isNot(Ar.stableId('طواف الحج')));
    });
  });

  group('سجل الأخطاء', () {
    test('الإجابة الخاطئة تدخل قائمة الأخطاء والصحيحة تخرجها منها', () async {
      await ctrl().start(mode: ReviewMode.random);
      final q = read().current!;
      final id = q.source.id;

      // إجابة خاطئة
      ctrl().answer((q.correctIndex + 1) % q.options.length);
      await Future<void>.delayed(Duration.zero);
      expect(ProgressService.instance.mistakeIds(), contains(id));
      expect(read().mistakes.length, 1);
      expect(read().mistakes.first.question.id, id);

      // نفس السؤال يُجاب صحيحاً لاحقاً
      await ProgressService.instance.recordAnswer(
        id: id,
        topic: q.topic,
        correct: true,
      );
      expect(ProgressService.instance.mistakeIds(), isNot(contains(id)));
    });

    test('مراجعة الأخطاء تقتصر على الأسئلة الخاطئة', () async {
      final all = await container.read(getQuestionsUseCaseProvider).all();
      final wrongOnes = all.take(3).toList();
      for (final q in wrongOnes) {
        await ProgressService.instance.recordAnswer(
          id: q.id,
          topic: q.topic,
          correct: false,
        );
      }

      await ctrl().start(mode: ReviewMode.mistakes);
      expect(read().poolSize, 3);
      expect(read().title, 'مراجعة الأخطاء');
      expect(
        wrongOnes.map((q) => q.id),
        contains(read().current!.source.id),
      );
    });

    test('التغطية تُحتسب من سجل الأسئلة التي ظهرت', () async {
      await ctrl().start(mode: ReviewMode.random);
      for (var i = 0; i < 4; i++) {
        ctrl().answer(read().current!.correctIndex);
        ctrl().next();
      }
      await Future<void>.delayed(Duration.zero);
      expect(ProgressService.instance.seenIds().length, 4);
    });
  });

  group('النشاط اليومي', () {
    test('كل إجابة تُسجَّل في نشاط اليوم، والسلسلة تبدأ بيوم واحد', () async {
      await ctrl().start(mode: ReviewMode.random);
      for (var i = 0; i < 3; i++) {
        ctrl().answer(read().current!.correctIndex);
        ctrl().next();
      }
      await Future<void>.delayed(Duration.zero);

      final progress = ProgressService.instance;
      expect(progress.answersOn(DateTime.now()), 3);
      expect(progress.dayStreak(), 1);

      final week = progress.recentActivity(7);
      expect(week.length, 7);
      expect(week.last.count, 3); // اليوم في آخر القائمة
      expect(week.first.count, 0);
    });

    test('لا سلسلة قبل أي مراجعة', () async {
      await ProgressService.instance.load();
      expect(ProgressService.instance.dayStreak(), 0);
    });
  });

  group('استئناف الجلسة', () {
    test('الجلسة تُحفظ أثناء المراجعة وتُستأنف بنفس الأرقام', () async {
      await ctrl().start(mode: ReviewMode.random);
      ctrl().answer(read().current!.correctIndex);
      ctrl().next();
      ctrl().answer(
        (read().current!.correctIndex + 1) % read().current!.options.length,
      );
      await Future<void>.delayed(Duration.zero);

      final saved = await SessionStore.instance.read();
      expect(saved, isNotNull);
      expect(saved!.shown, 2);
      expect(saved.correct, 1);
      expect(saved.wrong, 1);

      // متحكم جديد يستأنف الجلسة
      final other = ProviderContainer();
      addTearDown(other.dispose);
      final ok = await other
          .read(reviewControllerProvider.notifier)
          .resume(saved);
      expect(ok, isTrue);
      final resumed = other.read(reviewControllerProvider);
      expect(resumed.shown, 2);
      expect(resumed.correct, 1);
      expect(resumed.wrong, 1);
      expect(resumed.current, isNotNull);
    });

    test('إنهاء المراجعة يمسح الجلسة المحفوظة', () async {
      await ctrl().start(mode: ReviewMode.random);
      ctrl().answer(read().current!.correctIndex);
      await Future<void>.delayed(Duration.zero);
      expect(await SessionStore.instance.read(), isNotNull);

      await ctrl().finish();
      expect(await SessionStore.instance.read(), isNull);
    });
  });
}
