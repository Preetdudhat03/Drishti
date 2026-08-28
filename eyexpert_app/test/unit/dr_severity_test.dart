import 'package:flutter_test/flutter_test.dart';
import 'package:eyexpert_app/core/constants/dr_severity.dart';

void main() {
  group('DRSeverity & Referable DR Logic Tests', () {
    test('Level 0 mapping (No DR) should be non-referable', () {
      final sev = DRSeverity.fromLevel(0);
      expect(sev, DRSeverity.level0);
      expect(sev.isReferable, isFalse);
      expect(DRSeverity.checkIsReferable(0), isFalse);
    });

    test('Level 1 mapping (Mild NPDR) should be non-referable', () {
      final sev = DRSeverity.fromLevel(1);
      expect(sev, DRSeverity.level1);
      expect(sev.isReferable, isFalse);
      expect(DRSeverity.checkIsReferable(1), isFalse);
    });

    test('Level 2 mapping (Moderate NPDR) MUST be referable', () {
      final sev = DRSeverity.fromLevel(2);
      expect(sev, DRSeverity.level2);
      expect(sev.isReferable, isTrue);
      expect(DRSeverity.checkIsReferable(2), isTrue);
    });

    test('Level 3 mapping (Severe NPDR) MUST be referable', () {
      final sev = DRSeverity.fromLevel(3);
      expect(sev, DRSeverity.level3);
      expect(sev.isReferable, isTrue);
      expect(DRSeverity.checkIsReferable(3), isTrue);
    });

    test('Level 4 mapping (Proliferative DR) MUST be referable', () {
      final sev = DRSeverity.fromLevel(4);
      expect(sev, DRSeverity.level4);
      expect(sev.isReferable, isTrue);
      expect(DRSeverity.checkIsReferable(4), isTrue);
    });
  });
}
