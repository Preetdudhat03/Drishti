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

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String organization;
  final String facilityId;
  final String? professionalId;
  final bool isActive;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    this.email = '',
    required this.name,
    required this.role,
    required this.organization,
    this.facilityId = 'PHC-RAMGARH-01',
    this.professionalId,
    this.isActive = true,
    this.lastLoginAt,
  });

  bool get isClinician => role == UserRole.clinician;
  bool get isHealthWorker => role == UserRole.healthWorker;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? 'Medical Officer',
      role: UserRole.fromString(json['role']?.toString()),
      organization: json['organization']?.toString() ?? json['facility_id']?.toString() ?? 'Primary Health Centre',
      facilityId: json['facility_id']?.toString() ?? 'PHC-RAMGARH-01',
      professionalId: json['professional_id']?.toString() ?? json['registration_id']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] : (json['is_active']?.toString() != 'false'),
      lastLoginAt: json['last_login_at'] != null ? DateTime.tryParse(json['last_login_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.code,
      'organization': organization,
      'facility_id': facilityId,
      'professional_id': professionalId,
      'is_active': isActive,
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? organization,
    String? facilityId,
    String? professionalId,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      organization: organization ?? this.organization,
      facilityId: facilityId ?? this.facilityId,
      professionalId: professionalId ?? this.professionalId,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

