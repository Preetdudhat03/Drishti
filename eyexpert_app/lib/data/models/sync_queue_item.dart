enum SyncStatus {
  queuedForUpload,
  uploading,
  uploaded,
  syncFailed;

  String get label {
    switch (this) {
      case SyncStatus.queuedForUpload:
        return 'QUEUED';
      case SyncStatus.uploading:
        return 'UPLOADING';
      case SyncStatus.uploaded:
        return 'SYNCED';
      case SyncStatus.syncFailed:
        return 'FAILED';
    }
  }
}

class SyncQueueItem {
  final String localId;
  final String clientRequestId;
  final String patientId;
  final int? age;
  final String? gender;
  final int? diabetesDurationYears;
  final String eye;
  final String imagePath;
  final String? imageSha256;
  final SyncStatus status;
  final String? serverScreeningId;
  final String? errorMessage;
  final DateTime capturedAt;
  final int retryCount;

  const SyncQueueItem({
    required this.localId,
    required this.clientRequestId,
    required this.patientId,
    this.age,
    this.gender,
    this.diabetesDurationYears,
    required this.eye,
    required this.imagePath,
    this.imageSha256,
    this.status = SyncStatus.queuedForUpload,
    this.serverScreeningId,
    this.errorMessage,
    required this.capturedAt,
    this.retryCount = 0,
  });

  SyncQueueItem copyWith({
    String? localId,
    String? clientRequestId,
    String? patientId,
    int? age,
    String? gender,
    int? diabetesDurationYears,
    String? eye,
    String? imagePath,
    String? imageSha256,
    SyncStatus? status,
    String? serverScreeningId,
    String? errorMessage,
    DateTime? capturedAt,
    int? retryCount,
  }) {
    return SyncQueueItem(
      localId: localId ?? this.localId,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      patientId: patientId ?? this.patientId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      diabetesDurationYears: diabetesDurationYears ?? this.diabetesDurationYears,
      eye: eye ?? this.eye,
      imagePath: imagePath ?? this.imagePath,
      imageSha256: imageSha256 ?? this.imageSha256,
      status: status ?? this.status,
      serverScreeningId: serverScreeningId ?? this.serverScreeningId,
      errorMessage: errorMessage ?? this.errorMessage,
      capturedAt: capturedAt ?? this.capturedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'client_request_id': clientRequestId,
      'patient_id': patientId,
      'age': age,
      'gender': gender,
      'diabetes_duration_years': diabetesDurationYears,
      'eye': eye,
      'image_path': imagePath,
      'image_sha256': imageSha256,
      'status': status.label,
      'server_screening_id': serverScreeningId,
      'error_message': errorMessage,
      'captured_at': capturedAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      localId: json['local_id'] ?? '',
      clientRequestId: json['client_request_id'] ?? '',
      patientId: json['patient_id'] ?? '',
      age: json['age'],
      gender: json['gender'],
      diabetesDurationYears: json['diabetes_duration_years'],
      eye: json['eye'] ?? 'OD',
      imagePath: json['image_path'] ?? '',
      imageSha256: json['image_sha256'],
      status: json['status'] == 'SYNCED'
          ? SyncStatus.uploaded
          : json['status'] == 'UPLOADING'
              ? SyncStatus.uploading
              : json['status'] == 'FAILED'
                  ? SyncStatus.syncFailed
                  : SyncStatus.queuedForUpload,
      serverScreeningId: json['server_screening_id'],
      errorMessage: json['error_message'],
      capturedAt: json['captured_at'] != null
          ? DateTime.tryParse(json['captured_at']) ?? DateTime.now()
          : DateTime.now(),
      retryCount: json['retry_count'] ?? 0,
    );
  }
}
