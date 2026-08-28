import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyexpert_app/main.dart';

void main() {
  testWidgets('EyeXpert App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EyeXpertApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(EyeXpertApp), findsOneWidget);
  });
}
