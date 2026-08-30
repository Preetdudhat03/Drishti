import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? authenticatingMessage;
  final String? errorMessage;
  final bool isSessionRestored;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.authenticatingMessage,
    this.errorMessage,
    this.isSessionRestored = false,
  });

  bool get isAuthenticated => user != null;
  bool get isClinician => user?.role == UserRole.clinician;
  bool get isHealthWorker => user?.role == UserRole.healthWorker;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? authenticatingMessage,
    String? errorMessage,
    bool? isSessionRestored,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      authenticatingMessage: authenticatingMessage ?? this.authenticatingMessage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSessionRestored: isSessionRestored ?? this.isSessionRestored,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _initSession();
  }

  Future<void> _initSession() async {
    try {
      final user = await _authService.getCurrentUser();
      state = state.copyWith(
        user: user,
        isSessionRestored: true,
      );
    } catch (_) {
      state = state.copyWith(isSessionRestored: true);
    }
  }

  Future<bool> login({
    required String username,
    required String password,
    required UserRole roleRequested,
    String? medicalRegistrationId,
  }) async {
    state = state.copyWith(
      isLoading: true,
      authenticatingMessage: 'Verifying secure clinical access...',
      clearError: true,
    );

    try {
      final user = await _authService.login(
        username: username,
        password: password,
        roleRequested: roleRequested,
        medicalRegistrationId: medicalRegistrationId,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        authenticatingMessage: null,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        authenticatingMessage: null,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, authenticatingMessage: 'Signing out...');
    try {
      await _authService.logout();
    } catch (_) {}
    state = const AuthState(isSessionRestored: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
