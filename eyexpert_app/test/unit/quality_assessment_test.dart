import 'package:flutter_test/flutter_test.dart';
import 'package:eyexpert_app/data/models/quality_assessment_model.dart';

void main() {
  group('QualityAssessmentModel Domain Tests', () {
    test('GOOD quality parsing and flags', () {
      final json = {
        'screening_id': 'EX-001',
        'overall_score': 0.88,
        'status': 'GOOD',
        'sharpness': {'score': 0.89, 'status': 'GOOD', 'metric': 'Laplacian focus'},
        'illumination': {'score': 0.86, 'status': 'GOOD', 'metric': 'Exposure'},
        'field_of_view': {'score': 0.90, 'status': 'ADEQUATE', 'metric': 'FOV'},
        'enhancement_applied': false,
        'feedback_messages': ['Image quality is optimal for automated DR screening.'],
      };

      final q = QualityAssessmentModel.fromJson(json);
      expect(q.isGood, isTrue);
      expect(q.isUngradable, isFalse);
      expect(q.isBorderline, isFalse);
      expect(q.overallScore, 0.88);
      expect(q.enhancementApplied, isFalse);
    });

    test('BORDERLINE quality parsing and CLAHE enhancement flag', () {
      final json = {
        'screening_id': 'EX-002',
        'overall_score': 0.61,
        'status': 'BORDERLINE',
        'sharpness': {'score': 0.68, 'status': 'GOOD', 'metric': 'Laplacian focus'},
        'illumination': {'score': 0.48, 'status': 'ATTENTION', 'metric': 'Exposure'},
        'field_of_view': {'score': 0.72, 'status': 'ADEQUATE', 'metric': 'FOV'},
        'enhancement_applied': true,
        'feedback_messages': ['Sub-optimal exposure detected. Adaptive CLAHE enhancement will be applied.'],
      };

      final q = QualityAssessmentModel.fromJson(json);
      expect(q.isBorderline, isTrue);
      expect(q.isGood, isFalse);
      expect(q.isUngradable, isFalse);
      expect(q.enhancementApplied, isTrue);
    });

    test('UNGRADABLE quality strictly flags isUngradable', () {
      final json = {
        'screening_id': 'EX-003',
        'overall_score': 0.28,
        'status': 'UNGRADABLE',
        'sharpness': {'score': 0.16, 'status': 'POOR', 'metric': 'Laplacian focus'},
        'illumination': {'score': 0.42, 'status': 'ATTENTION', 'metric': 'Exposure'},
        'field_of_view': {'score': 0.35, 'status': 'INADEQUATE', 'metric': 'FOV'},
        'enhancement_applied': false,
        'feedback_messages': ['Severe blur detected.', 'Recapture required.'],
      };

      final q = QualityAssessmentModel.fromJson(json);
      expect(q.isUngradable, isTrue);
      expect(q.isGood, isFalse);
      expect(q.feedbackMessages.length, 2);
    });
  });
}
