import 'patient_model.dart';
import 'quality_assessment_model.dart';
import 'dr_prediction_model.dart';
import 'explainability_model.dart';
import 'clinician_review_model.dart';

enum ScreeningStatus {
  created,
  awaitingImage,
  imageReceived,
  qualityAssessment,
  borderlineEnhancement,
  aiProcessing,
  readyForReview,
  pendingClinicianReview,
  ungradable,
  recaptureRequired,
  clinicianValidated,
  clinicianOverridden,
  completed,
  processingFailed;

  String get label {
    switch (this) {
      case ScreeningStatus.created:
        return 'CREATED';
      case ScreeningStatus.awaitingImage:
        return 'AWAITING_IMAGE';
      case ScreeningStatus.imageReceived:
        return 'IMAGE_RECEIVED';
      case ScreeningStatus.qualityAssessment:
        return 'QUALITY_ASSESSMENT';
      case ScreeningStatus.borderlineEnhancement:
        return 'BORDERLINE_ENHANCEMENT';
      case ScreeningStatus.aiProcessing:
        return 'AI_PROCESSING';
      case ScreeningStatus.readyForReview:
        return 'READY_FOR_REVIEW';
      case ScreeningStatus.pendingClinicianReview:
        return 'PENDING_REVIEW';
      case ScreeningStatus.ungradable:
        return 'UNGRADABLE';
      case ScreeningStatus.recaptureRequired:
        return 'RECAPTURE_REQUIRED';
      case ScreeningStatus.clinicianValidated:
        return 'VALIDATED';
      case ScreeningStatus.clinicianOverridden:
        return 'OVERRIDDEN';
      case ScreeningStatus.completed:
        return 'COMPLETED';
      case ScreeningStatus.processingFailed:
        return 'FAILED';
    }
  }

  static ScreeningStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'AWAITING_IMAGE':
        return ScreeningStatus.awaitingImage;
      case 'IMAGE_RECEIVED':
        return ScreeningStatus.imageReceived;
      case 'QUALITY_ASSESSMENT':
        return ScreeningStatus.qualityAssessment;
      case 'BORDERLINE_ENHANCEMENT':
        return ScreeningStatus.borderlineEnhancement;
      case 'AI_PROCESSING':
        return ScreeningStatus.aiProcessing;
      case 'READY_FOR_REVIEW':
        return ScreeningStatus.readyForReview;
      case 'PENDING_REVIEW':
      case 'PENDING_CLINICIAN_REVIEW':
        return ScreeningStatus.pendingClinicianReview;
      case 'UNGRADABLE':
        return ScreeningStatus.ungradable;
      case 'RECAPTURE_REQUIRED':
        return ScreeningStatus.recaptureRequired;
      case 'CLINICIAN_VALIDATED':
      case 'VALIDATED':
        return ScreeningStatus.clinicianValidated;
      case 'CLINICIAN_OVERRIDDEN':
      case 'OVERRIDDEN':
        return ScreeningStatus.clinicianOverridden;
      case 'COMPLETED':
        return ScreeningStatus.completed;
      case 'FAILED':
      case 'PROCESSING_FAILED':
        return ScreeningStatus.processingFailed;
      case 'CREATED':
      default:
        return ScreeningStatus.created;
    }
  }
}

class FundusImageData {
  final String imageId;
  final String imageUrl;
  final String? localPath;
  final String? sha256;
  final String? captureDeviceModel;
  final DateTime uploadedAt;

  const FundusImageData({
    required this.imageId,
    required this.imageUrl,
    this.localPath,
    this.sha256,
    this.captureDeviceModel,
    required this.uploadedAt,
  });

  factory FundusImageData.fromJson(Map<String, dynamic> json) {
    return FundusImageData(
      imageId: json['image_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      localPath: json['local_path'],
      sha256: json['sha256'],
      captureDeviceModel: json['capture_device_model'],
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_id': imageId,
      'image_url': imageUrl,
      'local_path': localPath,
      'sha256': sha256,
      'capture_device_model': captureDeviceModel,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}

class ScreeningCaseModel {
  final String screeningId;
  final String? clientRequestId;
  final PatientModel patient;
  final ScreeningStatus status;
  final FundusImageData? image;
  final QualityAssessmentModel? quality;
  final DRPredictionModel? prediction;
  final ExplainabilityModel? explainability;
  final ClinicianReviewModel? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScreeningCaseModel({
    required this.screeningId,
    this.clientRequestId,
    required this.patient,
    required this.status,
    this.image,
    this.quality,
    this.prediction,
    this.explainability,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReferable => prediction?.referable ?? false;
  bool get hasReviewed => review != null;
  bool get isPendingReview =>
      status == ScreeningStatus.readyForReview ||
      status == ScreeningStatus.pendingClinicianReview;

  factory ScreeningCaseModel.fromJson(Map<String, dynamic> json) {
    return ScreeningCaseModel(
      screeningId: json['screening_id'] ?? '',
      clientRequestId: json['client_request_id'],
      patient: json['patient'] != null
          ? PatientModel.fromJson(json['patient'])
          : PatientModel(
              patientId: json['patient_id'] ?? 'Unknown',
              eye: json['eye'] ?? 'OD',
              facilityId: 'PHC-01',
              createdAt: DateTime.now(),
            ),
      status: ScreeningStatus.fromString(json['status']),
      image: json['image'] != null ? FundusImageData.fromJson(json['image']) : null,
      quality: json['quality'] != null
          ? QualityAssessmentModel.fromJson(json['quality'])
          : null,
      prediction: json['prediction'] != null
          ? DRPredictionModel.fromJson(json['prediction'],
              screeningId: json['screening_id'])
          : null,
      explainability: json['explainability'] != null
          ? ExplainabilityModel.fromJson(json['explainability'])
          : null,
      review: json['review'] != null
          ? ClinicianReviewModel.fromJson(json['review'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screening_id': screeningId,
      'client_request_id': clientRequestId,
      'patient': patient.toJson(),
      'status': status.label,
      'image': image?.toJson(),
      'quality': quality?.toJson(),
      'prediction': prediction?.toJson(),
      'explainability': explainability?.toJson(),
      'review': review?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ScreeningCaseModel copyWith({
    String? screeningId,
    String? clientRequestId,
    PatientModel? patient,
    ScreeningStatus? status,
    FundusImageData? image,
    QualityAssessmentModel? quality,
    DRPredictionModel? prediction,
    ExplainabilityModel? explainability,
    ClinicianReviewModel? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScreeningCaseModel(
      screeningId: screeningId ?? this.screeningId,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      patient: patient ?? this.patient,
      status: status ?? this.status,
      image: image ?? this.image,
      quality: quality ?? this.quality,
      prediction: prediction ?? this.prediction,
      explainability: explainability ?? this.explainability,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
