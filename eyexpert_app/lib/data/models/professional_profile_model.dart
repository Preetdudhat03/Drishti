class ProfessionalProfileModel {
  final String id;
  final String userId;
  final String qualification;
  final String specialization;
  final String registrationNumber;
  final String registrationAuthority;
  final int yearsExperience;
  final String facilityName;
  final String? facilityId;
  final String professionalPhone;
  final String professionalEmail;
  final String consultationLocation;
  final String district;
  final String state;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfessionalProfileModel({
    required this.id,
    required this.userId,
    required this.qualification,
    required this.specialization,
    required this.registrationNumber,
    required this.registrationAuthority,
    this.yearsExperience = 5,
    required this.facilityName,
    this.facilityId,
    this.professionalPhone = '',
    this.professionalEmail = '',
    this.consultationLocation = '',
    required this.district,
    required this.state,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfessionalProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfessionalProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      qualification: json['qualification']?.toString() ?? 'MS / DNB (Ophthalmology)',
      specialization: json['specialization']?.toString() ?? 'Vitreo-Retinal Surgeon',
      registrationNumber: json['registration_number']?.toString() ?? json['professional_id']?.toString() ?? '',
      registrationAuthority: json['registration_authority']?.toString() ?? 'National Medical Commission (NMC)',
      yearsExperience: (json['years_experience'] as num?)?.toInt() ?? 5,
      facilityName: json['facility_name']?.toString() ?? json['hospital_name']?.toString() ?? 'District Eye Centre',
      facilityId: json['facility_id']?.toString(),
      professionalPhone: json['professional_phone']?.toString() ?? json['phone']?.toString() ?? '',
      professionalEmail: json['professional_email']?.toString() ?? json['email']?.toString() ?? '',
      consultationLocation: json['consultation_location']?.toString() ?? 'Main OPD, Eye Hospital',
      district: json['district']?.toString() ?? 'Ranchi',
      state: json['state']?.toString() ?? 'Jharkhand',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'qualification': qualification,
      'specialization': specialization,
      'registration_number': registrationNumber,
      'registration_authority': registrationAuthority,
      'years_experience': yearsExperience,
      'facility_name': facilityName,
      'facility_id': facilityId,
      'professional_phone': professionalPhone,
      'professional_email': professionalEmail,
      'consultation_location': consultationLocation,
      'district': district,
      'state': state,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProfessionalProfileModel copyWith({
    String? id,
    String? userId,
    String? qualification,
    String? specialization,
    String? registrationNumber,
    String? registrationAuthority,
    int? yearsExperience,
    String? facilityName,
    String? facilityId,
    String? professionalPhone,
    String? professionalEmail,
    String? consultationLocation,
    String? district,
    String? state,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfessionalProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      qualification: qualification ?? this.qualification,
      specialization: specialization ?? this.specialization,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      registrationAuthority: registrationAuthority ?? this.registrationAuthority,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      facilityName: facilityName ?? this.facilityName,
      facilityId: facilityId ?? this.facilityId,
      professionalPhone: professionalPhone ?? this.professionalPhone,
      professionalEmail: professionalEmail ?? this.professionalEmail,
      consultationLocation: consultationLocation ?? this.consultationLocation,
      district: district ?? this.district,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
