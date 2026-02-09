/// Backend health check service.
///
/// Non-blocking health check for backend availability.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/devices/presentation/providers/device_providers.dart';
import 'app_lifecycle.dart';

/// Health check service
class HealthCheckService {
  HealthCheckService(this._ref);

  final Ref _ref;
  bool _isChecking = false;

  /// Check backend health (non-blocking)
  Future<void> checkHealth() async {
    if (_isChecking) return;

    _isChecking = true;

    try {
      final apiClient = _ref.read(apiClientProvider);
      final result = await apiClient.get<Map<String, dynamic>>(
        '/health',
        parser: (data) => data as Map<String, dynamic>,
      );

      result.when(
        success: (_) {
          _ref.read(backendStatusProvider.notifier).markReachable();
        },
        failure: (error) {
          _ref.read(backendStatusProvider.notifier).markUnreachable(
            error.toString(),
          );
        },
      );
    } catch (e) {
      _ref.read(backendStatusProvider.notifier).markUnreachable(
        'Unexpected error: ${e.toString()}',
      );
    } finally {
      _isChecking = false;
    }
  }
}

/// Health check service provider
final healthCheckServiceProvider = Provider<HealthCheckService>((ref) {
  return HealthCheckService(ref);
});


