// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:krx_stock_analysis/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KRXStockApp()));
    await tester.pump();

    // Verify app renders with KRX branding
    expect(find.text('KRX'), findsOneWidget);
    expect(find.text('KRX Analysis'), findsOneWidget);
  });
}
