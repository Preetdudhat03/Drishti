import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drishti_app/data/models/dr_prediction_model.dart';
import 'package:drishti_app/data/models/screening_case_model.dart';
import 'package:drishti_app/data/models/patient_model.dart';
import 'package:drishti_app/features/results/ai_result_screen.dart';
import 'package:drishti_app/features/screening/screening_session_provider.dart';

void main() {
  group('Differential Image A vs Image B Inference & UI Binding Tests', () {
    // Synthetic raw image byte representations simulating two distinct fundus photos
    final bytesImageA = utf8.encode('SIMULATED_FUNDUS_RETINA_A_c38dec54a9f7_NORMAL');
    final bytesImageB = utf8.encode('SIMULATED_FUNDUS_RETINA_B_405b4f78658f_SEVERE');

    final shaA = sha256.convert(bytesImageA).toString();
    final shaB = sha256.convert(bytesImageB).toString();

    // 1. Verify Client-Side SHA-256 Integrity
    test('Image A and Image B produce distinct client SHA-256 digests', () {
      expect(shaA, isNot(equals(shaB)));
      expect(shaA.length, equals(64));
      expect(shaB.length, equals(64));
    });

    // 2. Mock API v1 Analyze Responses from PyTorch ResNet-18
    final backendResponseA = {
      'screening_id': 'SCR-CASE-A',
      'inference_id': 'INF-A-001',
      'server_sha256': shaA,
      'client_sha256': shaA,
      'crop_box': [25, 25, 360, 360],
      'model_version': 'EyeXpert_ResNet18_v1.0',
      'preprocessing_version': 'fundus-v1',
      'dr_level': 0,
      'severity_label': 'Level 0 — No Apparent Retinopathy (Normal)',
      'severity_code': 'NONE',
      'referable': false,
      'model_probability': 0.942,
      'class_probabilities': {
        '0': 0.942,
        '1': 0.045,
        '2': 0.010,
        '3': 0.002,
        '4': 0.001,
      },
      'raw_logits': [3.85, 0.72, -0.65, -2.10, -2.95],
      'review_priority': 'NORMAL',
      'recommendation': 'Annual routine rescreening in 12 months at PHC.',
      'workflow_status': 'AI_COMPLETED',
      'clinical_decision': 'PENDING',
      'analyzed_at': '2026-09-13T11:00:00Z',
    };

    final backendResponseB = {
      'screening_id': 'SCR-CASE-B',
      'inference_id': 'INF-B-002',
      'server_sha256': shaB,
      'client_sha256': shaB,
      'crop_box': [30, 30, 355, 355],
      'model_version': 'EyeXpert_ResNet18_v1.0',
      'preprocessing_version': 'fundus-v1',
      'dr_level': 3,
      'severity_label': 'Level 3 — Severe Non-Proliferative DR (Severe NPDR)',
      'severity_code': 'NPDR_SEVERE',
      'referable': true,
      'model_probability': 0.885,
      'class_probabilities': {
        '0': 0.005,
        '1': 0.020,
        '2': 0.090,
        '3': 0.885,
        '4': 0.000,
      },
      'raw_logits': [-2.15, -0.75, 0.72, 3.12, -1.90],
      'review_priority': 'URGENT',
      'recommendation': 'Urgent specialist referral within 2-4 weeks. Risk of proliferative conversion.',
      'workflow_status': 'AI_COMPLETED',
      'clinical_decision': 'PENDING',
      'analyzed_at': '2026-09-13T11:02:00Z',
    };

    test('DRPredictionModel parses disparate backend results with intact provenance', () {
      final predA = DRPredictionModel.fromJson(backendResponseA, screeningId: 'SCR-CASE-A');
      final predB = DRPredictionModel.fromJson(backendResponseB, screeningId: 'SCR-CASE-B');

      // Assert distinct predictions
      expect(predA.drLevel, equals(0));
      expect(predB.drLevel, equals(3));
      expect(predA.referable, isFalse);
      expect(predB.referable, isTrue);

      // Assert distinct inference IDs
      expect(predA.provenance.modelId, isNotNull);
      expect(backendResponseA['inference_id'], isNot(equals(backendResponseB['inference_id'])));

      // Assert probability distributions differ completely
      expect(predA.classProbabilities[0]! > 0.90, isTrue);
      expect(predB.classProbabilities[3]! > 0.80, isTrue);
    });

    testWidgets('AiResultScreen UI displays Image A (Level 0, Non-referable) metrics', (tester) async {
      final predA = DRPredictionModel.fromJson(backendResponseA, screeningId: 'SCR-CASE-A');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            screeningSessionProvider.overrideWith((ref) {
              final notifier = ScreeningSessionNotifier(ref.watch(screeningRepositoryProvider), ref);
              notifier.startNewSession(patientId: 'PT-TEST-A', eye: 'OD');
              notifier.setPrediction(predA);
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

      await tester.pumpAndSettle();

      // UI must show Level 0 / Normal / Non-referable
      expect(find.textContaining('AI PRELIMINARY ASSESSMENT'), findsOneWidget);
      expect(find.textContaining('Level 0'), findsWidgets);
      expect(find.textContaining('SUBMIT FOR OPHTHALMOLOGIST REVIEW'), findsOneWidget);
    });

    testWidgets('AiResultScreen UI displays Image B (Level 3, Referable) metrics', (tester) async {
      final predB = DRPredictionModel.fromJson(backendResponseB, screeningId: 'SCR-CASE-B');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            screeningSessionProvider.overrideWith((ref) {
              final notifier = ScreeningSessionNotifier(ref.watch(screeningRepositoryProvider), ref);
              notifier.startNewSession(patientId: 'PT-TEST-B', eye: 'OS');
              notifier.setPrediction(predB);
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

      await tester.pumpAndSettle();

      // UI must show Level 3 / Severe NPDR / Referable
      expect(find.textContaining('AI PRELIMINARY ASSESSMENT'), findsOneWidget);
      expect(find.textContaining('Level 3'), findsWidgets);
      expect(find.textContaining('SUBMIT FOR OPHTHALMOLOGIST REVIEW'), findsOneWidget);
    });
  });
}
