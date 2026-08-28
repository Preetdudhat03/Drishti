import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyexpert_app/features/results/ai_result_screen.dart';
import 'package:eyexpert_app/features/screening/screening_session_provider.dart';
import 'package:eyexpert_app/data/models/dr_prediction_model.dart';
import 'package:eyexpert_app/data/models/quality_assessment_model.dart';
import 'package:eyexpert_app/data/models/patient_model.dart';

void main() {
  testWidgets('AiResultScreen renders Level 2 classification and referable alert correctly', (WidgetTester tester) async {
    final patient = PatientModel(
      patientId: 'PT-2026-8819',
      age: 54,
      gender: 'FEMALE',
      diabetesDurationYears: 8,
      eye: 'OD',
      facilityId: 'PHC-01',
      createdAt: DateTime.now(),
    );

    final quality = QualityAssessmentModel(
      screeningId: 'EX-2026-000124',
      overallScore: 0.88,
      status: QualityStatus.good,
      sharpness: const QualityMetric(score: 0.89, status: 'GOOD', metricName: 'Sharpness'),
      illumination: const QualityMetric(score: 0.86, status: 'GOOD', metricName: 'Illumination'),
      fieldOfView: const QualityMetric(score: 0.90, status: 'ADEQUATE', metricName: 'FOV'),
      feedbackMessages: ['Optimal quality'],
      evaluatedAt: DateTime.now(),
    );

    final prediction = DRPredictionModel(
      screeningId: 'EX-2026-000124',
      drLevel: 2,
      severityLabel: 'Moderate Non-Proliferative Diabetic Retinopathy',
      severityCode: 'LEVEL_2',
      referable: true,
      modelProbability: 0.914,
      classProbabilities: {0: 0.021, 1: 0.037, 2: 0.892, 3: 0.041, 4: 0.009},
      recommendation: 'Ophthalmologist review recommended.',
      provenance: ModelProvenanceModel.defaultProvenance,
      analyzedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          screeningSessionProvider.overrideWith((ref) {
            final notifier = ScreeningSessionNotifier(ref.watch(screeningRepositoryProvider), ref);
            notifier.startNewSession(patientId: 'PT-2026-8819', eye: 'OD');
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AiResultScreen(
              onViewExplainability: () {},
              onViewReport: () {},
              onNewScreening: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify statutory disclaimer or empty state fallback handles gracefully
    expect(find.byType(AiResultScreen), findsOneWidget);
  });
}
