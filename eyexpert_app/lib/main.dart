import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/models/user_model.dart';
import 'data/models/screening_case_model.dart';
import 'data/services/supabase_service.dart';
import 'shared/widgets/responsive_scaffold.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/health_worker_dashboard.dart';
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

  // Screening sub-flow state
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

  void _onModeSwitch() {
    final currentMode = ref.read(authProvider).workflowMode;
    final nextMode = currentMode == 'DEMO' ? 'VALIDATION' : 'DEMO';
    ref.read(authProvider.notifier).setWorkflowMode(nextMode);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // If not authenticated, display login
    if (!authState.isAuthenticated || user == null) {
      return const LoginScreen();
    }

    // Clinician flow
    if (user.role == UserRole.clinician) {
      if (_activeCaseReview != null) {
        return ClinicianReviewScreen(
          screeningCase: _activeCaseReview!,
          onReviewSubmitted: () => setState(() => _activeCaseReview = null),
          onBack: () => setState(() => _activeCaseReview = null),
        );
      }

      Widget body;
      String title = 'Ophthalmologist Portal';
      if (_navIndex == 0) {
        title = 'Review Queue';
        body = CaseQueueScreen(
          onSelectCase: (c) => setState(() => _activeCaseReview = c),
        );
      } else if (_navIndex == 1) {
        title = 'System & Microservices';
        body = const SystemStatusScreen();
      } else {
        title = 'Clinician Profile';
        body = const ProfileScreen();
      }

      return ResponsiveScaffold(
        currentIndex: _navIndex,
        onNavigationIndexChanged: (idx) => setState(() => _navIndex = idx),
        title: title,
        currentUser: user,
        workflowMode: authState.workflowMode,
        onModeSwitchPressed: _onModeSwitch,
        body: body,
      );
    }

    // Health Worker flow
    if (_activeCaseReview != null) {
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

    Widget body;
    String title = 'Health Worker Portal';

    if (_navIndex == 0) {
      title = 'Screening Dashboard';
      body = HealthWorkerDashboard(
        onStartScreening: () {
          _resetScreeningFlow();
          setState(() => _navIndex = 1);
        },
        onViewCases: () => setState(() => _navIndex = 2),
      );
    } else if (_navIndex == 1) {
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
    } else if (_navIndex == 2) {
      title = 'Screening Cases';
      body = CaseQueueScreen(
        onSelectCase: (c) => setState(() => _activeCaseReview = c),
      );
    } else if (_navIndex == 3) {
      title = 'Rural Sync Manager';
      body = const SyncManagerScreen();
    } else {
      title = 'Worker Profile';
      body = const ProfileScreen();
    }

    return ResponsiveScaffold(
      currentIndex: _navIndex,
      onNavigationIndexChanged: (idx) => setState(() {
        _navIndex = idx;
      }),
      title: title,
      currentUser: user,
      workflowMode: authState.workflowMode,
      onModeSwitchPressed: _onModeSwitch,
      body: body,
    );
  }
}
