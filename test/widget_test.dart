// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_app/main.dart';

void main() {
  testWidgets('Login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const TaxtaApp());

    expect(find.text('Taxta do‘koni'), findsOneWidget);
    expect(find.text('Kirish'), findsAtLeastNWidgets(1));
    expect(find.text('Ishchi'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('Dashboard opens report screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TaxtaApp());

    await tester.tap(find.text('Kirish').last);
    await tester.pumpAndSettle();

    expect(find.text('Tezkor amallar'), findsOneWidget);
    expect(find.text('Hisobot'), findsOneWidget);

    await tester.tap(find.text('Hisobot'));
    await tester.pumpAndSettle();

    expect(find.text('Bugungi hisobot'), findsOneWidget);
    expect(find.text('AI maslahat'), findsOneWidget);
  });
}
