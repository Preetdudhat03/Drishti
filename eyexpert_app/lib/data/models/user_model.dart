import 'facility_model.dart';
import 'professional_profile_model.dart';
import 'verification_document_model.dart';

enum UserRole {
  healthWorker,
  clinician,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.healthWorker:
        return 'PHC / Health Worker';
      case UserRole.clinician:
        return 'Ophthalmologist';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get code {
    switch (this) {
      case UserRole.healthWorker:
        return 'HEALTH_WORKER';
      case UserRole.clinician:
        return 'OPHTHALMOLOGIST';
      case UserRole.admin:
        return 'ADMIN';
    }
  }

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.healthWorker;
    final normalized = role.trim().toUpperCase();
    if (normalized.contains('CLINICIAN') ||
        normalized.contains('OPHTHALMOLOGIST') ||
        normalized == 'DOCTOR') {
      return UserRole.clinician;
    }
    if (normalized.contains('ADMIN')) {
      return UserRole.admin;
    }
    return UserRole.healthWorker;
  }
}

enum OverallVerificationStatus {
  pending,
  underReview,
  verified,
  requiresAction;

  String get label {
    switch (this) {
      case OverallVerificationStatus.pending:
        return 'PENDING ENROLLMENT';
      case OverallVerificationStatus.underReview:
        return 'UNDER REVIEW';
      case OverallVerificationStatus.verified:
        return 'VERIFIED';
      case OverallVerificationStatus.requiresAction:
        return 'REQUIRES CORRECTION';
    }
  }

  String get code {
    switch (this) {
      case OverallVerificationStatus.pending:
        return 'PENDING';
      case OverallVerificationStatus.underReview:
        return 'UNDER_REVIEW';
      case OverallVerificationStatus.verified:
        return 'VERIFIED';
      case OverallVerificationStatus.requiresAction:
        return 'REQUIRES_ACTION';
    }
  }

  static OverallVerificationStatus fromString(String? val) {
    if (val == null) return OverallVerificationStatus.pending;
    final norm = val.trim().toUpperCase();
    if (norm == 'VERIFIED' || norm == 'APPROVED') return OverallVerificationStatus.verified;
    if (norm == 'UNDER_REVIEW' || norm == 'IN_REVIEW') return OverallVerificationStatus.underReview;
    if (norm == 'REQUIRES_ACTION' || norm == 'REJECTED' || norm == 'ACTION_REQUIRED') {
      return OverallVerificationStatus.requiresAction;
    }
    return OverallVerificationStatus.pending;
  }
}

class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final String organization;
  final String facilityId;
  final String? professionalId;
  final String? avatarUrl;
  final String district;
  final String state;
  final String address;
  final String pinCode;
  final String gender;
  final String preferredLanguage;
  final int profileCompletion;
  final OverallVerificationStatus verificationStatus;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final FacilityModel? facility;
  final ProfessionalProfileModel? professionalProfile;
  final List<VerificationDocumentModel> documents;

  const UserModel({
    required this.id,
    this.email = '',
    required this.name,
    this.phone = '',
    required this.role,
    required this.organization,
    this.facilityId = 'PHC-RAMGARH-01',
    this.professionalId,
    this.avatarUrl,
    this.district = 'Ramgarh',
    this.state = 'Jharkhand',
    this.address = '',
    this.pinCode = '829122',
    this.gender = 'Not Specified',
    this.preferredLanguage = 'English / Hindi',
    this.profileCompletion = 80,
    this.verificationStatus = OverallVerificationStatus.underReview,
    this.isActive = true,
    this.createdAt,
    this.lastLoginAt,
    this.facility,
    this.professionalProfile,
    this.documents = const [],
  });

  bool get isClinician => role == UserRole.clinician;
  bool get isHealthWorker => role == UserRole.healthWorker;
  bool get isVerified => verificationStatus == OverallVerificationStatus.verified;

  int calculateCompletionPercentage() {
    int score = 0;
    // Step 1: Basic account
    if (email.isNotEmpty) score += 15;
    if (name.isNotEmpty) score += 15;
    if (phone.isNotEmpty) score += 10;
    if (address.isNotEmpty) score += 10;
    if (district.isNotEmpty && state.isNotEmpty) score += 10;

    // Step 2: Role specific info
    if (isHealthWorker) {
      if (facilityId.isNotEmpty) score += 15;
      if (facility?.facilityName.isNotEmpty == true) score += 10;
    } else {
      if (professionalId != null && professionalId!.isNotEmpty) score += 15;
      if (professionalProfile?.qualification.isNotEmpty == true) score += 10;
    }

    // Step 3: Documents
    if (documents.isNotEmpty) {
      final uploadedCount = documents.where((d) => d.isUploaded).length;
      if (uploadedCount >= 2) {
        score += 15;
      } else if (uploadedCount == 1) {
        score += 8;
      }
    }

    return score.clamp(0, 100);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? 'Medical Officer',
      phone: json['phone']?.toString() ?? '',
      role: UserRole.fromString(json['role']?.toString()),
      organization: json['organization']?.toString() ?? json['facility_name']?.toString() ?? json['facility_id']?.toString() ?? 'Primary Health Centre',
      facilityId: json['facility_id']?.toString() ?? 'PHC-RAMGARH-01',
      professionalId: json['professional_id']?.toString() ?? json['registration_number']?.toString() ?? json['registration_id']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      district: json['district']?.toString() ?? 'Ramgarh',
      state: json['state']?.toString() ?? 'Jharkhand',
      address: json['address']?.toString() ?? '',
      pinCode: json['pin_code']?.toString() ?? '829122',
      gender: json['gender']?.toString() ?? 'Not Specified',
      preferredLanguage: json['preferred_language']?.toString() ?? 'English / Hindi',
      profileCompletion: (json['profile_completion'] as num?)?.toInt() ?? 80,
      verificationStatus: OverallVerificationStatus.fromString(json['verification_status']?.toString()),
      isActive: json['is_active'] is bool ? json['is_active'] : (json['is_active']?.toString() != 'false'),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      lastLoginAt: json['last_login_at'] != null ? DateTime.tryParse(json['last_login_at'].toString()) : null,
      facility: json['facility'] != null && json['facility'] is Map<String, dynamic>
          ? FacilityModel.fromJson(json['facility'])
          : null,
      professionalProfile: json['professional_profile'] != null && json['professional_profile'] is Map<String, dynamic>
          ? ProfessionalProfileModel.fromJson(json['professional_profile'])
          : null,
      documents: json['documents'] != null && json['documents'] is List
          ? (json['documents'] as List)
              .map((d) => VerificationDocumentModel.fromJson(Map<String, dynamic>.from(d)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'full_name': name,
      'phone': phone,
      'role': role.code,
      'organization': organization,
      'facility_id': facilityId,
      'professional_id': professionalId,
      'avatar_url': avatarUrl,
      'district': district,
      'state': state,
      'address': address,
      'pin_code': pinCode,
      'gender': gender,
      'preferred_language': preferredLanguage,
      'profile_completion': profileCompletion,
      'verification_status': verificationStatus.code,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'facility': facility?.toJson(),
      'professional_profile': professionalProfile?.toJson(),
      'documents': documents.map((d) => d.toJson()).toList(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? organization,
    String? facilityId,
    String? professionalId,
    String? avatarUrl,
    String? district,
    String? state,
    String? address,
    String? pinCode,
    String? gender,
    String? preferredLanguage,
    int? profileCompletion,
    OverallVerificationStatus? verificationStatus,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    FacilityModel? facility,
    ProfessionalProfileModel? professionalProfile,
    List<VerificationDocumentModel>? documents,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      organization: organization ?? this.organization,
      facilityId: facilityId ?? this.facilityId,
      professionalId: professionalId ?? this.professionalId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      district: district ?? this.district,
      state: state ?? this.state,
      address: address ?? this.address,
      pinCode: pinCode ?? this.pinCode,
      gender: gender ?? this.gender,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      facility: facility ?? this.facility,
      professionalProfile: professionalProfile ?? this.professionalProfile,
      documents: documents ?? this.documents,
    );
  }
}
