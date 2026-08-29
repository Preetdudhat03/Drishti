import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/services/supabase_service.dart';
import '../../data/api/api_endpoints.dart';

enum ConnectionStatus {
  online,
  offline,
  checking,
}

class ConnectionStateModel {
  final ConnectionStatus status;
  final bool supabaseConnected;
  final bool backendConnected;
  final DateTime lastChecked;
  final String? errorMessage;

  const ConnectionStateModel({
    this.status = ConnectionStatus.checking,
    this.supabaseConnected = false,
    this.backendConnected = false,
    required this.lastChecked,
    this.errorMessage,
  });

  bool get isOnline => status == ConnectionStatus.online;
  bool get isOffline => status == ConnectionStatus.offline;
  bool get isChecking => status == ConnectionStatus.checking;

  ConnectionStateModel copyWith({
    ConnectionStatus? status,
    bool? supabaseConnected,
    bool? backendConnected,
    DateTime? lastChecked,
    String? errorMessage,
  }) {
    return ConnectionStateModel(
      status: status ?? this.status,
      supabaseConnected: supabaseConnected ?? this.supabaseConnected,
      backendConnected: backendConnected ?? this.backendConnected,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage,
    );
  }
}

class ConnectionNotifier extends StateNotifier<ConnectionStateModel> {
  Timer? _periodicTimer;

  ConnectionNotifier()
      : super(ConnectionStateModel(
          status: ConnectionStatus.checking,
          lastChecked: DateTime.now(),
        )) {
    checkConnection();
    // Re-check connectivity every 30 seconds
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnection();
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> checkConnection() async {
    state = state.copyWith(status: ConnectionStatus.checking, errorMessage: null);

    bool supaOk = false;
    bool backendOk = false;
    String? errorDetails;

    // 1. Check Supabase Connectivity (re-initialize if needed)
    try {
      if (!SupabaseService.isInitialized) {
        await SupabaseService.initialize();
      }
      final client = SupabaseService.client;
      if (client != null) {
        await client
            .from('screenings')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 5));
        supaOk = true;
      }
    } catch (e) {
      supaOk = false;
      errorDetails = 'Supabase: ${e.toString()}';
    }

    // 2. Check Backend API Connectivity
    try {
      final res = await http
          .get(Uri.parse(ApiEndpoints.systemStatus))
          .timeout(const Duration(seconds: 4));
      backendOk = res.statusCode >= 200 && res.statusCode < 400;
    } catch (_) {
      backendOk = false;
    }

    final isOverallOnline = supaOk || backendOk;

    state = state.copyWith(
      status: isOverallOnline ? ConnectionStatus.online : ConnectionStatus.offline,
      supabaseConnected: supaOk,
      backendConnected: backendOk,
      lastChecked: DateTime.now(),
      errorMessage: isOverallOnline ? null : (errorDetails ?? 'No network or backend connection.'),
    );
  }
}

final connectionProvider =
    StateNotifierProvider<ConnectionNotifier, ConnectionStateModel>((ref) {
  return ConnectionNotifier();
});
