import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drishti_app/data/models/user_model.dart';
import 'package:drishti_app/features/auth/auth_provider.dart';
import 'package:drishti_app/shared/widgets/responsive_scaffold.dart';
import 'package:drishti_app/features/dashboard/ophthalmologist_dashboard.dart';
import 'package:drishti_app/features/dashboard/health_worker_dashboard.dart';
import 'package:drishti_app/features/queue/case_queue_screen.dart';

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

    testWidgets('Ophthalmologist ResponsiveScaffold contains ZERO intake/screening creation triggers', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ResponsiveScaffold(
              currentIndex: 0,
              onNavigationIndexChanged: (_) {},
              title: 'Ophthalmologist Workspace',
              currentUser: ophthalmologistUser,
              body: CaseQueueScreen(onSelectCase: (_) {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

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

      await tester.pumpAndSettle();

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
            authProvider.overrideWith((ref) => AuthNotifier(null)..state = const AuthState(
              isAuthenticated: true,
              user: ophthalmologistUser,
            )),
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

      await tester.pumpAndSettle();

      // Verify primary CTA is reviewing cases
      expect(find.textContaining('REVIEW NEXT CASE'), findsOneWidget);
      expect(find.textContaining('Open Full Clinical Review Queue'), findsOneWidget);

      // Verify screening creation does NOT exist
      expect(find.text('Start New Screening'), findsNothing);
      expect(find.text('+ START NEW SCREENING'), findsNothing);
      expect(find.text('New Intake'), findsNothing);
      expect(find.text('New Screening'), findsNothing);
    });
  });
}
