import '../../data/models/user_model.dart';

enum AppPermission {
  login,
  patientRegistration,
  captureFundusImage,
  imageQualityAssessment,
  aiScreening,
  viewAiResult,
  viewGradCam,
  submitScreeningCase,
  accessReviewQueue,
  claimCase,
  validateAiResult,
  overrideDrLevel,
  markUngradable,
  editClinicalNotes,
  makeFinalClinicalDecision,
  finalizeReport,
  viewAllReports,
  systemAdministration,
}

class PermissionService {
  final UserModel? user;

  const PermissionService(this.user);

  UserRole get role => user?.role ?? UserRole.unknown;

  bool hasPermission(AppPermission permission) {
    if (user == null || role == UserRole.unknown) return false;

    switch (permission) {
      case AppPermission.login:
        return true;
      case AppPermission.viewAiResult:
        return role == UserRole.healthWorker || role == UserRole.clinician || role == UserRole.admin;

      // PHC Health Worker Actions (Ophthalmologists strictly excluded)
      case AppPermission.patientRegistration:
      case AppPermission.captureFundusImage:
      case AppPermission.imageQualityAssessment:
      case AppPermission.aiScreening:
      case AppPermission.submitScreeningCase:
        return role == UserRole.healthWorker || role == UserRole.admin;

      // Ophthalmologist Specialist Actions (PHC Health Workers strictly excluded)
      case AppPermission.accessReviewQueue:
      case AppPermission.claimCase:
      case AppPermission.viewGradCam:
      case AppPermission.validateAiResult:
      case AppPermission.overrideDrLevel:
      case AppPermission.markUngradable:
      case AppPermission.editClinicalNotes:
      case AppPermission.makeFinalClinicalDecision:
      case AppPermission.finalizeReport:
      case AppPermission.viewAllReports:
        return role == UserRole.clinician || role == UserRole.admin;

      case AppPermission.systemAdministration:
        return role == UserRole.admin;
    }
  }

  // Quick helper getters
  bool get canCreateScreening => hasPermission(AppPermission.patientRegistration);
  bool get canCaptureFundus => hasPermission(AppPermission.captureFundusImage);
  bool get canRunQualityCheck => hasPermission(AppPermission.imageQualityAssessment);
  bool get canTriggerAiScreening => hasPermission(AppPermission.aiScreening);
  bool get canRegisterPatient => hasPermission(AppPermission.patientRegistration);
  bool get canSubmitCase => hasPermission(AppPermission.submitScreeningCase);

  bool get canAccessReviewQueue => hasPermission(AppPermission.accessReviewQueue);
  bool get canClaimCase => hasPermission(AppPermission.claimCase);
  bool get canViewGradCam => hasPermission(AppPermission.viewGradCam);
  bool get canValidateAi => hasPermission(AppPermission.validateAiResult);
  bool get canOverrideDrLevel => hasPermission(AppPermission.overrideDrLevel);
  bool get canMakeFinalDecision => hasPermission(AppPermission.makeFinalClinicalDecision);
  bool get canFinalizeReport => hasPermission(AppPermission.finalizeReport);
  bool get canViewAllReports => hasPermission(AppPermission.viewAllReports);
}
