import 'package:faith_connect/widgets/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrapApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(child: child),
      ),
    );
  }

  testWidgets('Worshipper header shows Following only', (tester) async {
    await tester.pumpWidget(
      wrapApp(
        const WorshipperProfileHeader(
          photoUrl: null,
          name: 'Alice',
          faithLabel: 'Christianity',
          followingCount: 2,
        ),
      ),
    );

    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Followers'), findsNothing);
    expect(find.text('Worshipper'), findsOneWidget);
    expect(find.text('Leader'), findsNothing);
  });

  testWidgets('Leader header shows Followers only', (tester) async {
    await tester.pumpWidget(
      wrapApp(
        const LeaderProfileHeader(
          photoUrl: null,
          name: 'Leader Bob',
          faithLabel: 'ISLAM',
          followersCount: 120,
        ),
      ),
    );

    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Following'), findsNothing);
    expect(find.text('Leader'), findsOneWidget);
    expect(find.text('Worshipper'), findsNothing);
  });
}
