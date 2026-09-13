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
    });
  });
}
