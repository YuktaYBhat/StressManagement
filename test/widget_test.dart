import 'package:flutter_test/flutter_test.dart';

import 'package:apps/app/stress_sense_app.dart';

void main() {
  testWidgets('StressSense login screen smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StressSenseApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Welcome to StressSense'), findsOneWidget);

    final hasLoginButton = find
        .text('Login')
        .evaluate()
        .isNotEmpty;
    final hasHomeTitle = find.text('Home').evaluate().isNotEmpty;
    expect(hasLoginButton || hasHomeTitle, isTrue);
  });
}
