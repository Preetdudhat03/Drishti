import 'dr_prediction_model.dart';

class ServiceHealth {
  final String status; // 'ONLINE' or 'OFFLINE'
  final int latencyMs;

  const ServiceHealth({required this.status, required this.latencyMs});

  bool get isOnline => status.toUpperCase() == 'ONLINE';

  factory ServiceHealth.fromJson(Map<String, dynamic> json) {
    return ServiceHealth(
      status: json['status'] ?? 'OFFLINE',
      latencyMs: json['latency_ms'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'latency_ms': latencyMs,
      };
}

class SystemStatusModel {
  final String status; // 'HEALTHY', 'DEGRADED', 'OFFLINE'
  final DateTime timestamp;
  final Map<String, ServiceHealth> services;
  final ModelProvenanceModel modelProvenance;
  final int pendingSyncCount;

  const SystemStatusModel({
    required this.status,
    required this.timestamp,
    required this.services,
    required this.modelProvenance,
    this.pendingSyncCount = 0,
  });

  bool get isAllOnline =>
      services.values.every((s) => s.isOnline) && status == 'HEALTHY';

  factory SystemStatusModel.fromJson(Map<String, dynamic> json) {
    final Map<String, ServiceHealth> servicesMap = {};
    if (json['services'] != null) {
      (json['services'] as Map).forEach((k, v) {
        servicesMap[k.toString()] =
            ServiceHealth.fromJson(v as Map<String, dynamic>);
      });
    }

    return SystemStatusModel(
      status: json['status'] ?? 'HEALTHY',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      services: servicesMap,
      modelProvenance: json['model_provenance'] != null
          ? ModelProvenanceModel.fromJson(json['model_provenance'])
          : ModelProvenanceModel.defaultProvenance,
      pendingSyncCount: json['pending_sync_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> servJson = {};
    services.forEach((k, v) => servJson[k] = v.toJson());

    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'services': servJson,
      'model_provenance': modelProvenance.toJson(),
      'pending_sync_count': pendingSyncCount,
    };
  }

  static SystemStatusModel get defaultHealthy => SystemStatusModel(
        status: 'HEALTHY',
        timestamp: DateTime.now(),
        services: const {
          'ai_engine': ServiceHealth(status: 'ONLINE', latencyMs: 142),
          'image_quality_gate': ServiceHealth(status: 'ONLINE', latencyMs: 38),
          'gradcam_engine': ServiceHealth(status: 'ONLINE', latencyMs: 210),
          'report_generator': ServiceHealth(status: 'ONLINE', latencyMs: 65),
          'database': ServiceHealth(status: 'ONLINE', latencyMs: 12),
        },
        modelProvenance: ModelProvenanceModel.defaultProvenance,
        pendingSyncCount: 0,
      );
}
