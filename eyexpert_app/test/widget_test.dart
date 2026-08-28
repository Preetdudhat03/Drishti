import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eyexpert_app/main.dart';

void main() {
  testWidgets('Drishti App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DrishtiApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DrishtiApp), findsOneWidget);
  });
}
