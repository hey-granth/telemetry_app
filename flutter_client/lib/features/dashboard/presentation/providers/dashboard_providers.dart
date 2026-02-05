import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../../../../core/networking/websocket_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/connection_indicator.dart';
import '../../domain/models/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// Connection status provider for WebSocket state
final connectionStatusProvider = StateProvider<ConnectionStatus>((ref) {
  return ConnectionStatus.disconnected;
});

/// WebSocket connection manager provider
final wsConnectionProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient(
    onConnectionStateChange: (state) {
      final status = switch (state) {
        WsConnectionState.connected => ConnectionStatus.connected,
        WsConnectionState.connecting => ConnectionStatus.connecting,
        WsConnectionState.reconnecting => ConnectionStatus.connecting,
        WsConnectionState.disconnected => ConnectionStatus.disconnected,
      };
      ref.read(connectionStatusProvider.notifier).state = status;
    },
  );

  ref.onDispose(() {
    client.disconnect();
  });

  return client;
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ApiClient(baseUrl: AppConfig.apiBaseUrl);
  return DashboardRepository(apiClient);
});

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getDashboardStats();

  return result.when(
    success: (stats) => stats,
    failure: (error) => throw Exception(error),
  );
});

final systemHealthProvider =
    FutureProvider.autoDispose<SystemHealth>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getSystemHealth();

  return result.when(
    success: (health) => health,
    failure: (error) => throw Exception(error),
  );
});

// Auto-refresh provider that combines stats and health
final dashboardDataProvider =
    FutureProvider.autoDispose<({DashboardStats stats, SystemHealth health})>(
        (ref) async {
  final statsResult = await ref.watch(dashboardStatsProvider.future);
  final healthResult = await ref.watch(systemHealthProvider.future);

  return (stats: statsResult, health: healthResult);
});
