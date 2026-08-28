import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyexpert_app/features/quality/image_quality_screen.dart';
import 'package:eyexpert_app/features/screening/screening_session_provider.dart';

void main() {
  testWidgets('ImageQualityScreen renders quality evaluation interface', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ImageQualityScreen(
              onProceedToProcessing: () {},
              onRetake: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Image Quality Assessment'), findsOneWidget);
  });
}
