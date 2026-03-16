import 'package:flutter_test/flutter_test.dart';
import 'package:etoda_nagcarlan/main.dart'; // Ensure this matches your project name

void main() {
  testWidgets('Landing Page Smoke Test', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    // Ensure 'EtodaApp' matches the class name in your main.dart
    await tester.pumpWidget(const EtodaApp());

    // 2. Verify that our branding exists.
    expect(find.text('eTODA'), findsOneWidget);
    expect(find.text('NAGCARLAN'), findsOneWidget);

    // 3. Verify that the Role Selection buttons are present.
    expect(find.text('PASSENGER'), findsOneWidget);
    expect(find.text('DRIVER'), findsOneWidget);
  });
}