import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/models/user_model.dart';
import 'data/models/screening_case_model.dart';
import 'data/services/supabase_service.dart';
import 'shared/widgets/responsive_scaffold.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/clinician_login_screen.dart';
import 'features/review/clinician_review_screen.dart';
import 'features/queue/case_queue_screen.dart';
import 'features/system_status/system_status_screen.dart';
import 'features/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: DrishtiClinicianApp(),
    ),
  );
}

class DrishtiClinicianApp extends ConsumerWidget {
  const DrishtiClinicianApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Drishti Clinician - AI Retinal Review Workstation',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.clinicalTheme,
      home: const ClinicianRootScreen(),
    );
  }
}

class ClinicianRootScreen extends ConsumerStatefulWidget {
  const ClinicianRootScreen({super.key});

  @override
  ConsumerState<ClinicianRootScreen> createState() => _ClinicianRootScreenState();
}

class _ClinicianRootScreenState extends ConsumerState<ClinicianRootScreen> {
  int _navIndex = 0;
  ScreeningCaseModel? _activeCaseReview;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (!authState.isAuthenticated || user == null) {
      return const ClinicianLoginScreen();
    }

    if (_activeCaseReview != null) {
      return ClinicianReviewScreen(
        screeningCase: _activeCaseReview!,
        onReviewSubmitted: () => setState(() => _activeCaseReview = null),
        onBack: () => setState(() => _activeCaseReview = null),
      );
    }

    Widget body;
    String title = 'Ophthalmology Review Workstation';
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
      body: body,
    );
  }
}
