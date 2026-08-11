import 'package:flutter/material.dart';
import 'package:flutter_shopowner/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ShopOwner Portal loads Overview screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ThiraaShopOwner());

    // Verify the Overview screen text shows up on load.
    expect(find.text('Overview — build your UI here'), findsOneWidget);
  });
}
