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
    UserRole roleRequested = UserRole.healthWorker,
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

  // Multi-Step Onboarding & Clinical Registration
  Future<UserModel> registerAndOnboard({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    required String district,
    required String state,
    required String address,
    required String pinCode,
    String gender = 'Not Specified',
    String preferredLanguage = 'English / Hindi',
    String? organizationName,
    String? facilityId,
    String? facilityType,
    String? cameraManufacturer,
    String? cameraModel,
    bool cameraAvailable = true,
    String connectivity = 'ONLINE',
    String? medicalRegistrationNo,
    String? registrationAuthority,
    String? qualification,
    String? specialization,
    int yearsExperience = 5,
    List<Map<String, dynamic>> initialDocuments = const [],
  }) async {
    final supa = SupabaseService.client;
    if (supa == null) {
      throw const AuthException(
        'Supabase authentication service is not initialized.\nPlease check your network connection.',
        code: 'supabase_uninitialized',
      );
    }

    try {
      final finalFacilityId = facilityId?.trim().isNotEmpty == true
          ? facilityId!.trim()
          : (role == UserRole.clinician ? 'FAC-CLINIC' : 'PHC-UNIT');

      final finalOrg = organizationName?.trim().isNotEmpty == true
          ? organizationName!.trim()
          : (role == UserRole.clinician ? 'Eye Care Hospital' : 'Primary Health Centre');

      // 1. Create Supabase Auth User
      final AuthResponse response = await supa.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'role': role.displayName,
          'facility_id': finalFacilityId,
          'professional_id': medicalRegistrationNo?.trim(),
        },
      );

      final supaUser = response.user;
      if (supaUser == null) {
        throw const AuthException(
          'Failed to create account. Please verify your email and try again.',
          code: 'signup_failed',
        );
      }

      final userId = supaUser.id;

      // 2. Persist Profile
      await supa.from('profiles').upsert({
        'id': userId,
        'email': email.trim(),
        'full_name': fullName.trim(),
        'name': fullName.trim(),
        'phone': phone.trim(),
        'role': role.displayName,
        'organization': finalOrg,
        'facility_id': finalFacilityId,
        'professional_id': medicalRegistrationNo?.trim(),
        'district': district.trim(),
        'state': state.trim(),
        'address': address.trim(),
        'pin_code': pinCode.trim(),
        'gender': gender,
        'preferred_language': preferredLanguage,
        'profile_completion': 90,
        'verification_status': 'UNDER_REVIEW',
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. Persist Facility or Professional Profile
      if (role == UserRole.healthWorker) {
        await supa.from('facilities').upsert({
          'facility_name': finalOrg,
          'facility_type': facilityType ?? 'Primary Health Centre (PHC)',
          'facility_identifier': finalFacilityId,
          'address': address.trim(),
          'district': district.trim(),
          'state': state.trim(),
          'pin_code': pinCode.trim(),
          'contact_number': phone.trim(),
          'official_email': email.trim(),
          'camera_available': cameraAvailable,
          'camera_manufacturer': cameraManufacturer?.trim() ?? '',
          'camera_model': cameraModel?.trim() ?? '',
          'connectivity_type': connectivity,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        await supa.from('professional_profiles').upsert({
          'user_id': userId,
          'qualification': qualification?.trim() ?? '',
          'specialization': specialization?.trim() ?? '',
          'registration_number': medicalRegistrationNo?.trim() ?? '',
          'registration_authority': registrationAuthority?.trim() ?? '',
          'years_experience': yearsExperience,
          'facility_name': finalOrg,
          'facility_id': finalFacilityId,
          'professional_phone': phone.trim(),
          'professional_email': email.trim(),
          'district': district.trim(),
          'state': state.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      // 4. Fetch the full created profile
      final user = await _supabaseService.fetchUserProfile(userId, fallbackEmail: email.trim());
      final finalUser = user ??
          UserModel(
            id: userId,
            email: email.trim(),
            name: fullName.trim(),
            phone: phone.trim(),
            role: role,
            organization: finalOrg,
            facilityId: finalFacilityId,
            professionalId: medicalRegistrationNo,
            district: district.trim(),
            state: state.trim(),
            address: address.trim(),
            pinCode: pinCode.trim(),
            gender: gender,
            preferredLanguage: preferredLanguage,
            profileCompletion: 90,
            verificationStatus: OverallVerificationStatus.underReview,
            isActive: true,
          );

      // Persist session locally
      final token = response.session?.accessToken;
      if (token != null) {
        await SecureStorage.saveToken(token);
      }
      await SecureStorage.saveUserData(jsonEncode(finalUser.toJson()));
      return finalUser;
    } on AuthApiException catch (e) {
      debugPrint('[AuthService] Supabase signup error: ${e.message}');
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('[AuthService] General signup error: $e');
      throw const AuthException(
        'Registration failed. Please check your connection and details.',
        code: 'registration_error',
      );
    }
  }

  // Update Profile
  Future<UserModel> updateUserProfile(UserModel updatedUser) async {
    // 1. Update Auth User Metadata if signed in
    try {
      final supa = SupabaseService.client;
      if (supa != null && supa.auth.currentUser != null) {
        await supa.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': updatedUser.name,
              'name': updatedUser.name,
              'phone': updatedUser.phone,
              'facility_id': updatedUser.facilityId,
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('[AuthService] Auth metadata update notice: $e');
    }

    // 2. Persist to PostgreSQL tables
    try {
      await _supabaseService.updateProfile(updatedUser);
    } catch (e) {
      debugPrint('[AuthService] Supabase profile table update warning: $e');
    }

    // 3. Always update local secure cache so UI updates instantly and stays responsive
    await SecureStorage.saveUserData(jsonEncode(updatedUser.toJson()));
    return updatedUser;
  }

  // Change Password
  Future<void> changePassword(String newPassword) async {
    final success = await _supabaseService.changePassword(newPassword: newPassword);
    if (!success) {
      throw const AuthException(
        'Failed to update password. Please check your connection.',
        code: 'password_update_failed',
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
