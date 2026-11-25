import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phishtriage_app/account_check_screen.dart';
import 'package:phishtriage_app/blocklist_service.dart';
import 'package:phishtriage_app/call_protection_screen.dart';
import 'package:phishtriage_app/official_directory_screen.dart';
import 'package:phishtriage_app/feedback_card.dart';
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

  testWidgets('Feedback card offers correct/wrong answers and opt-in sharing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FeedbackCard(scanId: 'x', message: 'hello', flagged: true)),
    ));
    expect(find.text('Was this result right?'), findsOneWidget);
    expect(find.text('No, it is safe'), findsOneWidget);
    final box = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(box.value, isFalse); // sharing is off unless the user opts in
  });

  test('Offline list normalises Nigerian numbers like the server', () {
    expect(BlocklistService.normalize('0803 123 4567'), '+2348031234567');
    expect(BlocklistService.normalize('+234 803 123 4567'), '+2348031234567');
    expect(BlocklistService.normalize('8031234567'), '+2348031234567');
    expect(BlocklistService.normalize('12345'), isNull);
  });

  testWidgets('Call protection explains when the phone cannot support it', (tester) async {
    // No native side in tests, so the screen must fall back gracefully.
    await tester.pumpWidget(const MaterialApp(home: CallProtectionScreen()));
    // Platform-channel calls complete on the real event loop, not the test's fake clock.
    // Each awaited channel call resumes between real and fake time, so alternate a few times.
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    expect(find.textContaining('Android 10 or newer'), findsOneWidget);
  });

  testWidgets('Official directory shows the check box', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OfficialDirectoryScreen()));
    await tester.pump();
    expect(find.text('Is this really my bank?'), findsOneWidget);
  });
}
