import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/networking/api_client.dart';
import '../models/device.dart';

/// Repository for device data access.
///
/// Provides a clean interface for device operations.
/// Abstracts network communication from the presentation layer.
abstract class DeviceRepository {
  /// Get all devices
  Future<Result<List<Device>, AppError>> getDevices();

  /// Get device by ID
  Future<Result<Device, AppError>> getDevice(String deviceId);

  /// Get latest reading for a device
  Future<Result<Reading?, AppError>> getLatestReading(String deviceId);

  /// Get device statistics
  Future<Result<DeviceStats, AppError>> getDeviceStats(
    String deviceId, {
    String range = '24h',
  });

  /// Get reading history for a device
  Future<Result<List<Reading>, AppError>> getDeviceHistory(
    String deviceId, {
    String range = '24h',
    int limit = 1000,
  });
}

/// Implementation of [DeviceRepository] using REST API.
class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<List<Device>, AppError>> getDevices() async {
    final result = await _apiClient.get<List<dynamic>>('/devices');

    return result.map((data) {
      return data
          .map((json) => Device.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<Result<Device, AppError>> getDevice(String deviceId) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/devices/$deviceId',
    );

    return result.map((data) => Device.fromJson(data));
  }

  @override
  Future<Result<Reading?, AppError>> getLatestReading(String deviceId) async {
    final result = await _apiClient.get<Map<String, dynamic>?>(
      '/devices/$deviceId/latest',
    );

    return result.map((data) {
      if (data == null) return null;
      return Reading.fromJson(data);
    });
  }

  @override
  Future<Result<DeviceStats, AppError>> getDeviceStats(
    String deviceId, {
    String range = '24h',
  }) async {
    final result = await _apiClient.get<Map<String, dynamic>>(
      '/devices/$deviceId/stats',
      queryParameters: {'range': range},
    );

    return result.map((data) => DeviceStats.fromJson(data));
  }

  @override
  Future<Result<List<Reading>, AppError>> getDeviceHistory(
    String deviceId, {
    String range = '24h',
    int limit = 1000,
  }) async {
    final result = await _apiClient.get<List<dynamic>>(
      '/devices/$deviceId/history',
      queryParameters: {
        'range': range,
        'limit': limit,
      },
    );

    return result.map((data) {
      return data
          .map((json) => Reading.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }
}
