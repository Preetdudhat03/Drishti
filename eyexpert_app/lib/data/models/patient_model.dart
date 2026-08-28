class PatientModel {
  final String patientId;
  final int? age;
  final String? gender;
  final int? diabetesDurationYears;
  final String eye; // 'OD' (Right Eye) or 'OS' (Left Eye)
  final String facilityId;
  final DateTime createdAt;

  const PatientModel({
    required this.patientId,
    this.age,
    this.gender,
    this.diabetesDurationYears,
    required this.eye,
    required this.facilityId,
    required this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      patientId: json['patient_id'] ?? '',
      age: json['age'],
      gender: json['gender'],
      diabetesDurationYears: json['diabetes_duration_years'],
      eye: json['eye'] ?? 'OD',
      facilityId: json['facility_id'] ?? 'PHC-01',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'age': age,
      'gender': gender,
      'diabetes_duration_years': diabetesDurationYears,
      'eye': eye,
      'facility_id': facilityId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PatientModel copyWith({
    String? patientId,
    int? age,
    String? gender,
    int? diabetesDurationYears,
    String? eye,
    String? facilityId,
    DateTime? createdAt,
  }) {
    return PatientModel(
      patientId: patientId ?? this.patientId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      diabetesDurationYears: diabetesDurationYears ?? this.diabetesDurationYears,
      eye: eye ?? this.eye,
      facilityId: facilityId ?? this.facilityId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
