// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:cuentas_claras/main.dart';

void main() {
  testWidgets('renders the application splash screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildApp());

    // Wait for the splash screen timer to finish
    await tester.pumpAndSettle();

    // After the splash screen, the app should navigate to the login screen
    // because the user is not logged in.
    expect(find.text('¡Bienvenido!'), findsOneWidget);
  });
}
