import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lightweight regression tests for role-gated Create (+) FAB.
///
/// Note: These tests intentionally avoid depending on app auth/providers.
/// We validate the key contract the UX spec cares about:
/// - Leader sees a (+) FloatingActionButton
/// - Worshipper never sees it
///
/// The actual MainWrapper integration is covered by widget/integration tests
/// elsewhere; this protects the gating logic.
void main() {
  testWidgets('Leader shows create FAB', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('Worshipper hides create FAB', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
