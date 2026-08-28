import 'package:flutter_test/flutter_test.dart';
import 'package:eyexpert_app/data/models/clinician_review_model.dart';
import 'package:eyexpert_app/data/services/review_service.dart';
import 'package:eyexpert_app/core/errors/app_exceptions.dart';

void main() {
  group('ClinicianReview Validation and Override Tests', () {
    late ReviewService reviewService;

    setUp(() {
      reviewService = ReviewService();
    });

    test('Validate AI Result successfully creates confirmation record', () async {
      final updated = await reviewService.submitClinicianReview(
        screeningId: 'EX-2026-000124',
        action: ClinicianAction.validateAiResult,
        finalDrLevel: 2,
        clinicalNotes: 'AI Level 2 validated by clinician.',
        clinicianName: 'Dr. Rajesh Kumar',
        isDemo: true,
      );

      expect(updated.review, isNotNull);
      expect(updated.review!.action, ClinicianAction.validateAiResult);
      expect(updated.review!.finalDrLevel, 2);
      expect(updated.review!.finalReferable, isTrue);
    });

    test('Override requires clinical notes and valid finalDrLevel', () async {
      expect(
        () async => await reviewService.submitClinicianReview(
          screeningId: 'EX-2026-000124',
          action: ClinicianAction.override,
          finalDrLevel: 3,
          clinicalNotes: '', // Empty notes should fail
          isDemo: true,
        ),
        throwsA(isA<AppException>()),
      );
    });

    test('Override with proper notes updates final level and status', () async {
      final updated = await reviewService.submitClinicianReview(
        screeningId: 'EX-2026-000124',
        action: ClinicianAction.override,
        finalDrLevel: 3,
        clinicalNotes: 'Multiple hemorrhages observed in four quadrants; upgrading to Level 3 Severe NPDR.',
        clinicianName: 'Dr. Rajesh Kumar',
        isDemo: true,
      );

      expect(updated.review!.action, ClinicianAction.override);
      expect(updated.review!.finalDrLevel, 3);
      expect(updated.review!.finalReferable, isTrue);
      expect(updated.review!.clinicalNotes, contains('upgrading to Level 3'));
    });
  });
}
