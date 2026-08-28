import 'dart:convert';
import '../models/user_model.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../core/security/secure_storage.dart';
import 'supabase_service.dart';

class AuthService {
  final ApiClient _apiClient;
  final SupabaseService _supabaseService;

  AuthService({ApiClient? apiClient, SupabaseService? supabaseService})
      : _apiClient = apiClient ?? ApiClient(),
        _supabaseService = supabaseService ?? SupabaseService();

  Future<UserModel> login({
    required String username,
    required String password,
    required UserRole roleRequested,
    bool isDemo = false,
  }) async {
    // 1. Genuine Supabase Auth attempt
    if (SupabaseService.isInitialized) {
      try {
        final supaUser = await _supabaseService.signIn(
          email: username,
          password: password,
        );
        if (supaUser != null) {
          final token = SupabaseService.client?.auth.currentSession?.accessToken;
          if (token != null) {
            await SecureStorage.saveToken(token);
          }
          await SecureStorage.saveUserData(jsonEncode(supaUser.toJson()));
          return supaUser;
        }
      } catch (e) {
        // Fall through to backend API if Supabase returns error or offline
      }
    }

    // 2. Fallback to API Backend
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        body: {
          'username': username,
          'password': password,
          'role_requested': roleRequested.name.toUpperCase(),
        },
      );

    final token = response['token'];
    if (token != null) {
      await SecureStorage.saveToken(token);
    }
    final user = UserModel.fromJson(response['user']);
    await SecureStorage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<UserModel?> getCurrentUser() async {
    final userData = await SecureStorage.getUserData();
    if (userData != null) {
      try {
        return UserModel.fromJson(jsonDecode(userData));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> logout() async {
    await _supabaseService.signOut();
    await SecureStorage.clearSession();
  }
}
