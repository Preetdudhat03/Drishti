enum FacilityType {
  phc,
  chc,
  districtHospital,
  privateClinic,
  eyeHospital,
  medicalCollege;

  String get displayName {
    switch (this) {
      case FacilityType.phc:
        return 'Primary Health Centre (PHC)';
      case FacilityType.chc:
        return 'Community Health Centre (CHC)';
      case FacilityType.districtHospital:
        return 'District Eye Hospital';
      case FacilityType.privateClinic:
        return 'Private Ophthalmology Clinic';
      case FacilityType.eyeHospital:
        return 'Tertiary Eye Hospital';
      case FacilityType.medicalCollege:
        return 'Medical College & Hospital';
    }
  }

  static FacilityType fromString(String? type) {
    if (type == null) return FacilityType.phc;
    final norm = type.trim().toUpperCase();
    if (norm.contains('CHC') || norm.contains('COMMUNITY')) return FacilityType.chc;
    if (norm.contains('DISTRICT')) return FacilityType.districtHospital;
    if (norm.contains('PRIVATE')) return FacilityType.privateClinic;
    if (norm.contains('TERTIARY') || norm.contains('EYE')) return FacilityType.eyeHospital;
    if (norm.contains('COLLEGE')) return FacilityType.medicalCollege;
    return FacilityType.phc;
  }
}

enum ConnectivityType {
  online,
  limited,
  offline;

  String get displayName {
    switch (this) {
      case ConnectivityType.online:
        return 'Full Broadband / 4G (Online)';
      case ConnectivityType.limited:
        return 'Intermittent / 2G-3G (Limited)';
      case ConnectivityType.offline:
        return 'No Cellular Network (Offline Sync)';
    }
  }

  static ConnectivityType fromString(String? val) {
    if (val == null) return ConnectivityType.online;
    final norm = val.trim().toUpperCase();
    if (norm.contains('LIMITED') || norm.contains('2G') || norm.contains('3G')) return ConnectivityType.limited;
    if (norm.contains('OFFLINE') || norm.contains('NONE')) return ConnectivityType.offline;
    return ConnectivityType.online;
  }
}

class FacilityModel {
  final String id;
  final String facilityName;
  final FacilityType facilityType;
  final String facilityIdentifier;
  final String address;
  final String? villageTown;
  final String district;
  final String state;
  final String pinCode;
  final String contactNumber;
  final String officialEmail;
  final int numberOfScreeningStaff;
  final bool cameraAvailable;
  final String? cameraManufacturer;
  final String? cameraModel;
  final ConnectivityType connectivityType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FacilityModel({
    required this.id,
    required this.facilityName,
    this.facilityType = FacilityType.phc,
    required this.facilityIdentifier,
    required this.address,
    this.villageTown,
    required this.district,
    required this.state,
    required this.pinCode,
    required this.contactNumber,
    this.officialEmail = '',
    this.numberOfScreeningStaff = 1,
    this.cameraAvailable = true,
    this.cameraManufacturer,
    this.cameraModel,
    this.connectivityType = ConnectivityType.online,
    this.createdAt,
    this.updatedAt,
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      id: json['id']?.toString() ?? '',
      facilityName: json['facility_name']?.toString() ?? json['name']?.toString() ?? 'PHC Ramgarh',
      facilityType: FacilityType.fromString(json['facility_type']?.toString()),
      facilityIdentifier: json['facility_identifier']?.toString() ?? json['facility_id']?.toString() ?? 'PHC-RAMGARH-01',
      address: json['address']?.toString() ?? 'Main Health Post, Sector 4',
      villageTown: json['village_town']?.toString(),
      district: json['district']?.toString() ?? 'Ramgarh',
      state: json['state']?.toString() ?? 'Jharkhand',
      pinCode: json['pin_code']?.toString() ?? '829122',
      contactNumber: json['contact_number']?.toString() ?? json['phone']?.toString() ?? '',
      officialEmail: json['official_email']?.toString() ?? json['email']?.toString() ?? '',
      numberOfScreeningStaff: (json['number_of_screening_staff'] as num?)?.toInt() ?? 1,
      cameraAvailable: json['camera_available'] is bool ? json['camera_available'] : (json['camera_available']?.toString() != 'false'),
      cameraManufacturer: json['camera_manufacturer']?.toString() ?? 'Remidio / Forus Health',
      cameraModel: json['camera_model']?.toString() ?? 'FOP NM-01 Retinal Camera',
      connectivityType: ConnectivityType.fromString(json['connectivity_type']?.toString() ?? json['connectivity']?.toString()),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facility_name': facilityName,
      'facility_type': facilityType.name,
      'facility_identifier': facilityIdentifier,
      'address': address,
      'village_town': villageTown,
      'district': district,
      'state': state,
      'pin_code': pinCode,
      'contact_number': contactNumber,
      'official_email': officialEmail,
      'number_of_screening_staff': numberOfScreeningStaff,
      'camera_available': cameraAvailable,
      'camera_manufacturer': cameraManufacturer,
      'camera_model': cameraModel,
      'connectivity_type': connectivityType.name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  FacilityModel copyWith({
    String? id,
    String? facilityName,
    FacilityType? facilityType,
    String? facilityIdentifier,
    String? address,
    String? villageTown,
    String? district,
    String? state,
    String? pinCode,
    String? contactNumber,
    String? officialEmail,
    int? numberOfScreeningStaff,
    bool? cameraAvailable,
    String? cameraManufacturer,
    String? cameraModel,
    ConnectivityType? connectivityType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FacilityModel(
      id: id ?? this.id,
      facilityName: facilityName ?? this.facilityName,
      facilityType: facilityType ?? this.facilityType,
      facilityIdentifier: facilityIdentifier ?? this.facilityIdentifier,
      address: address ?? this.address,
      villageTown: villageTown ?? this.villageTown,
      district: district ?? this.district,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      contactNumber: contactNumber ?? this.contactNumber,
      officialEmail: officialEmail ?? this.officialEmail,
      numberOfScreeningStaff: numberOfScreeningStaff ?? this.numberOfScreeningStaff,
      cameraAvailable: cameraAvailable ?? this.cameraAvailable,
      cameraManufacturer: cameraManufacturer ?? this.cameraManufacturer,
      cameraModel: cameraModel ?? this.cameraModel,
      connectivityType: connectivityType ?? this.connectivityType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
