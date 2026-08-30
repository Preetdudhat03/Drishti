import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/system_status_model.dart';
import '../../data/services/system_service.dart';
import '../offline/sync_queue_provider.dart';

final systemServiceProvider = Provider<SystemService>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return SystemService(syncService: syncService);
});

final systemStatusProvider = FutureProvider.autoDispose<SystemStatusModel>((ref) async {
  final systemService = ref.watch(systemServiceProvider);
  return systemService.getSystemStatus();
});
