import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../core/security/secure_storage.dart';
import 'supabase_service.dart';

class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

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
    String? medicalRegistrationId,
  }) async {
    final trimmedEmail = username.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const AuthException(
        'Please enter your registered credentials to proceed.',
        code: 'empty_fields',
      );
    }

    // -------------------------------------------------------------
    // 2. Production Supabase Authentication Layer
    // -------------------------------------------------------------
    if (SupabaseService.isInitialized) {
      try {
        final supa = SupabaseService.client;
        if (supa != null) {
          final AuthResponse authResponse = await supa.auth.signInWithPassword(
            email: trimmedEmail,
            password: password,
          );

          final supaUser = authResponse.user;
          if (supaUser == null) {
            throw const AuthException(
              'Authentication failed\n\nThe email/ID or password is incorrect.\n\nPlease verify your credentials and try again.',
              code: 'invalid_credentials',
            );
          }

          // Fetch authenticated role from Postgres 'profiles' table
          final profile = await _supabaseService.fetchUserProfile(
            supaUser.id,
            fallbackEmail: supaUser.email,
          );

          final user = profile ??
              UserModel(
                id: supaUser.id,
                email: supaUser.email ?? trimmedEmail,
                name: supaUser.userMetadata?['full_name'] ?? 'Medical Officer',
                role: roleRequested,
                organization: supaUser.userMetadata?['facility_id'] ?? 'PHC Tele-Screening Unit',
                facilityId: supaUser.userMetadata?['facility_id'] ?? 'PHC-RAMGARH-01',
                isActive: true,
                isDemoAccount: false,
              );

          // Check account status
          if (!user.isActive) {
            await supa.auth.signOut();
            throw const AuthException(
              'Account access is currently inactive.\n\nPlease contact your facility administrator.',
              code: 'account_inactive',
            );
          }

          // Persist session
          final token = authResponse.session?.accessToken;
          if (token != null) {
            await SecureStorage.saveToken(token);
          }
          await SecureStorage.saveUserData(jsonEncode(user.toJson()));
          return user;
        }
      } on AuthApiException catch (e) {
        debugPrint('[AuthService] Supabase AuthApiException: ${e.message}');
        if (e.message.toLowerCase().contains('invalid login credentials') ||
            e.statusCode == '400') {
          throw const AuthException(
            'Authentication failed\n\nThe email/ID or password is incorrect.\n\nPlease verify your credentials and try again.',
            code: 'invalid_credentials',
          );
        }
        throw AuthException(e.message, code: e.statusCode);
      } on AuthException {
        rethrow;
      } catch (e) {
        debugPrint('[AuthService] Supabase connection error: $e');
        // If network issue or host unreachable, check backend or return network error
        if (e.toString().toLowerCase().contains('socket') ||
            e.toString().toLowerCase().contains('network') ||
            e.toString().toLowerCase().contains('failed host lookup') ||
            e.toString().toLowerCase().contains('clientexception')) {
          // Attempt backend API fallback before declaring network failure
        } else {
          throw const AuthException(
            'Authentication failed\n\nThe email/ID or password is incorrect.\n\nPlease verify your credentials and try again.',
            code: 'auth_failed',
          );
        }
      }
    }

    // -------------------------------------------------------------
    // 3. Fallback to Dedicated Drishti Backend API Gateway
    // -------------------------------------------------------------
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        body: {
          'username': trimmedEmail,
          'password': password,
          'role_requested': roleRequested.code,
          if (medicalRegistrationId != null && medicalRegistrationId.isNotEmpty)
            'medical_registration_id': medicalRegistrationId,
        },
      );

      final token = response['token'];
      if (token != null) {
        await SecureStorage.saveToken(token);
      }
      final user = UserModel.fromJson(response['user']);
      if (!user.isActive) {
        throw const AuthException(
          'Account access is currently inactive.\n\nPlease contact your facility administrator.',
          code: 'account_inactive',
        );
      }
      await SecureStorage.saveUserData(jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('[AuthService] Backend API login attempt failed: $e');
      throw const AuthException(
        'Unable to connect to authentication service.\n\nCheck your network connection and try again.',
        code: 'network_failure',
      );
    }
  }

  Future<UserModel?> getCurrentUser() async {
    // 1. Check Supabase session first
    if (SupabaseService.isInitialized) {
      try {
        final currentSupaUser = SupabaseService.client?.auth.currentUser;
        if (currentSupaUser != null) {
          final profile = await _supabaseService.fetchUserProfile(
            currentSupaUser.id,
            fallbackEmail: currentSupaUser.email,
          );
          if (profile != null && profile.isActive) {
            return profile;
          }
        }
      } catch (_) {}
    }

    // 2. Restore from secure storage
    final userData = await SecureStorage.getUserData();
    if (userData != null) {
      try {
        final user = UserModel.fromJson(jsonDecode(userData));
        return user.isActive ? user : null;
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
