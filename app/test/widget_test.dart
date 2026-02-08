// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_care_nk/main.dart';
import 'package:my_care_nk/features/home/presentation/pages/home_page.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyCareNKApp());

    // Verify that HomePage is present
    expect(find.byType(HomePage), findsOneWidget);

    // Verify that the title 'MyCareNK' is not necessarily visible text but verify some known text
    expect(find.text('หน้าหลัก'), findsOneWidget); // Bottom nav item
    expect(find.text('1669'), findsOneWidget); // Emergency button
  });
}
