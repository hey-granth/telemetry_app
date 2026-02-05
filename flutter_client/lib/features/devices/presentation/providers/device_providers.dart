import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/networking/api_client.dart';
import '../../domain/models/device.dart';
import '../../domain/repositories/device_repository.dart';

/// API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Device repository provider
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(apiClient: ref.watch(apiClientProvider));
});

/// State for devices list
sealed class DevicesState {
  const DevicesState();
}

class DevicesLoading extends DevicesState {
  const DevicesLoading();
}

class DevicesLoaded extends DevicesState {
  const DevicesLoaded(this.devices);
  final List<Device> devices;
}

class DevicesError extends DevicesState {
  const DevicesError(this.error);
  final AppError error;
}

/// Devices list notifier
class DevicesNotifier extends AsyncNotifier<List<Device>> {
  @override
  Future<List<Device>> build() async {
    return _fetchDevices();
  }

  Future<List<Device>> _fetchDevices() async {
    final repository = ref.read(deviceRepositoryProvider);
    final result = await repository.getDevices();

    return result.when(
      success: (devices) => devices,
      failure: (error) => throw error,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchDevices);
  }

  /// Update device in list (for live updates)
  void updateDevice(Device device) {
    state.whenData((devices) {
      final index = devices.indexWhere((d) => d.deviceId == device.deviceId);
      if (index >= 0) {
        final updated = [...devices];
        updated[index] = device;
        state = AsyncData(updated);
      }
    });
  }

  /// Update latest reading for a device
  void updateLatestReading(String deviceId, Reading reading) {
    state.whenData((devices) {
      final index = devices.indexWhere((d) => d.deviceId == deviceId);
      if (index >= 0) {
        final device = devices[index];
        final updated = device.copyWith(
          latestReading: reading,
          lastSeenAt: reading.timestamp,
          readingCount: device.readingCount + 1,
        );
        final newList = [...devices];
        newList[index] = updated;
        state = AsyncData(newList);
      }
    });
  }
}

/// Devices list provider
final devicesProvider =
    AsyncNotifierProvider<DevicesNotifier, List<Device>>(() {
  return DevicesNotifier();
});

/// State for single device detail
class DeviceDetailState {
  const DeviceDetailState({
    this.device,
    this.stats,
    this.history,
    this.isLoading = false,
    this.error,
  });

  final Device? device;
  final DeviceStats? stats;
  final List<Reading>? history;
  final bool isLoading;
  final AppError? error;

  DeviceDetailState copyWith({
    Device? device,
    DeviceStats? stats,
    List<Reading>? history,
    bool? isLoading,
    AppError? error,
  }) {
    return DeviceDetailState(
      device: device ?? this.device,
      stats: stats ?? this.stats,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Device detail notifier
class DeviceDetailNotifier
    extends FamilyAsyncNotifier<DeviceDetailState, String> {
  @override
  Future<DeviceDetailState> build(String arg) async {
    return _fetchDeviceDetail(arg);
  }

  Future<DeviceDetailState> _fetchDeviceDetail(String deviceId) async {
    final repository = ref.read(deviceRepositoryProvider);

    // Fetch device, stats, and history in parallel
    final results = await Future.wait([
      repository.getDevice(deviceId),
      repository.getDeviceStats(deviceId),
      repository.getDeviceHistory(deviceId),
    ]);

    final deviceResult = results[0] as dynamic;
    final statsResult = results[1] as dynamic;
    final historyResult = results[2] as dynamic;

    Device? device;
    DeviceStats? stats;
    List<Reading>? history;
    AppError? error;

    deviceResult.when(
      success: (d) => device = d as Device,
      failure: (e) => error = e as AppError,
    );

    statsResult.when(
      success: (s) => stats = s as DeviceStats,
      failure: (e) => error ??= e as AppError,
    );

    historyResult.when(
      success: (h) => history = h as List<Reading>,
      failure: (e) => error ??= e as AppError,
    );

    if (error != null && device == null) {
      throw error!;
    }

    return DeviceDetailState(
      device: device,
      stats: stats,
      history: history,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchDeviceDetail(arg));
  }

  /// Update with new reading from WebSocket
  void addReading(Reading reading) {
    state.whenData((detail) {
      final updatedHistory = [reading, ...?detail.history];
      final updatedDevice = detail.device?.copyWith(
        latestReading: reading,
        lastSeenAt: reading.timestamp,
      );

      state = AsyncData(detail.copyWith(
        device: updatedDevice,
        history: updatedHistory,
      ));
    });
  }
}

/// Device detail provider (family)
final deviceDetailProvider = AsyncNotifierProvider.family<DeviceDetailNotifier,
    DeviceDetailState, String>(
  () => DeviceDetailNotifier(),
);

/// Selected time range provider
final selectedTimeRangeProvider = StateProvider<String>((ref) => '24h');

/// Available time ranges
const availableTimeRanges = [
  '1h',
  '6h',
  '24h',
  '7d',
  '30d',
];
