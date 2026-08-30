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
  validateAiResult,
  overrideDrLevel,
  editClinicalNotes,
  makeFinalClinicalDecision,
  viewAllReports,
  systemAdministration,
}

class PermissionService {
  final UserModel? user;

  const PermissionService(this.user);

  UserRole get role => user?.role ?? UserRole.healthWorker;

  bool hasPermission(AppPermission permission) {
    if (user == null) return false;

    switch (permission) {
      case AppPermission.login:
      case AppPermission.imageQualityAssessment:
      case AppPermission.aiScreening:
      case AppPermission.viewAiResult:
      case AppPermission.viewGradCam:
      case AppPermission.captureFundusImage:
        return true;

      case AppPermission.patientRegistration:
      case AppPermission.submitScreeningCase:
        return role == UserRole.healthWorker || role == UserRole.admin;

      case AppPermission.accessReviewQueue:
      case AppPermission.validateAiResult:
      case AppPermission.overrideDrLevel:
      case AppPermission.editClinicalNotes:
      case AppPermission.makeFinalClinicalDecision:
      case AppPermission.viewAllReports:
        return role == UserRole.clinician || role == UserRole.admin;

      case AppPermission.systemAdministration:
        return role == UserRole.admin;
    }
  }

  // Quick helper getters
  bool get canRegisterPatient => hasPermission(AppPermission.patientRegistration);
  bool get canSubmitCase => hasPermission(AppPermission.submitScreeningCase);
  bool get canAccessReviewQueue => hasPermission(AppPermission.accessReviewQueue);
  bool get canValidateAi => hasPermission(AppPermission.validateAiResult);
  bool get canOverrideDrLevel => hasPermission(AppPermission.overrideDrLevel);
  bool get canMakeFinalDecision => hasPermission(AppPermission.makeFinalClinicalDecision);
  bool get canViewAllReports => hasPermission(AppPermission.viewAllReports);
}
