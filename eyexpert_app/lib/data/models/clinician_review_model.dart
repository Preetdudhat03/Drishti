enum ClinicianAction {
  validateAiResult,
  override,
  markUngradable;

  String get label {
    switch (this) {
      case ClinicianAction.validateAiResult:
        return 'VALIDATE_AI';
      case ClinicianAction.override:
        return 'OVERRIDE_GRADE';
      case ClinicianAction.markUngradable:
        return 'REJECT_RECAPTURE';
    }
  }

  static ClinicianAction fromString(String? action) {
    switch (action?.toUpperCase()) {
      case 'OVERRIDE':
      case 'OVERRIDE_GRADE':
      case 'CLINICIAN_OVERRIDDEN':
        return ClinicianAction.override;
      case 'MARK_UNGRADABLE':
      case 'REJECT_RECAPTURE':
      case 'UNGRADABLE':
        return ClinicianAction.markUngradable;
      case 'VALIDATE_AI':
      case 'VALIDATE_AI_RESULT':
      case 'CONFIRMED':
      case 'CLINICIAN_VALIDATED':
      default:
        return ClinicianAction.validateAiResult;
    }
  }
}

class ClinicianReviewModel {
  final ClinicianAction action;
  final String? clinicianId;
  final String? clinicianName;
  final String? clinicianRole;
  final int? finalDrLevel;
  final String? finalDrLabel;
  final bool? finalReferable;
  final String clinicalNotes;
  final int? recommendedFollowupDays;
  final DateTime reviewedAt;

  const ClinicianReviewModel({
    required this.action,
    this.clinicianId,
    this.clinicianName,
    this.clinicianRole,
    this.finalDrLevel,
    this.finalDrLabel,
    this.finalReferable,
    required this.clinicalNotes,
    this.recommendedFollowupDays,
    required this.reviewedAt,
  });

  bool get isValidated => action == ClinicianAction.validateAiResult;
  bool get isOverridden => action == ClinicianAction.override;
  bool get isUngradable => action == ClinicianAction.markUngradable;

  factory ClinicianReviewModel.fromJson(Map<String, dynamic> json) {
    return ClinicianReviewModel(
      action: ClinicianAction.fromString(json['action']),
      clinicianId: json['clinician_id'],
      clinicianName: json['clinician_name'],
      clinicianRole: json['clinician_role'] ?? 'Ophthalmologist',
      finalDrLevel: json['final_dr_level'],
      finalDrLabel: json['final_dr_label'],
      finalReferable: json['final_referable'],
      clinicalNotes: json['clinical_notes'] ?? '',
      recommendedFollowupDays: json['recommended_followup_days'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action.label,
      'clinician_id': clinicianId,
      'clinician_name': clinicianName,
      'clinician_role': clinicianRole,
      'final_dr_level': finalDrLevel,
      'final_dr_label': finalDrLabel,
      'final_referable': finalReferable,
      'clinical_notes': clinicalNotes,
      'recommended_followup_days': recommendedFollowupDays,
      'reviewed_at': reviewedAt.toIso8601String(),
    };
  }
}
