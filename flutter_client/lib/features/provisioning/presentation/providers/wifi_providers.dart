/// WiFi network providers for scanning and selection.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// WiFi network model
class WifiNetwork {
  const WifiNetwork({
    required this.ssid,
    required this.signalStrength,
    required this.isSecure,
  });

  final String ssid;
  final int signalStrength; // 0-100
  final bool isSecure;
}

/// WiFi scan state
class WifiScanState {
  const WifiScanState({
    this.networks = const [],
    this.isScanning = false,
    this.error,
  });

  final List<WifiNetwork> networks;
  final bool isScanning;
  final String? error;

  WifiScanState copyWith({
    List<WifiNetwork>? networks,
    bool? isScanning,
    String? error,
  }) {
    return WifiScanState(
      networks: networks ?? this.networks,
      isScanning: isScanning ?? this.isScanning,
      error: error,
    );
  }
}

/// WiFi network scanning notifier
class WifiNetworksNotifier extends StateNotifier<WifiScanState> {
  WifiNetworksNotifier() : super(const WifiScanState());

  /// Scan for available WiFi networks
  void scan() {
    state = state.copyWith(isScanning: true, error: null);

    // Simulate scanning - in production this would query the device
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      state = WifiScanState(
        isScanning: false,
        networks: [
          const WifiNetwork(
            ssid: 'Home Network',
            signalStrength: 95,
            isSecure: true,
          ),
          const WifiNetwork(
            ssid: 'Guest_WiFi',
            signalStrength: 78,
            isSecure: true,
          ),
          const WifiNetwork(
            ssid: 'Office_5G',
            signalStrength: 62,
            isSecure: true,
          ),
          const WifiNetwork(
            ssid: 'Neighbor_Network',
            signalStrength: 35,
            isSecure: true,
          ),
        ],
      );
    });
  }
}

/// WiFi networks provider
final wifiNetworksProvider =
    StateNotifierProvider<WifiNetworksNotifier, WifiScanState>((ref) {
  return WifiNetworksNotifier();
});
