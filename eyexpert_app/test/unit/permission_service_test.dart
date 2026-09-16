import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_app/data/models/user_model.dart';
import 'package:drishti_app/core/permissions/permission_service.dart';

void main() {
  group('PermissionService RBAC Matrix Tests', () {
    const healthWorker = UserModel(
      id: 'HW-001',
      name: 'Sunita Sharma',
      role: UserRole.healthWorker,
      organization: 'PHC Ramgarh',
      facilityId: 'PHC-01',
    );

    const ophthalmologist = UserModel(
      id: 'DOC-001',
      name: 'Dr. Rajesh Kumar',
      role: UserRole.clinician,
      organization: 'District Eye Hospital',
      facilityId: 'DEH-01',
      professionalId: 'MCI-2018-84729',
    );

    test('PHC Health Worker permissions', () {
      const permissions = PermissionService(healthWorker);

      // Primary field intake permissions
      expect(permissions.canCreateScreening, isTrue);
      expect(permissions.canCaptureFundus, isTrue);
      expect(permissions.canRunQualityCheck, isTrue);
      expect(permissions.canTriggerAiScreening, isTrue);
      expect(permissions.canRegisterPatient, isTrue);
      expect(permissions.canSubmitCase, isTrue);
      expect(permissions.hasPermission(AppPermission.captureFundusImage), isTrue);
      expect(permissions.hasPermission(AppPermission.imageQualityAssessment), isTrue);
      expect(permissions.hasPermission(AppPermission.aiScreening), isTrue);

      // Clinical decision & specialist review restrictions (strictly prohibited)
      expect(permissions.canAccessReviewQueue, isFalse);
      expect(permissions.canClaimCase, isFalse);
      expect(permissions.canViewGradCam, isFalse);
      expect(permissions.canValidateAi, isFalse);
      expect(permissions.canOverrideDrLevel, isFalse);
      expect(permissions.canMakeFinalDecision, isFalse);
      expect(permissions.canFinalizeReport, isFalse);
      expect(permissions.canViewAllReports, isFalse);
    });

    test('Ophthalmologist permissions', () {
      const permissions = PermissionService(ophthalmologist);

      // Specialist Review & Validation permissions
      expect(permissions.canAccessReviewQueue, isTrue);
      expect(permissions.canClaimCase, isTrue);
      expect(permissions.canViewGradCam, isTrue);
      expect(permissions.canValidateAi, isTrue);
      expect(permissions.canOverrideDrLevel, isTrue);
      expect(permissions.canMakeFinalDecision, isTrue);
      expect(permissions.canFinalizeReport, isTrue);
      expect(permissions.canViewAllReports, isTrue);
      expect(permissions.hasPermission(AppPermission.editClinicalNotes), isTrue);

      // Field intake & screening creation restrictions (strictly prohibited)
      expect(permissions.canCreateScreening, isFalse);
      expect(permissions.canCaptureFundus, isFalse);
      expect(permissions.canRunQualityCheck, isFalse);
      expect(permissions.canTriggerAiScreening, isFalse);
      expect(permissions.canRegisterPatient, isFalse);
      expect(permissions.canSubmitCase, isFalse);
    const unknownUser = UserModel(
      id: 'UNKN-001',
      name: 'Unknown Operator',
      role: UserRole.unknown,
      organization: 'Unverified Center',
      facilityId: 'UNKN-01',
    );

    test('Unknown / Unverified Role permissions (Fail Closed)', () {
      const permissions = PermissionService(unknownUser);

      // Verify fail-closed behavior: NO permissions granted
      expect(permissions.canCreateScreening, isFalse);
      expect(permissions.canCaptureFundus, isFalse);
      expect(permissions.canRunQualityCheck, isFalse);
      expect(permissions.canTriggerAiScreening, isFalse);
      expect(permissions.canRegisterPatient, isFalse);
      expect(permissions.canSubmitCase, isFalse);

      expect(permissions.canAccessReviewQueue, isFalse);
      expect(permissions.canClaimCase, isFalse);
      expect(permissions.canViewGradCam, isFalse);
      expect(permissions.canValidateAi, isFalse);
      expect(permissions.canOverrideDrLevel, isFalse);
      expect(permissions.canMakeFinalDecision, isFalse);
      expect(permissions.canFinalizeReport, isFalse);
      expect(permissions.canViewAllReports, isFalse);

      expect(permissions.hasPermission(AppPermission.login), isFalse);
      expect(permissions.hasPermission(AppPermission.systemAdministration), isFalse);
    });

    test('Null User permissions evaluate to false', () {
      const permissions = PermissionService(null);
      expect(permissions.role, equals(UserRole.unknown));
      expect(permissions.canCreateScreening, isFalse);
      expect(permissions.canAccessReviewQueue, isFalse);
      expect(permissions.hasPermission(AppPermission.login), isFalse);
    });

    test('UserModel.fromString strict mapping and fail-closed resolution', () {
      // Clinician mappings
      expect(UserModel.fromString('CLINICIAN'), equals(UserRole.clinician));
      expect(UserModel.fromString('Ophthalmologist'), equals(UserRole.clinician));
      expect(UserModel.fromString('Doctor'), equals(UserRole.clinician));
      expect(UserModel.fromString('Retina Specialist'), equals(UserRole.clinician));
      expect(UserModel.fromString('Eye Surgeon'), equals(UserRole.clinician));

      // Health Worker mappings
      expect(UserModel.fromString('HEALTH_WORKER'), equals(UserRole.healthWorker));
      expect(UserModel.fromString('phc_worker'), equals(UserRole.healthWorker));
      expect(UserModel.fromString('PHC Worker'), equals(UserRole.healthWorker));
      expect(UserModel.fromString('Nurse'), equals(UserRole.healthWorker));
      expect(UserModel.fromString('ASHA'), equals(UserRole.healthWorker));
      expect(UserModel.fromString('Operator'), equals(UserRole.healthWorker));

      // Admin mappings
      expect(UserModel.fromString('ADMIN'), equals(UserRole.admin));
      expect(UserModel.fromString('Administrator'), equals(UserRole.admin));

      // Fail closed / Unknown mappings
      expect(UserModel.fromString(null), equals(UserRole.unknown));
      expect(UserModel.fromString(''), equals(UserRole.unknown));
      expect(UserModel.fromString('GUEST'), equals(UserRole.unknown));
      expect(UserModel.fromString('PATIENT'), equals(UserRole.unknown));
      expect(UserModel.fromString('RANDOM_STRING_123'), equals(UserRole.unknown));
    });
  });
}
