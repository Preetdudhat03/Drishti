import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drishti_app/features/results/ai_result_screen.dart';
import 'package:drishti_app/features/screening/screening_session_provider.dart';

void main() {
  testWidgets('AiResultScreen renders correctly with provider scope', (WidgetTester tester) async {
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
    expect(find.byType(AiResultScreen), findsOneWidget);
  });
}
