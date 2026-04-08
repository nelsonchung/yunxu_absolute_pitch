import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yunxu_absolute_pitch/src/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch shows intro and home can reopen the guide', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EarTrainingApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('使用介紹'), findsOneWidget);
    expect(find.text('說明分頁'), findsOneWidget);

    await tester.tap(find.byKey(const Key('intro-dismiss-button')));
    await tester.pumpAndSettle();

    expect(find.text('Yunxu Ear Lab'), findsOneWidget);
    expect(find.byTooltip('查看介紹'), findsOneWidget);
    expect(find.text('版本宣告'), findsOneWidget);

    await tester.tap(find.text('版本宣告'));
    await tester.pumpAndSettle();

    expect(find.text('本版內容'), findsOneWidget);
    expect(find.text('音檔來源'), findsOneWidget);
    expect(find.textContaining('MIT License'), findsOneWidget);
    expect(find.textContaining('完整宣告版本：'), findsOneWidget);

    await tester.tap(find.text('練習'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('查看介紹'));
    await tester.pumpAndSettle();

    expect(find.text('使用介紹'), findsOneWidget);
    expect(find.text('說明分頁'), findsOneWidget);
  });
}
