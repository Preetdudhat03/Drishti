import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/sync_queue_item.dart';
import '../models/patient_model.dart';
import '../models/screening_case_model.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';

class SyncService {
  final ApiClient _apiClient;
  final List<SyncQueueItem> _queue = [];
  bool _isOnline = true;
  bool _isSyncing = false;

  final _syncStreamController = StreamController<List<SyncQueueItem>>.broadcast();

  SyncService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  List<SyncQueueItem> get queue => List.unmodifiable(_queue);
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _queue.where((i) => i.status == SyncStatus.queuedForUpload || i.status == SyncStatus.syncFailed).length;
  Stream<List<SyncQueueItem>> get queueStream => _syncStreamController.stream;

  void setOnlineStatus(bool online) {
    _isOnline = online;
    if (_isOnline && pendingCount > 0) {
      syncPendingQueue();
    }
  }

  Future<SyncQueueItem> queueOfflineCapture({
    required PatientModel patient,
    required String imagePath,
    String? sha256,
  }) async {
    final item = SyncQueueItem(
      localId: 'LOC-${const Uuid().v4().substring(0, 8)}',
      clientRequestId: 'IDEMP-${const Uuid().v4()}',
      patientId: patient.patientId,
      age: patient.age,
      gender: patient.gender,
      diabetesDurationYears: patient.diabetesDurationYears,
      eye: patient.eye,
      imagePath: imagePath,
      imageSha256: sha256,
      status: SyncStatus.queuedForUpload,
      capturedAt: DateTime.now(),
    );

    _queue.add(item);
    _syncStreamController.add(_queue);

    if (_isOnline) {
      syncPendingQueue();
    }

    return item;
  }

  Future<void> syncPendingQueue() async {
    if (_isSyncing || !_isOnline) return;
    _isSyncing = true;

    for (int i = 0; i < _queue.length; i++) {
      final item = _queue[i];
      if (item.status == SyncStatus.queuedForUpload || item.status == SyncStatus.syncFailed) {
        _queue[i] = item.copyWith(status: SyncStatus.uploading);
        _syncStreamController.add(_queue);

        try {
          // Simulate / execute server sync
          await Future.delayed(const Duration(milliseconds: 600));
          final serverId = 'EX-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
          _queue[i] = item.copyWith(
            status: SyncStatus.uploaded,
            serverScreeningId: serverId,
          );
        } catch (e) {
          _queue[i] = item.copyWith(
            status: SyncStatus.syncFailed,
            errorMessage: e.toString(),
            retryCount: item.retryCount + 1,
          );
        }
        _syncStreamController.add(_queue);
      }
    }

    _isSyncing = false;
  }

  void clearCompleted() {
    _queue.removeWhere((i) => i.status == SyncStatus.uploaded);
    _syncStreamController.add(_queue);
  }
}
