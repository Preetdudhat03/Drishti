import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum DocumentVerificationStatus {
  notUploaded,
  uploaded,
  underReview,
  verified,
  rejected;

  String get label {
    switch (this) {
      case DocumentVerificationStatus.notUploaded:
        return 'NOT UPLOADED';
      case DocumentVerificationStatus.uploaded:
        return 'UPLOADED';
      case DocumentVerificationStatus.underReview:
        return 'UNDER REVIEW';
      case DocumentVerificationStatus.verified:
        return 'VERIFIED';
      case DocumentVerificationStatus.rejected:
        return 'REQUIRES CORRECTION';
    }
  }

  String get code {
    switch (this) {
      case DocumentVerificationStatus.notUploaded:
        return 'NOT_UPLOADED';
      case DocumentVerificationStatus.uploaded:
        return 'UPLOADED';
      case DocumentVerificationStatus.underReview:
        return 'UNDER_REVIEW';
      case DocumentVerificationStatus.verified:
        return 'VERIFIED';
      case DocumentVerificationStatus.rejected:
        return 'REJECTED';
    }
  }

  Color get color {
    switch (this) {
      case DocumentVerificationStatus.notUploaded:
        return AppColors.textMuted;
      case DocumentVerificationStatus.uploaded:
        return AppColors.pending;
      case DocumentVerificationStatus.underReview:
        return AppColors.statusBorderline;
      case DocumentVerificationStatus.verified:
        return AppColors.statusGood;
      case DocumentVerificationStatus.rejected:
        return AppColors.statusCritical;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case DocumentVerificationStatus.notUploaded:
        return Colors.grey.shade100;
      case DocumentVerificationStatus.uploaded:
        return AppColors.pendingBg;
      case DocumentVerificationStatus.underReview:
        return AppColors.statusBorderlineBg;
      case DocumentVerificationStatus.verified:
        return AppColors.statusGoodBg;
      case DocumentVerificationStatus.rejected:
        return AppColors.statusUngradableBg;
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentVerificationStatus.notUploaded:
        return Icons.upload_file_outlined;
      case DocumentVerificationStatus.uploaded:
        return Icons.file_present_rounded;
      case DocumentVerificationStatus.underReview:
        return Icons.hourglass_top_rounded;
      case DocumentVerificationStatus.verified:
        return Icons.verified_rounded;
      case DocumentVerificationStatus.rejected:
        return Icons.error_outline_rounded;
    }
  }

  static DocumentVerificationStatus fromString(String? val) {
    if (val == null) return DocumentVerificationStatus.notUploaded;
    final norm = val.trim().toUpperCase();
    if (norm == 'VERIFIED' || norm == 'APPROVED') return DocumentVerificationStatus.verified;
    if (norm == 'UNDER_REVIEW' || norm == 'PENDING_REVIEW' || norm == 'IN_REVIEW') {
      return DocumentVerificationStatus.underReview;
    }
    if (norm == 'UPLOADED') return DocumentVerificationStatus.uploaded;
    if (norm == 'REJECTED' || norm == 'REQUIRES_CORRECTION' || norm == 'INVALID') {
      return DocumentVerificationStatus.rejected;
    }
    return DocumentVerificationStatus.notUploaded;
  }
}

class VerificationDocumentModel {
  final String id;
  final String userId;
  final String? facilityId;
  final String documentType;
  final String documentTitle;
  final String fileName;
  final String storagePath;
  final String mimeType;
  final int fileSizeBytes;
  final DocumentVerificationStatus verificationStatus;
  final DateTime? uploadedAt;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final bool isMandatory;

  const VerificationDocumentModel({
    required this.id,
    required this.userId,
    this.facilityId,
    required this.documentType,
    required this.documentTitle,
    required this.fileName,
    required this.storagePath,
    this.mimeType = 'application/pdf',
    this.fileSizeBytes = 0,
    this.verificationStatus = DocumentVerificationStatus.uploaded,
    this.uploadedAt,
    this.reviewedAt,
    this.reviewNotes,
    this.isMandatory = true,
  });

  bool get isVerified => verificationStatus == DocumentVerificationStatus.verified;
  bool get isUploaded => verificationStatus != DocumentVerificationStatus.notUploaded;

  factory VerificationDocumentModel.fromJson(Map<String, dynamic> json) {
    return VerificationDocumentModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      facilityId: json['facility_id']?.toString(),
      documentType: json['document_type']?.toString() ?? 'OTHER',
      documentTitle: json['document_title']?.toString() ?? _defaultTitle(json['document_type']?.toString()),
      fileName: json['file_name']?.toString() ?? 'document.pdf',
      storagePath: json['storage_path']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? 'application/pdf',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      verificationStatus: DocumentVerificationStatus.fromString(json['verification_status']?.toString()),
      uploadedAt: json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at'].toString()) : null,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'].toString()) : null,
      reviewNotes: json['review_notes']?.toString(),
      isMandatory: json['is_mandatory'] is bool ? json['is_mandatory'] : true,
    );
  }

  static String _defaultTitle(String? type) {
    switch (type) {
      case 'PHC_REGISTRATION':
        return 'Facility Registration / Authorization';
      case 'FACILITY_PROOF':
        return 'PHC Identity / Facility Proof';
      case 'PERSONNEL_AUTHORIZATION':
        return 'Authorized Personnel Document';
      case 'MEDICAL_REGISTRATION_CERT':
        return 'Medical Council Registration Certificate';
      case 'DEGREE_QUALIFICATION':
        return 'Medical Degree / Specialization Certificate';
      case 'PROFESSIONAL_ID_PROOF':
        return 'Government / Professional Identity Document';
      case 'HOSPITAL_ASSOCIATION_PROOF':
        return 'Hospital / Clinic Association Proof';
      default:
        return 'Supporting Verification Document';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'facility_id': facilityId,
      'document_type': documentType,
      'document_title': documentTitle,
      'file_name': fileName,
      'storage_path': storagePath,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'verification_status': verificationStatus.code,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'review_notes': reviewNotes,
      'is_mandatory': isMandatory,
    };
  }

  VerificationDocumentModel copyWith({
    String? id,
    String? userId,
    String? facilityId,
    String? documentType,
    String? documentTitle,
    String? fileName,
    String? storagePath,
    String? mimeType,
    int? fileSizeBytes,
    DocumentVerificationStatus? verificationStatus,
    DateTime? uploadedAt,
    DateTime? reviewedAt,
    String? reviewNotes,
    bool? isMandatory,
  }) {
    return VerificationDocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      facilityId: facilityId ?? this.facilityId,
      documentType: documentType ?? this.documentType,
      documentTitle: documentTitle ?? this.documentTitle,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      isMandatory: isMandatory ?? this.isMandatory,
    );
  }
}
