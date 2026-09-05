import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drainage/main.dart';
import 'package:drainage/screens/login_screen.dart';

void main() {
  testWidgets('Login smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(home: LoginScreen()));

    expect(find.text('DrainAlert'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });
}
