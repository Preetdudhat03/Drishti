import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drishti_app/features/auth/login_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Unified LoginScreen renders clean work email, password, and sign in button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify fields
    expect(find.text('WORK EMAIL / USERNAME'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('CLINICAL AI WORKSTATION'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);

    // Verify NO role toggles or demo buttons exist
    expect(find.text('DEMO ENVIRONMENT'), findsNothing);
    expect(find.text('Demo PHC Worker'), findsNothing);
    expect(find.text('Demo Clinician'), findsNothing);
    expect(find.text('PHC / Health Worker'), findsNothing);
    expect(find.text('Ophthalmologist'), findsNothing);
  });
}
