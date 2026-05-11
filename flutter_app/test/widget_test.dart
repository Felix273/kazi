import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KaziApp());
    // We expect a splash screen or loading, and then it might have some timers
    // We can't use pumpAndSettle if there are infinite or long timers
    await tester.pump(const Duration(seconds: 1));

    // Basic check to see if the app builds
    expect(find.byType(MaterialApp), findsOneWidget);

    // To satisfy the pending timer check in some environments
    await tester.pumpAndSettle(const Duration(seconds: 6));
  });
}
