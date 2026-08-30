import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/permissions/permission_service.dart';
import 'data/models/user_model.dart';
import 'data/models/screening_case_model.dart';
import 'data/services/supabase_service.dart';
import 'shared/widgets/responsive_scaffold.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/dashboard/health_worker_dashboard.dart';
import 'features/dashboard/ophthalmologist_dashboard.dart';
import 'features/screening/patient_intake_screen.dart';
import 'features/screening/fundus_capture_screen.dart';
import 'features/quality/image_quality_screen.dart';
import 'features/processing/clinical_processing_screen.dart';
import 'features/results/ai_result_screen.dart';
import 'features/explainability/explainability_screen.dart';
import 'features/reports/screening_report_screen.dart';
import 'features/review/clinician_review_screen.dart';
import 'features/queue/case_queue_screen.dart';
import 'features/offline/sync_manager_screen.dart';
import 'features/system_status/system_status_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/screening/screening_session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase Data/Platform Layer
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: DrishtiApp(),
    ),
  );
}

class DrishtiApp extends ConsumerWidget {
  const DrishtiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '${AppConstants.appName} (${AppConstants.appHindiName})',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clinicalTheme,
      home: const RootScreen(),
    );
  }
}

class RootScreen extends ConsumerStatefulWidget {
  const RootScreen({super.key});

  @override
  ConsumerState<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends ConsumerState<RootScreen> {
  int _navIndex = 0;
  bool _showOnboarding = false;

  // Screening sub-flow state for Health Worker
  // 0: Intake, 1: Capture, 2: Quality, 3: Processing, 4: Result, 5: Explainability, 6: Report
  int _screeningStep = 0;

  // Case details overlay
  ScreeningCaseModel? _activeCaseReview;
  ScreeningCaseModel? _activeReportView;

  void _resetScreeningFlow() {
    setState(() {
      _screeningStep = 0;
    });
    ref.read(screeningSessionProvider.notifier).resetSession();
  }

  Widget _buildAccessRestrictedBanner(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gpp_bad_outlined, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 16),
            const Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This workspace is available only to authorized ophthalmologists.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() => _activeCaseReview = null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Return to Workspace'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // 1. If not authenticated, display Onboarding or LoginScreen
    if (!authState.isAuthenticated || user == null) {
      if (_showOnboarding) {
        return OnboardingScreen(
          onCancelToLogin: () => setState(() => _showOnboarding = false),
        );
      }
      return LoginScreen(
        onOpenOnboarding: () => setState(() => _showOnboarding = true),
      );
    }

    final permissions = PermissionService(user);

    // 2. Active Overlays (Review / Report)
    if (_activeCaseReview != null) {
      if (!permissions.canValidateAi) {
        return Scaffold(
          appBar: AppBar(title: const Text('Access Control')),
          body: _buildAccessRestrictedBanner(context),
        );
      }
      return ClinicianReviewScreen(
        screeningCase: _activeCaseReview!,
        onReviewSubmitted: () => setState(() => _activeCaseReview = null),
        onBack: () => setState(() => _activeCaseReview = null),
      );
    }

    if (_activeReportView != null) {
      return ScreeningReportScreen(
        screeningCase: _activeReportView!,
        onBack: () => setState(() => _activeReportView = null),
      );
    }

    // -------------------------------------------------------------
    // 3. OPHTHALMOLOGIST WORKSPACE
    // -------------------------------------------------------------
    if (user.role == UserRole.clinician) {
      Widget body;
      String title = 'Ophthalmologist Workspace';

      switch (_navIndex) {
        case 0:
          title = 'Specialist Overview';
          body = OphthalmologistDashboard(
            onOpenReviewQueue: () => setState(() => _navIndex = 1),
            onViewCases: () => setState(() => _navIndex = 2),
            onViewSystemStatus: () => setState(() => _navIndex = 3),
            onSelectCase: (c) => setState(() => _activeCaseReview = c),
          );
          break;
        case 1:
          title = 'Priority Review Queue';
          body = CaseQueueScreen(
            onSelectCase: (c) => setState(() => _activeCaseReview = c),
          );
          break;
        case 2:
          title = 'All Screening Cases';
          body = CaseQueueScreen(
            onSelectCase: (c) => setState(() => _activeCaseReview = c),
          );
          break;
        case 3:
          title = 'System & Microservices';
          body = const SystemStatusScreen();
          break;
        case 4:
          title = 'Clinical Reports';
          body = CaseQueueScreen(
            onSelectCase: (c) => setState(() => _activeReportView = c),
          );
          break;
        case 5:
        default:
          title = 'Clinician Profile & Verification';
          body = const ProfileScreen();
          break;
      }

      return ResponsiveScaffold(
        currentIndex: _navIndex,
        onNavigationIndexChanged: (idx) => setState(() => _navIndex = idx),
        title: title,
        currentUser: user,
        body: body,
      );
    }

    // -------------------------------------------------------------
    // 4. PHC HEALTH WORKER WORKSPACE
    // -------------------------------------------------------------
    Widget body;
    String title = 'PHC Screening Workspace';

    switch (_navIndex) {
      case 0:
        title = 'Screening Dashboard';
        body = HealthWorkerDashboard(
          onStartScreening: () {
            _resetScreeningFlow();
            setState(() => _navIndex = 1);
          },
          onViewCases: () => setState(() => _navIndex = 2),
        );
        break;
      case 1:
        title = 'Retinal Screening Flow';
        if (_screeningStep == 0) {
          body = PatientIntakeScreen(
            onProceedToCapture: () => setState(() => _screeningStep = 1),
          );
        } else if (_screeningStep == 1) {
          body = FundusCaptureScreen(
            onProceedToQuality: () => setState(() => _screeningStep = 2),
            onCancel: _resetScreeningFlow,
          );
        } else if (_screeningStep == 2) {
          body = ImageQualityScreen(
            onProceedToProcessing: () => setState(() => _screeningStep = 3),
            onRetake: () => setState(() => _screeningStep = 1),
          );
        } else if (_screeningStep == 3) {
          body = ClinicalProcessingScreen(
            onComplete: () => setState(() => _screeningStep = 4),
          );
        } else if (_screeningStep == 4) {
          body = AiResultScreen(
            onViewExplainability: () => setState(() => _screeningStep = 5),
            onViewReport: () => setState(() => _screeningStep = 6),
            onNewScreening: _resetScreeningFlow,
          );
        } else if (_screeningStep == 5) {
          body = ExplainabilityScreen(
            onBack: () => setState(() => _screeningStep = 4),
          );
        } else {
          body = ScreeningReportScreen(
            onBack: () => setState(() => _screeningStep = 4),
          );
        }
        break;
      case 2:
        title = 'Patient Screenings';
        body = CaseQueueScreen(
          onSelectCase: (c) => setState(() => _activeReportView = c),
        );
        break;
      case 3:
        title = 'Rural Sync Manager';
        body = const SyncManagerScreen();
        break;
      case 4:
      default:
        title = 'Worker Profile & Facility';
        body = const ProfileScreen();
        break;
    }

    return ResponsiveScaffold(
      currentIndex: _navIndex,
      onNavigationIndexChanged: (idx) => setState(() => _navIndex = idx),
      title: title,
      currentUser: user,
      body: body,
    );
  }
}
