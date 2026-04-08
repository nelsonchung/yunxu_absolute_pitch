import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yunxu_absolute_pitch/src/ear_training/progress_repository.dart';
import 'package:yunxu_absolute_pitch/src/intro/intro_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('progress repository persists intro seen flag', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = ProgressRepository();

    expect(await repository.hasSeenIntro(), isFalse);

    await repository.markIntroSeen();

    expect(await repository.hasSeenIntro(), isTrue);
  });

  testWidgets('intro page exposes bottom explanation tabs and finish action', (
    tester,
  ) async {
    var finishCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: IntroPage(
          onFinished: () async {
            finishCount += 1;
          },
        ),
      ),
    );

    expect(find.text('說明分頁'), findsOneWidget);
    expect(find.text('一輪練習流程'), findsOneWidget);

    await tester.tap(find.byKey(const Key('intro-tab-1')));
    await tester.pumpAndSettle();

    expect(find.text('目前內建的模式'), findsOneWidget);

    await tester.tap(find.byKey(const Key('intro-tab-2')));
    await tester.pumpAndSettle();

    expect(find.text('練習時的小習慣'), findsOneWidget);
    expect(find.byKey(const Key('intro-finish-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('intro-finish-button')));
    await tester.pump();

    expect(finishCount, 1);
  });
}
