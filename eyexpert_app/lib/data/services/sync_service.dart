import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/sync_queue_item.dart';
import '../models/patient_model.dart';
import '../models/screening_case_model.dart';
import 'supabase_service.dart';

class SyncService {
  static const String _storageKey = 'drishti_offline_sync_queue';
  final List<SyncQueueItem> _queue = [];
  final SupabaseService _supabaseService;
  bool _isOnline = true;
  bool _isSyncing = false;

  final _syncStreamController = StreamController<List<SyncQueueItem>>.broadcast();

  SyncService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService() {
    _loadPersistedQueue();
  }

  List<SyncQueueItem> get queue => List.unmodifiable(_queue);
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingCount => _queue
      .where((i) => i.status == SyncStatus.queuedForUpload || i.status == SyncStatus.syncFailed)
      .length;
  Stream<List<SyncQueueItem>> get queueStream => _syncStreamController.stream;

  Future<void> _loadPersistedQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        _queue.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _queue.add(SyncQueueItem.fromJson(item));
          }
        }
        _syncStreamController.add(_queue);
      }
    } catch (e) {
      debugPrint('[SyncService] Failed to load persisted queue: $e');
    }
  }

  Future<void> _persistQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _queue.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[SyncService] Failed to persist queue: $e');
    }
  }

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
    await _persistQueue();

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
          final serverId = 'EX-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

          // 1. Upload fundus image to Supabase Storage if initialized
          String? uploadedImageUrl;
          if (SupabaseService.isInitialized && item.imagePath.isNotEmpty) {
            final file = File(item.imagePath);
            if (await file.exists()) {
              uploadedImageUrl = await _supabaseService.uploadFundusImage(
                screeningId: serverId,
                facilityId: 'PHC-RAMGARH-01',
                imageBytesOrFile: file,
                filename: 'fundus_photo.jpg',
              );
            }
          }

          // 2. Register Screening Case in Supabase cloud
          if (SupabaseService.isInitialized) {
            final patient = PatientModel(
              patientId: item.patientId,
              age: item.age,
              gender: item.gender,
              diabetesDurationYears: item.diabetesDurationYears,
              eye: item.eye,
              facilityId: 'PHC-RAMGARH-01',
              createdAt: item.capturedAt,
            );

            final newCase = ScreeningCaseModel(
              screeningId: serverId,
              clientRequestId: item.clientRequestId,
              patient: patient,
              image: FundusImageData(
                imageId: serverId,
                imageUrl: uploadedImageUrl ?? item.imagePath,
                localPath: item.imagePath,
                uploadedAt: DateTime.now(),
              ),
              status: ScreeningStatus.readyForReview,
              createdAt: item.capturedAt,
              updatedAt: DateTime.now(),
            );

            await _supabaseService.saveScreeningCase(newCase);
          }

          _queue[i] = item.copyWith(
            status: SyncStatus.uploaded,
            serverScreeningId: serverId,
          );
        } catch (e) {
          debugPrint('[SyncService] Sync failed for ${item.localId}: $e');
          _queue[i] = item.copyWith(
            status: SyncStatus.syncFailed,
            errorMessage: e.toString(),
            retryCount: item.retryCount + 1,
          );
        }
        _syncStreamController.add(_queue);
        await _persistQueue();
      }
    }

    _isSyncing = false;
  }

  void clearCompleted() {
    _queue.removeWhere((i) => i.status == SyncStatus.uploaded);
    _syncStreamController.add(_queue);
    _persistQueue();
  }
}
