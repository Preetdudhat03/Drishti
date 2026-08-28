enum UserRole {
  healthWorker,
  clinician,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.healthWorker:
        return 'Health Worker';
      case UserRole.clinician:
        return 'Ophthalmologist / Clinician';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'CLINICIAN':
      case 'OPHTHALMOLOGIST':
        return UserRole.clinician;
      case 'ADMIN':
        return UserRole.admin;
      case 'HEALTH_WORKER':
      default:
        return UserRole.healthWorker;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final UserRole role;
  final String organization;
  final bool isDemoAccount;

  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.organization,
    this.isDemoAccount = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.fromString(json['role']),
      organization: json['organization'] ?? '',
      isDemoAccount: json['is_demo_account'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role.name.toUpperCase(),
      'organization': organization,
      'is_demo_account': isDemoAccount,
    };
  }

  static const UserModel healthWorkerDefault = UserModel(
    id: 'HW-RAMGARH-001',
    name: 'Sunita Sharma',
    role: UserRole.healthWorker,
    organization: 'PHC Ramgarh Tele-Screening Unit',
    isDemoAccount: false,
  );

  static const UserModel clinicianDefault = UserModel(
    id: 'DOC-DISTRICT-002',
    name: 'Dr. Rajesh Kumar',
    role: UserRole.clinician,
    organization: 'District Eye Hospital (Retina Clinic)',
    isDemoAccount: false,
  );
}
