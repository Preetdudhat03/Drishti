import 'patient_model.dart';
import 'quality_assessment_model.dart';
import 'dr_prediction_model.dart';
import 'explainability_model.dart';
import 'clinician_review_model.dart';

enum ScreeningStatus {
  created,
  awaitingImage,
  imageReceived,
  qualityCheck,
  borderlineEnhancement,
  aiProcessing,
  aiCompleted,
  reviewPending,
  readyForReview,
  pendingClinicianReview,
  ophthalmologistReview,
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
      case ScreeningStatus.qualityCheck:
        return 'QUALITY_CHECK';
      case ScreeningStatus.borderlineEnhancement:
        return 'BORDERLINE_ENHANCEMENT';
      case ScreeningStatus.aiProcessing:
        return 'AI_PROCESSING';
      case ScreeningStatus.aiCompleted:
        return 'AI_COMPLETED';
      case ScreeningStatus.reviewPending:
        return 'REVIEW_PENDING';
      case ScreeningStatus.readyForReview:
        return 'READY_FOR_REVIEW';
      case ScreeningStatus.pendingClinicianReview:
        return 'PENDING_REVIEW';
      case ScreeningStatus.ophthalmologistReview:
        return 'OPHTHALMOLOGIST_REVIEW';
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
      case 'QUALITY_CHECK':
      case 'QUALITY_ASSESSMENT':
        return ScreeningStatus.qualityCheck;
      case 'BORDERLINE_ENHANCEMENT':
        return ScreeningStatus.borderlineEnhancement;
      case 'AI_PROCESSING':
        return ScreeningStatus.aiProcessing;
      case 'AI_COMPLETED':
        return ScreeningStatus.aiCompleted;
      case 'REVIEW_PENDING':
        return ScreeningStatus.reviewPending;
      case 'READY_FOR_REVIEW':
        return ScreeningStatus.readyForReview;
      case 'PENDING_REVIEW':
      case 'PENDING_CLINICIAN_REVIEW':
        return ScreeningStatus.pendingClinicianReview;
      case 'OPHTHALMOLOGIST_REVIEW':
        return ScreeningStatus.ophthalmologistReview;
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
  final String clinicalDecision; // PENDING, AI_VALIDATED, AI_OVERRIDDEN, CLINICALLY_UNGRADABLE
  final String? serverSha256;
  final String? inferenceId;
  final String? assignedReviewerId;
  final DateTime? claimedAt;
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
    this.clinicalDecision = 'PENDING',
    this.serverSha256,
    this.inferenceId,
    this.assignedReviewerId,
    this.claimedAt,
    this.image,
    this.quality,
    this.prediction,
    this.explainability,
    this.review,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReferable {
    if (review != null && review!.finalReferable != null) {
      return review!.finalReferable!;
    }
    if (review != null && review!.finalDrLevel != null) {
      return review!.finalDrLevel! >= 2;
    }
    return prediction?.referable ?? false;
  }
  bool get hasReviewed =>
      review != null ||
      clinicalDecision == 'AI_VALIDATED' ||
      clinicalDecision == 'AI_OVERRIDDEN' ||
      status == ScreeningStatus.completed ||
      status == ScreeningStatus.clinicianValidated ||
      status == ScreeningStatus.clinicianOverridden;
  bool get isPendingReview =>
      !hasReviewed &&
      (status == ScreeningStatus.reviewPending ||
       status == ScreeningStatus.ophthalmologistReview ||
       status == ScreeningStatus.aiCompleted ||
       status == ScreeningStatus.readyForReview ||
       status == ScreeningStatus.pendingClinicianReview ||
       status == ScreeningStatus.aiProcessing ||
       status == ScreeningStatus.qualityCheck ||
       status == ScreeningStatus.imageReceived ||
       status == ScreeningStatus.created);

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
      clinicalDecision: json['clinical_decision'] ?? 'PENDING',
      serverSha256: json['server_sha256'],
      inferenceId: json['inference_id'],
      assignedReviewerId: json['assigned_reviewer_id'],
      claimedAt: json['claimed_at'] != null ? DateTime.tryParse(json['claimed_at']) : null,
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
      'clinical_decision': clinicalDecision,
      'server_sha256': serverSha256,
      'inference_id': inferenceId,
      'assigned_reviewer_id': assignedReviewerId,
      'claimed_at': claimedAt?.toIso8601String(),
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
    String? clinicalDecision,
    String? serverSha256,
    String? inferenceId,
    String? assignedReviewerId,
    DateTime? claimedAt,
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
      clinicalDecision: clinicalDecision ?? this.clinicalDecision,
      serverSha256: serverSha256 ?? this.serverSha256,
      inferenceId: inferenceId ?? this.inferenceId,
      assignedReviewerId: assignedReviewerId ?? this.assignedReviewerId,
      claimedAt: claimedAt ?? this.claimedAt,
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
