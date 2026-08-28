import '../models/system_status_model.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'sync_service.dart';

class SystemService {
  final ApiClient _apiClient;
  final SyncService _syncService;

  SystemService({ApiClient? apiClient, required SyncService syncService})
      : _apiClient = apiClient ?? ApiClient(),
        _syncService = syncService;

  Future<SystemStatusModel> getSystemStatus({bool isDemo = true}) async {
    if (isDemo) {
      return SystemStatusModel(
        status: _syncService.isOnline ? 'HEALTHY' : 'OFFLINE_MODE',
        timestamp: DateTime.now(),
        services: {
          'ai_engine': ServiceHealth(
            status: _syncService.isOnline ? 'ONLINE' : 'OFFLINE',
            latencyMs: _syncService.isOnline ? 142 : 0,
          ),
          'image_quality_gate': ServiceHealth(
            status: _syncService.isOnline ? 'ONLINE' : 'OFFLINE',
            latencyMs: _syncService.isOnline ? 38 : 0,
          ),
          'gradcam_engine': ServiceHealth(
            status: _syncService.isOnline ? 'ONLINE' : 'OFFLINE',
            latencyMs: _syncService.isOnline ? 210 : 0,
          ),
          'report_generator': ServiceHealth(
            status: _syncService.isOnline ? 'ONLINE' : 'OFFLINE',
            latencyMs: _syncService.isOnline ? 65 : 0,
          ),
          'database': const ServiceHealth(status: 'ONLINE', latencyMs: 12),
        },
        modelProvenance: ModelProvenanceModel.defaultProvenance,
        pendingSyncCount: _syncService.pendingCount,
      );
    }

    final response = await _apiClient.get(ApiEndpoints.systemStatus);
    return SystemStatusModel.fromJson(response);
  }
}
