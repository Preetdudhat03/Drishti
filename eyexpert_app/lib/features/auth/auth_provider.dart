import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../core/security/secure_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final String workflowMode; // 'DEMO' (Simulated Workflow) or 'VALIDATION' (Real APTOS Test Data)

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.workflowMode = 'DEMO',
  });

  bool get isAuthenticated => user != null;
  bool get isClinician => user?.role == UserRole.clinician;
  bool get isHealthWorker => user?.role == UserRole.healthWorker;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    String? workflowMode,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      workflowMode: workflowMode ?? this.workflowMode,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState(user: UserModel.demoHealthWorker)) {
    _initSession();
  }

  Future<void> _initSession() async {
    final savedMode = await SecureStorage.getWorkflowMode();
    final user = await _authService.getCurrentUser();
    state = state.copyWith(
      user: user ?? UserModel.demoHealthWorker,
      workflowMode: savedMode,
    );
  }

  Future<void> login({
    required String username,
    required String password,
    required UserRole roleRequested,
    bool isDemo = true,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.login(
        username: username,
        password: password,
        roleRequested: roleRequested,
        isDemo: isDemo,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> switchRole(UserRole newRole) async {
    final user = newRole == UserRole.clinician
        ? UserModel.demoClinician
        : UserModel.demoHealthWorker;
    await login(
      username: user.name,
      password: '',
      roleRequested: newRole,
      isDemo: true,
    );
  }

  Future<void> setWorkflowMode(String mode) async {
    await SecureStorage.saveWorkflowMode(mode);
    state = state.copyWith(workflowMode: mode);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
