/// BLE scanning providers for device discovery.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Discovered BLE device model
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isPaired = false,
  });

  final String id;
  final String name;
  final int rssi;
  final bool isPaired;

  /// Signal strength as percentage (rough estimation)
  int get signalStrength {
    // RSSI typically ranges from -100 (weak) to -30 (strong)
    if (rssi >= -50) return 100;
    if (rssi >= -60) return 80;
    if (rssi >= -70) return 60;
    if (rssi >= -80) return 40;
    if (rssi >= -90) return 20;
    return 10;
  }

  /// Signal quality description
  String get signalQuality {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    if (rssi >= -80) return 'Weak';
    return 'Poor';
  }
}

/// BLE scan state
class BleScanState {
  const BleScanState({
    this.devices = const [],
    this.isScanning = false,
    this.error,
  });

  final List<DiscoveredDevice> devices;
  final bool isScanning;
  final String? error;

  BleScanState copyWith({
    List<DiscoveredDevice>? devices,
    bool? isScanning,
    String? error,
  }) {
    return BleScanState(
      devices: devices ?? this.devices,
      isScanning: isScanning ?? this.isScanning,
      error: error,
    );
  }
}

/// BLE scan notifier
class BleScanNotifier extends StateNotifier<BleScanState> {
  BleScanNotifier() : super(const BleScanState());

  Timer? _scanTimer;

  /// Start BLE scanning
  void startScan() {
    state = state.copyWith(isScanning: true, error: null);

    // Simulate BLE scanning with mock devices
    // In production, this would use flutter_blue_plus or similar
    _simulateScan();
  }

  /// Stop BLE scanning
  void stopScan() {
    _scanTimer?.cancel();
    state = state.copyWith(isScanning: false);
  }

  void _simulateScan() {
    // Clear existing devices
    state = state.copyWith(devices: [], isScanning: true);

    // Simulate finding devices over time
    int deviceCount = 0;
    _scanTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (deviceCount >= 3) {
        timer.cancel();
        state = state.copyWith(isScanning: false);
        return;
      }

      final mockDevices = [
        DiscoveredDevice(
          id: 'esp32_sensor_001',
          name: 'ESP32 Sensor 001',
          rssi: -45,
          isPaired: false,
        ),
        DiscoveredDevice(
          id: 'esp32_sensor_002',
          name: 'ESP32 Sensor 002',
          rssi: -62,
          isPaired: false,
        ),
        DiscoveredDevice(
          id: 'esp32_sensor_003',
          name: 'ESP32 Sensor 003',
          rssi: -78,
          isPaired: true,
        ),
      ];

      state = state.copyWith(
        devices: [...state.devices, mockDevices[deviceCount]],
      );
      deviceCount++;
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    super.dispose();
  }
}

/// BLE scan provider
final bleScanProvider = StateNotifierProvider<BleScanNotifier, BleScanState>((ref) {
  return BleScanNotifier();
});
