import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toda_go/main.dart';
import 'package:toda_go/screens/login_screen.dart';

void main() {
  testWidgets('Login smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(home: LoginScreen()));

    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });
}
