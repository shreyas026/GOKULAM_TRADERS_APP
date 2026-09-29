import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gokulam_app/screens/auth/login_screen.dart';
import 'package:gokulam_app/screens/auth/register_screen.dart';

void main() {
  testWidgets('login screen renders its form', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('register screen blocks a username containing spaces', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterScreen())),
    );
    await tester.pump(const Duration(seconds: 1));

    final submit = find.widgetWithText(ElevatedButton, 'Create Account');
    expect(submit, findsOneWidget);
    expect(find.text('Username'), findsOneWidget);

    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Required'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, 'Shreyas S');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.textContaining('no spaces'), findsOneWidget);
  });
}
