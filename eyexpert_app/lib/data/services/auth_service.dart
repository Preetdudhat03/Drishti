import 'dart:convert';
import '../models/user_model.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../core/security/secure_storage.dart';
import 'mock_data_service.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<UserModel> login({
    required String username,
    required String password,
    required UserRole roleRequested,
    bool isDemo = true,
  }) async {
    if (isDemo || username.contains('demo')) {
      final UserModel user = roleRequested == UserRole.clinician
          ? UserModel.demoClinician
          : UserModel.demoHealthWorker;
      await SecureStorage.saveToken('DEMO_JWT_TOKEN_${user.id}');
      await SecureStorage.saveUserData(jsonEncode(user.toJson()));
      return user;
    }

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
    await SecureStorage.clearSession();
  }
}
