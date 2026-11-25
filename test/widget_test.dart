import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishtriage_app/account_check_screen.dart';
import 'package:phishtriage_app/home_screen.dart';
import 'package:phishtriage_app/main.dart';
import 'package:phishtriage_app/message_scanner_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'seenOnboarding': true}));

  testWidgets('Splash leads to home with all main actions', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Check a Number'), findsOneWidget);
    expect(find.text('Check a Bank Account'), findsOneWidget);
    expect(find.text('Scan Message'), findsOneWidget);
    await tester.scrollUntilVisible(find.text("I've Been Scammed"), 200);
    expect(find.text("I've Been Scammed"), findsOneWidget);
  });

  testWidgets('Scanner asks for text when empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MessageScannerScreen()));
    await tester.tap(find.text('Scan message'));
    await tester.pump();
    expect(find.text('Paste a suspicious message or link to scan.'), findsOneWidget);
  });

  testWidgets('Account check validates 10 digits', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AccountCheckScreen()));
    await tester.enterText(find.byType(TextField).first, '12345');
    await tester.tap(find.text('Check account'));
    await tester.pump();
    expect(find.text('Enter the 10-digit account number.'), findsOneWidget);
  });
}
