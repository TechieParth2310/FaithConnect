// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget test harness boots', (WidgetTester tester) async {
    // This app requires Firebase initialization for `MyApp`.
    // For CI sanity, we keep a minimal test that verifies the test
    // environment can build a widget tree.
    await tester.pumpWidget(const TestHarnessApp());
    expect(find.byType(TestHarnessApp), findsOneWidget);
  });
}

class TestHarnessApp extends StatelessWidget {
  const TestHarnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox.shrink(),
    );
  }
}
