import 'package:flutter_test/flutter_test.dart';
import 'package:eyexpert_app/data/services/sync_service.dart';
import 'package:eyexpert_app/data/models/patient_model.dart';
import 'package:eyexpert_app/data/models/sync_queue_item.dart';

void main() {
  group('SyncService Offline & Rural Queue Tests', () {
    late SyncService syncService;

    setUp(() {
      syncService = SyncService();
    });

    test('Queueing capture when offline adds item to pending queue', () async {
      syncService.setOnlineStatus(false);
      expect(syncService.isOnline, isFalse);

      final patient = PatientModel(
        patientId: 'PT-2026-9901',
        age: 48,
        gender: 'MALE',
        diabetesDurationYears: 4,
        eye: 'OS',
        facilityId: 'PHC-01',
        createdAt: DateTime.now(),
      );

      final item = await syncService.queueOfflineCapture(
        patient: patient,
        imagePath: 'assets/sample_fundus/sample_good_normal.png',
      );

      expect(syncService.queue.length, 1);
      expect(syncService.pendingCount, 1);
      expect(item.patientId, 'PT-2026-9901');
      expect(item.status, SyncStatus.queuedForUpload);
    });

    test('Restoring connectivity automatically processes queued items', () async {
      syncService.setOnlineStatus(false);
      final patient = PatientModel(
        patientId: 'PT-2026-9902',
        age: 52,
        gender: 'FEMALE',
        diabetesDurationYears: 6,
        eye: 'OD',
        facilityId: 'PHC-01',
        createdAt: DateTime.now(),
      );

      await syncService.queueOfflineCapture(
        patient: patient,
        imagePath: 'assets/sample_fundus/sample_good_npdr_mild.png',
      );

      expect(syncService.pendingCount, 1);

      // Restore network
      syncService.setOnlineStatus(true);
      await Future.delayed(const Duration(milliseconds: 800));

      expect(syncService.isOnline, isTrue);
      expect(syncService.pendingCount, 0);
      expect(syncService.queue.first.status, SyncStatus.uploaded);
      expect(syncService.queue.first.serverScreeningId, isNotNull);
    });
  });
}
