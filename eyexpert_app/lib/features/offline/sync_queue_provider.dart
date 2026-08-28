import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sync_queue_item.dart';
import '../../data/models/patient_model.dart';
import '../../data/services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) => SyncService());

class SyncQueueState {
  final List<SyncQueueItem> queue;
  final bool isOnline;
  final bool isSyncing;

  const SyncQueueState({
    this.queue = const [],
    this.isOnline = true,
    this.isSyncing = false,
  });

  int get pendingCount =>
      queue.where((i) => i.status == SyncStatus.queuedForUpload || i.status == SyncStatus.syncFailed).length;
  int get syncedCount => queue.where((i) => i.status == SyncStatus.uploaded).length;

  SyncQueueState copyWith({
    List<SyncQueueItem>? queue,
    bool? isOnline,
    bool? isSyncing,
  }) {
    return SyncQueueState(
      queue: queue ?? this.queue,
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class SyncQueueNotifier extends StateNotifier<SyncQueueState> {
  final SyncService _syncService;

  SyncQueueNotifier(this._syncService) : super(const SyncQueueState()) {
    _syncService.queueStream.listen((q) {
      state = state.copyWith(queue: q, isSyncing: _syncService.isSyncing);
    });
  }

  void toggleOnlineStatus() {
    final next = !state.isOnline;
    _syncService.setOnlineStatus(next);
    state = state.copyWith(isOnline: next);
  }

  Future<void> queueCapture({
    required PatientModel patient,
    required String imagePath,
    String? sha256,
  }) async {
    await _syncService.queueOfflineCapture(
      patient: patient,
      imagePath: imagePath,
      sha256: sha256,
    );
  }

  Future<void> syncNow() async {
    await _syncService.syncPendingQueue();
  }

  void clearCompleted() {
    _syncService.clearCompleted();
  }
}

final syncQueueProvider =
    StateNotifierProvider<SyncQueueNotifier, SyncQueueState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncQueueNotifier(syncService);
});
