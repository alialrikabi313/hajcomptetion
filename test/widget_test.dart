import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_levels_clean/core/constants.dart';
import 'package:quiz_levels_clean/core/progress_service.dart';
import 'package:quiz_levels_clean/core/session_store.dart';
import 'package:quiz_levels_clean/core/topic_names.dart';
import 'package:quiz_levels_clean/data/datasources/local_questions_data_source.dart';
import 'package:quiz_levels_clean/data/repositories/quiz_repository_impl.dart';
import 'package:quiz_levels_clean/presentation/providers/quiz_providers.dart';
import 'package:quiz_levels_clean/presentation/providers/review_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    K.soundEnabled = false;
    K.showTimer = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('أسماء المواضيع', () {
    test('تُختصر إلى اسم الموضوع فقط', () {
      expect(TopicNames.clean('جميع اسئلة الطواف'), 'الطواف');
      expect(TopicNames.clean('جميع اسئلة السعي'), 'السعي');
      expect(TopicNames.clean('اسئلة التقصير'), 'التقصير');
      expect(TopicNames.clean('اسئلة صلاة الطواف'), 'صلاة الطواف');
      expect(TopicNames.clean('اخر اسئلة الذبح'), 'الذبح');
      expect(TopicNames.clean('اسئلة الارشاد بخصوص المخيط'), 'المخيط');
      expect(TopicNames.clean('اسئلة الارشاد حول مزدلفة'), 'مزدلفة');
      expect(TopicNames.clean('اسئلة الارشاد حول موقف عرفات'), 'موقف عرفات');
      expect(TopicNames.clean('اسئلة الارشاد حول احرام الحج'), 'احرام الحج');
      expect(
        TopicNames.clean('اسئلة الارشاد حول رمي جمرة العقبة'),
        'رمي جمرة العقبة',
      );
      expect(
        TopicNames.clean('اسئلة الارشاد حول الذبح من مسالة 384 الى 395'),
        'الذبح',
      );
    });

    test('كل مواضيع الملف أسماؤها قصيرة وبلا مقدمات', () async {
      final repo = QuizRepositoryImpl(LocalQuestionsDataSourceImpl());
      final topics = await repo.getTopics();

      for (final t in topics) {
        expect(t.name.startsWith('اسئلة'), isFalse);
        expect(t.name.startsWith('جميع'), isFalse);
        expect(t.name.startsWith('اخر'), isFalse);
        expect(t.name.contains('مسالة'), isFalse);
        expect(t.name.split(' ').length, lessThanOrEqualTo(3));
      }

      // الموضوعان الخاصان بالذبح يندمجان تحت اسم واحد
      expect(topics.where((t) => t.name == 'الذبح').length, 1);

      // المواضيع المعتمدة في التطبيق
      expect(topics.length, 17);
      expect(
        topics.map((t) => t.name).toSet(),
        {
          'الطواف',
          'السعي',
          'صلاة الطواف',
          'الذبح',
          'التقصير',
          'رمي جمرة العقبة',
          'مزدلفة',
          'موقف عرفات',
          'احرام الحج',
          'المخيط',
          'محرمات الإحرام',
          'حج التمتع وأحكامه',
          'العمرة المفردة',
          'الاستطاعة ووجوب الحج',
          'المبيت في منى',
          'أحكام الحائض والمستحاضة',
          'النيابة في الحج',
        },
      );
    });
    test('ترتيب عرض المواضيع يتبع ترتيب أعمال الحج', () async {
      final repo = QuizRepositoryImpl(LocalQuestionsDataSourceImpl());
      final topics = await repo.getTopics();

      expect(topics.map((t) => t.name).toList(), TopicNames.order);
    });
  });

  group('مصدر الأسئلة', () {
    test('يقرأ الأسئلة من haj_questions.json ويصنّفها حسب الموضوع', () async {
      final repo = QuizRepositoryImpl(LocalQuestionsDataSourceImpl());

      final questions = await repo.getAllQuestions();
      expect(questions.length, greaterThan(1100));

      // لا سؤال بلا موضوع بعد اعتماد التصنيف
      expect(questions.where((q) => q.topic.isEmpty), isEmpty);

      // أسئلة الحائض والمستحاضة مجموعة في موضوعها ولو كان موضوعها الأساسي غيره
      final hayd = questions
          .where((q) => q.topics.contains('أحكام الحائض والمستحاضة'))
          .length;
      expect(hayd, greaterThan(90));
      expect(
        questions.where((q) => q.topics.length > 1).length,
        greaterThan(80),
      );

      for (final q in questions) {
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.options.contains(q.correctAnswer), isTrue);
        expect(q.correctIndex, greaterThanOrEqualTo(0));
      }

      // أسئلة الملف الأول لها مستند جواب
      final withReference = questions.where((q) => q.hasReference).length;
      expect(withReference, greaterThan(900));

      final topics = await repo.getTopics();
      expect(topics.length, greaterThan(1));
      expect(topics.every((t) => t.name.isNotEmpty), isTrue);
      // مجموع أسئلة المواضيع = مجموع انتماءات الأسئلة (سؤال قد ينتمي لموضوعين)
      expect(
        topics.fold<int>(0, (sum, t) => sum + t.questionCount),
        questions.fold<int>(0, (sum, q) => sum + q.topics.length),
      );

      final first = await repo.getQuestionsByTopic(topics.first.name);
      expect(first.length, topics.first.questionCount);
      expect(first.every((q) => q.topic == topics.first.name), isTrue);
    });
  });


  group('سلامة نقل الأسئلة من ملفات المصدر', () {
    test('كل سؤال له خيارات وجواب من ضمنها', () async {
      final repo = QuizRepositoryImpl(LocalQuestionsDataSourceImpl());
      final questions = await repo.getAllQuestions();

      expect(questions.length, greaterThanOrEqualTo(1150));
      for (final q in questions) {
        expect(q.question.trim(), isNotEmpty);
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.options.contains(q.correctAnswer), isTrue,
            reason: 'الجواب الصحيح خارج الخيارات: ${q.question}');
        expect(q.options.toSet().length, q.options.length,
            reason: 'خيارات مكررة في: ${q.question}');
      }

      // أسئلة ملف المستندات لها مستند جواب (عدا ما لم يذكره المصدر)
      final withRef = questions.where((q) => q.hasReference).length;
      expect(withRef, greaterThanOrEqualTo(930));
    });
  });

  group('أرقام بنك الأسئلة', () {
    test('أرقام صفحة «حول التطبيق» مطابقة للملفات', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final bank = await container.read(bankStatsProvider.future);
      final questions = await container.read(allQuestionsProvider.future);

      expect(bank.total, questions.length);
      expect(bank.withReference + bank.withoutReference, bank.total);
      expect(bank.withReference, questions.where((q) => q.hasReference).length);
      expect(bank.withoutReference, greaterThan(0));
      expect(bank.topics, 17);
    });
  });

  group('جلسة المراجعة', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    ReviewState read() => container.read(reviewControllerProvider);
    ReviewController ctrl() =>
        container.read(reviewControllerProvider.notifier);

    test('المراجعة العشوائية تأخذ من جميع المواضيع', () async {
      await ctrl().start(mode: ReviewMode.random);

      final all = await container.read(getQuestionsUseCaseProvider).all();
      expect(read().poolSize, all.length);
      expect(read().mode, ReviewMode.random);
      expect(read().current, isNotNull);
    });

    test('المراجعة حسب الموضوع تقتصر على أسئلة الموضوع', () async {
      final topics = await container.read(getQuestionsUseCaseProvider).topics();
      final target = topics.first;

      await ctrl().start(mode: ReviewMode.topic, topic: target.name);

      expect(read().title, target.name);
      expect(read().poolSize, target.questionCount);
      expect(read().current!.topic, target.name);
    });

    test('احتساب الإجابات الصحيحة والخاطئة والسلسلة', () async {
      await ctrl().start(mode: ReviewMode.random);

      // إجابة صحيحة
      ctrl().answer(read().current!.correctIndex);
      expect(read().isAnswered, isTrue);
      expect(read().shown, 1);
      expect(read().correct, 1);
      expect(read().streak, 1);

      // الإجابة مرة ثانية على نفس السؤال لا تُحتسب
      ctrl().answer(read().current!.correctIndex);
      expect(read().shown, 1);

      ctrl().next();
      expect(read().isAnswered, isFalse);
      expect(read().selectedIndex, isNull);
      expect(read().referenceShown, isFalse);

      // إجابة خاطئة
      final q = read().current!;
      ctrl().answer((q.correctIndex + 1) % q.options.length);
      expect(read().shown, 2);
      expect(read().correct, 1);
      expect(read().wrong, 1);
      expect(read().streak, 0);
      expect(read().bestStreak, 1);
      expect(read().accuracyPercent, 50);
    });

    test('ترتيب الخيارات يبقى كما في الملف', () async {
      await ctrl().start(mode: ReviewMode.random);

      for (var i = 0; i < 25; i++) {
        final q = read().current!;
        expect(q.options, orderedEquals(q.source.options));
        expect(q.options[q.correctIndex], q.source.correctAnswer);
        ctrl().next();
      }
    });

    test('ترتيب الأسئلة يختلف بين جلسة وأخرى', () async {
      Future<List<String>> firstTen() async {
        await ctrl().start(mode: ReviewMode.random);
        final texts = <String>[];
        for (var i = 0; i < 10; i++) {
          texts.add(read().current!.text);
          ctrl().next();
        }
        return texts;
      }

      final a = await firstTen();
      final b = await firstTen();
      expect(a, isNot(orderedEquals(b)));
    });

    test('إحصائيات المواضيع لا تتأثر بالمراجعة العشوائية', () async {
      final topics = await container.read(getQuestionsUseCaseProvider).topics();

      await ctrl().start(mode: ReviewMode.random);
      for (var i = 0; i < 5; i++) {
        ctrl().answer(read().current!.correctIndex);
        ctrl().next();
      }
      await Future<void>.delayed(Duration.zero);

      final perTopic = await ProgressService.instance.forTopics(
        topics.map((t) => t.name).toList(),
      );
      expect(perTopic.values.every((s) => s.answered == 0), isTrue);

      // بينما مراجعة الموضوع تُحتسب
      await ctrl().start(mode: ReviewMode.topic, topic: topics.first.name);
      ctrl().answer(read().current!.correctIndex);
      await Future<void>.delayed(Duration.zero);

      final after = await ProgressService.instance.forTopic(topics.first.name);
      expect(after.answered, 1);
      expect(after.correct, 1);
    });

    test('تنتهي الجلسة بنفاد أسئلة الموضوع ولا تتكرر', () async {
      final topics = await container.read(getQuestionsUseCaseProvider).topics();
      final smallest = topics.reduce(
        (a, b) => a.questionCount <= b.questionCount ? a : b,
      );

      await ctrl().start(mode: ReviewMode.topic, topic: smallest.name);

      final seen = <int>{};
      for (var i = 0; i < smallest.questionCount; i++) {
        expect(read().finished, isFalse);
        seen.add(read().current!.source.id);
        ctrl().answer(read().current!.correctIndex);
        ctrl().next();
      }

      // لا سؤال يتكرر داخل الجلسة، وتنتهي المراجعة عند آخر سؤال
      expect(seen.length, smallest.questionCount);
      expect(read().finished, isTrue);
      expect(read().completedAll, isTrue);
      expect(read().shown, smallest.questionCount);
      expect(read().correct, smallest.questionCount);
      await Future<void>.delayed(Duration.zero);
      expect(await SessionStore.instance.read(), isNull);
    });

    test('إنهاء المراجعة يحفظ الجلسة ويحافظ على الإحصائيات', () async {
      await ctrl().start(mode: ReviewMode.random);
      ctrl().answer(read().current!.correctIndex);
      await ctrl().finish();

      expect(read().finished, isTrue);
      expect(read().shown, 1);
      expect(read().correct, 1);
    });
  });
}
