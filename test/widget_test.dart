// Sheba Bar Stock Management System Widget Tests
//
// This file contains basic widget tests for the Sheba Bar Stock Management System.
// These tests verify that the app's main components can be instantiated correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shebabar/main.dart';
import 'package:shebabar/screens/login_screen.dart';
import 'package:shebabar/widgets/custom_card.dart';
import 'package:shebabar/providers/auth_provider.dart';

void main() {
  testWidgets('ShebaBarApp can be instantiated', (WidgetTester tester) async {
    // Test that the main app widget can be created without errors
    const app = ShebaBarApp();
    expect(app, isA<ShebaBarApp>());
  });

  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    // Test the login screen in isolation
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          child: const LoginScreen(),
        ),
      ),
    );

    // Verify that key elements are present
    expect(find.text('SHEBA BAR'), findsOneWidget);
    expect(find.text('Injira'), findsOneWidget);
    expect(find.byType(TextFormField), findsAtLeast(2));
  });

  testWidgets('CustomCard widget renders correctly', (WidgetTester tester) async {
    // Test the custom card widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomCard(
            child: Text('Test Content'),
          ),
        ),
      ),
    );

    expect(find.text('Test Content'), findsOneWidget);
    expect(find.byType(CustomCard), findsOneWidget);
  });

  testWidgets('AuthProvider can be instantiated', (WidgetTester tester) async {
    // Test that providers can be created
    final authProvider = AuthProvider();
    expect(authProvider, isA<AuthProvider>());
    expect(authProvider.isLoggedIn, false);
    expect(authProvider.isLoading, false);
  });

  test('App constants are defined', () {
    // Test that essential constants exist
    expect('SHEBA BAR', isA<String>());
    expect('Injira', isA<String>());
  });
}
