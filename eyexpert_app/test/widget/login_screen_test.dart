import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drishti_app/features/auth/login_screen.dart';
import 'package:drishti_app/features/auth/phc_login_screen.dart';
import 'package:drishti_app/features/auth/clinician_login_screen.dart';
import 'package:drishti_app/features/auth/widgets/role_selection_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen renders role selection and dynamic context without demo UI', (WidgetTester tester) async {
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

    // Verify role cards exist
    expect(find.byType(RoleSelectionCard), findsNWidgets(2));
    expect(find.text('PHC / Health Worker'), findsWidgets);
    expect(find.text('Ophthalmologist'), findsWidgets);

    // Verify SIH badge
    expect(find.text('SIH 2026 • PS-26038'), findsWidgets);

    // Verify NO demo mode or demo buttons exist
    expect(find.text('DEMO ENVIRONMENT'), findsNothing);
    expect(find.text('Demo PHC Worker'), findsNothing);
    expect(find.text('Demo Clinician'), findsNothing);

    // Tap on Ophthalmologist card
    await tester.tap(find.text('Ophthalmologist').first);
    await tester.pump();

    // Verify Medical Registration ID field appears for clinician
    expect(find.text('MEDICAL REGISTRATION ID (OPTIONAL)'), findsOneWidget);
  });

  testWidgets('PhcLoginScreen renders dedicated PHC interface', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PhcLoginScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('PHC WORKSTATION'), findsOneWidget);
    expect(find.text('REGISTERED HEALTH WORKER EMAIL / ID'), findsOneWidget);
    expect(find.text('PRIMARY HEALTH CENTRE CLEARANCE'), findsOneWidget);
    expect(find.text('Sign In to PHC Workstation'), findsOneWidget);
    expect(find.text('DEMO ENVIRONMENT'), findsNothing);
  });

  testWidgets('ClinicianLoginScreen renders dedicated Ophthalmologist interface', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ClinicianLoginScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('OPHTHALMOLOGIST PORTAL'), findsOneWidget);
    expect(find.text('PROFESSIONAL EMAIL / CLINICIAN ID'), findsOneWidget);
    expect(find.text('SPECIALIST CLINICAL WORKSPACE'), findsOneWidget);
    expect(find.text('Sign In to Specialist Review Portal'), findsOneWidget);
    expect(find.text('DEMO ENVIRONMENT'), findsNothing);
  });
}
