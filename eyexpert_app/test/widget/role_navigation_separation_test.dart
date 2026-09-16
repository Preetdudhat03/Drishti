import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drishti_app/data/models/user_model.dart';
import 'package:drishti_app/features/auth/auth_provider.dart';
import 'package:drishti_app/data/services/auth_service.dart';
import 'package:drishti_app/shared/widgets/responsive_scaffold.dart';
import 'package:drishti_app/features/dashboard/ophthalmologist_dashboard.dart';
import 'package:drishti_app/features/dashboard/health_worker_dashboard.dart';
import 'package:drishti_app/core/network/connection_provider.dart';
import 'package:drishti_app/main.dart';

void main() {
  group('Role-Based Navigation & UI Separation Tests', () {
    const ophthalmologistUser = UserModel(
      id: 'USR-DOC-001',
      name: 'Dr. Sharma',
      email: 'clinician@drishti.org',
      role: UserRole.clinician,
      organization: 'District Eye Hospital',
      facilityId: 'DISTRICT-EYE-HOSPITAL',
      professionalId: 'MCI-88291',
    );

    const healthWorkerUser = UserModel(
      id: 'USR-HW-001',
      name: 'Sunita Sharma',
      email: 'healthworker@drishti.org',
      role: UserRole.healthWorker,
      organization: 'PHC Ramgarh',
      facilityId: 'PHC-RAMGARH-01',
    );

    const unknownUser = UserModel(
      id: 'USR-UNKN-999',
      name: 'Unverified Guest',
      email: 'guest@unknown.org',
      role: UserRole.unknown,
      organization: 'Unknown Org',
    );

    testWidgets('Ophthalmologist ResponsiveScaffold contains ZERO intake/screening creation triggers', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionProvider.overrideWith((ref) => ConnectionNotifier(enablePeriodicTimer: false)),
          ],
          child: MaterialApp(
            home: ResponsiveScaffold(
              currentIndex: 0,
              onNavigationIndexChanged: (_) {},
              title: 'Ophthalmologist Workspace',
              currentUser: ophthalmologistUser,
              body: const SizedBox(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify permitted Ophthalmologist navigation items
      expect(find.text('Review Queue'), findsWidgets);
      expect(find.text('All Cases'), findsWidgets);
      expect(find.text('Overview'), findsWidgets);
      expect(find.text('Reports'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);

      // Verify strictly PROHIBITED field intake / screening creation triggers do NOT exist anywhere
      expect(find.text('New Intake'), findsNothing);
      expect(find.text('New Screening'), findsNothing);
      expect(find.text('Start Screening'), findsNothing);
      expect(find.text('Add Patient'), findsNothing);
      expect(find.text('Capture'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('PHC Health Worker ResponsiveScaffold retains New Intake navigation item', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectionProvider.overrideWith((ref) => ConnectionNotifier(enablePeriodicTimer: false)),
          ],
          child: MaterialApp(
            home: ResponsiveScaffold(
              currentIndex: 0,
              onNavigationIndexChanged: (_) {},
              title: 'PHC Screening Workspace',
              currentUser: healthWorkerUser,
              body: HealthWorkerDashboard(
                onStartScreening: () {},
                onViewCases: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify permitted PHC Worker intake items
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('New Intake'), findsWidgets);
      expect(find.text('+ START NEW SCREENING'), findsOneWidget);

      // Verify specialist review queue is NOT on PHC primary nav
      expect(find.text('Review Queue'), findsNothing);
    });

    testWidgets('OphthalmologistDashboard has NO screening creation buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier(AuthService());
              notifier.state = const AuthState(
                user: ophthalmologistUser,
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OphthalmologistDashboard(
                onOpenReviewQueue: () {},
                onViewCases: () {},
                onViewSystemStatus: () {},
                onSelectCase: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify primary CTA is reviewing cases
      expect(find.textContaining('REVIEW NEXT CASE'), findsOneWidget);
      expect(find.textContaining('Open Full Clinical Review Queue'), findsOneWidget);

      // Verify screening creation does NOT exist
      expect(find.text('Start New Screening'), findsNothing);
      expect(find.text('+ START NEW SCREENING'), findsNothing);
      expect(find.text('New Intake'), findsNothing);
      expect(find.text('New Screening'), findsNothing);
    });

    testWidgets('RootScreen renders Access Denied screen for UserRole.unknown (Fail Closed)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier(AuthService());
              notifier.state = const AuthState(
                user: unknownUser,
              );
              return notifier;
            }),
            connectionProvider.overrideWith((ref) => ConnectionNotifier(enablePeriodicTimer: false)),
          ],
          child: const MaterialApp(
            home: RootScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify Access Denied banner is displayed
      expect(find.text('Access Denied — Unrecognized Role'), findsOneWidget);
      expect(find.text('Sign Out & Return to Login'), findsOneWidget);

      // Verify neither PHC nor Clinician workspace is rendered
      expect(find.text('+ START NEW SCREENING'), findsNothing);
      expect(find.text('Priority Review Queue'), findsNothing);
    });

    testWidgets('RootScreen renders PHC Screening Workspace for Health Worker', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier(AuthService());
              notifier.state = const AuthState(
                user: healthWorkerUser,
              );
              return notifier;
            }),
            connectionProvider.overrideWith((ref) => ConnectionNotifier(enablePeriodicTimer: false)),
          ],
          child: const MaterialApp(
            home: RootScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify PHC primary actions are present
      expect(find.text('+ START NEW SCREENING'), findsOneWidget);
      expect(find.text('Screening Dashboard'), findsWidgets);

      // Verify Clinician review queue is absent
      expect(find.text('Priority Review Queue'), findsNothing);
    });

    testWidgets('RootScreen renders Ophthalmologist Workspace for Clinician', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier(AuthService());
              notifier.state = const AuthState(
                user: ophthalmologistUser,
              );
              return notifier;
            }),
            connectionProvider.overrideWith((ref) => ConnectionNotifier(enablePeriodicTimer: false)),
          ],
          child: const MaterialApp(
            home: RootScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify Clinician workspace header is present
      expect(find.text('Priority Review Queue'), findsWidgets);

      // Verify PHC new screening button is NOT present
      expect(find.text('+ START NEW SCREENING'), findsNothing);
    });
  });
}
