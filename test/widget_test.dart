// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezviz_example_app/main.dart';
import 'package:ezviz_example_app/repositories/ezviz_repository.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Create a mock repository for testing
    final ezvizRepository = EzvizRepository();

    // Initialize repository with test credentials
    await ezvizRepository.initialize(
      appKey: 'test_app_key',
      appSecret: 'test_app_secret',
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(ezvizRepository: ezvizRepository));

    // Verify that our app starts with a configuration error or auth page
    // Since we're using test credentials, it should show an error or auth page
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
