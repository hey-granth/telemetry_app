/// Provisioning state and notifier
library;

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../core/errors/provisioning_errors.dart';
import '../../domain/entities/provisioning_entities.dart';
import '../../domain/usecases/provisioning_usecases.dart';

/// Provisioning state
class ProvisioningState extends Equatable {
  const ProvisioningState({
    this.phase = ProvisioningPhase.idle,
    this.discoveredDevices = const [],
    this.selectedDevice,
    this.availableNetworks = const [],
    this.selectedNetwork,
    this.progress = 0.0,
    this.error,
    this.qrData,
  });

  final ProvisioningPhase phase;
  final List<ProvisioningDevice> discoveredDevices;
  final ProvisioningDevice? selectedDevice;
  final List<WiFiNetwork> availableNetworks;
  final WiFiNetwork? selectedNetwork;
  final double progress;
  final ProvisioningError? error;
  final QrProvisioningData? qrData;

  bool get isLoading => phase.isLoading;
  bool get hasError => error != null;
  bool get isComplete => phase == ProvisioningPhase.success;

  @override
  List<Object?> get props => [
        phase,
        discoveredDevices,
        selectedDevice,
        availableNetworks,
        selectedNetwork,
        progress,
        error,
        qrData,
      ];

  ProvisioningState copyWith({
    ProvisioningPhase? phase,
    List<ProvisioningDevice>? discoveredDevices,
    ProvisioningDevice? selectedDevice,
    List<WiFiNetwork>? availableNetworks,
    WiFiNetwork? selectedNetwork,
    double? progress,
    ProvisioningError? error,
    bool clearError = false,
    QrProvisioningData? qrData,
    bool clearQrData = false,
  }) {
    return ProvisioningState(
      phase: phase ?? this.phase,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      selectedDevice: selectedDevice ?? this.selectedDevice,
      availableNetworks: availableNetworks ?? this.availableNetworks,
      selectedNetwork: selectedNetwork ?? this.selectedNetwork,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
      qrData: clearQrData ? null : (qrData ?? this.qrData),
    );
  }
}

/// Provisioning phases
enum ProvisioningPhase {
  idle,
  scanningDevices,
  connecting,
  establishingSession,
  scanningWiFi,
  sendingCredentials,
  applyingConfig,
  verifying,
  success,
  failure;

  bool get isLoading => this != idle && this != success && this != failure;
}

/// Provisioning state notifier
class ProvisioningNotifier extends StateNotifier<ProvisioningState> {
  ProvisioningNotifier({
    required ScanForDevicesUseCase scanForDevicesUseCase,
    required ConnectToDeviceUseCase connectToDeviceUseCase,
    required EstablishSecureSessionUseCase establishSecureSessionUseCase,
    required ScanWiFiNetworksUseCase scanWiFiNetworksUseCase,
    required ProvisionWiFiUseCase provisionWiFiUseCase,
    required GetProvisioningStatusUseCase getProvisioningStatusUseCase,
    required SendCustomDataUseCase sendCustomDataUseCase,
    required ParseQrCodeUseCase parseQrCodeUseCase,
    required DisconnectDeviceUseCase disconnectDeviceUseCase,
    Logger? logger,
  })  : _scanForDevicesUseCase = scanForDevicesUseCase,
        _connectToDeviceUseCase = connectToDeviceUseCase,
        _establishSecureSessionUseCase = establishSecureSessionUseCase,
        _scanWiFiNetworksUseCase = scanWiFiNetworksUseCase,
        _provisionWiFiUseCase = provisionWiFiUseCase,
        _getProvisioningStatusUseCase = getProvisioningStatusUseCase,
        _sendCustomDataUseCase = sendCustomDataUseCase,
        _parseQrCodeUseCase = parseQrCodeUseCase,
        _disconnectDeviceUseCase = disconnectDeviceUseCase,
        _logger = logger ?? Logger(),
        super(const ProvisioningState());

  final ScanForDevicesUseCase _scanForDevicesUseCase;
  final ConnectToDeviceUseCase _connectToDeviceUseCase;
  final EstablishSecureSessionUseCase _establishSecureSessionUseCase;
  final ScanWiFiNetworksUseCase _scanWiFiNetworksUseCase;
  final ProvisionWiFiUseCase _provisionWiFiUseCase;
  // ignore: unused_field
  final GetProvisioningStatusUseCase _getProvisioningStatusUseCase;
  final SendCustomDataUseCase _sendCustomDataUseCase;
  final ParseQrCodeUseCase _parseQrCodeUseCase;
  final DisconnectDeviceUseCase _disconnectDeviceUseCase;
  final Logger _logger;

  /// Start scanning for devices
  Future<void> startDeviceScan({Duration? timeout}) async {
    _logger.i('🔍 Starting device scan');

    state = state.copyWith(
      phase: ProvisioningPhase.scanningDevices,
      discoveredDevices: [],
      clearError: true,
    );

    try {
      _logger.i('🔍 Calling scanForDevicesUseCase...');
      var deviceCount = 0;

      await for (final device in _scanForDevicesUseCase(timeout: timeout)) {
        deviceCount++;
        _logger.i('✅ Device discovered: ${device.name} (${device.id}) - RSSI: ${device.rssi}dBm');

        // Add or update device in list
        final devices = List<ProvisioningDevice>.from(state.discoveredDevices);
        final index = devices.indexWhere((d) => d.id == device.id);

        if (index >= 0) {
          _logger.d('🔄 Updating existing device: ${device.name}');
          devices[index] = device;
        } else {
          _logger.d('➕ Adding new device: ${device.name}');
          devices.add(device);
        }

        state = state.copyWith(discoveredDevices: devices);
        _logger.d('📋 Total devices in list: ${devices.length}');
      }

      state = state.copyWith(phase: ProvisioningPhase.idle);
      _logger.i('✅ Device scan completed - Found $deviceCount devices');
    } catch (e, stackTrace) {
      _logger.e('❌ Device scan failed: $e');
      _logger.e('Stack trace: $stackTrace');
      _handleError(e);
    }
  }

  /// Connect to device
  Future<void> connectToDevice(ProvisioningDevice device) async {
    _logger.i('🔌 Connecting to device: ${device.name}');

    state = state.copyWith(
      phase: ProvisioningPhase.connecting,
      selectedDevice: device,
      progress: 0.1,
      clearError: true,
    );

    try {
      _logger.d('🔌 Calling connectToDeviceUseCase...');
      await _connectToDeviceUseCase(device);

      state = state.copyWith(
        phase: ProvisioningPhase.idle,
        progress: 0.2,
      );

      _logger.i('✅ Connected successfully to ${device.name}');
    } catch (e, stackTrace) {
      _logger.e('❌ Connection failed: $e');
      _logger.e('Stack trace: $stackTrace');
      _handleError(e);
    }
  }

  /// Establish secure session
  Future<void> establishSecureSession({required String proofOfPossession}) async {
    _logger.i('🔐 Establishing secure session with PoP');

    state = state.copyWith(
      phase: ProvisioningPhase.establishingSession,
      progress: 0.3,
      clearError: true,
    );

    try {
      _logger.d('🔐 Calling establishSecureSessionUseCase...');
      await _establishSecureSessionUseCase(
        proofOfPossession: proofOfPossession,
      );

      state = state.copyWith(
        phase: ProvisioningPhase.idle,
        progress: 0.4,
      );

      _logger.i('✅ Secure session established');
    } catch (e, stackTrace) {
      _logger.e('❌ Secure session failed: $e');
      _logger.e('Stack trace: $stackTrace');
      _handleError(e);
    }
  }

  /// Scan for Wi-Fi networks
  Future<void> scanWiFiNetworks() async {
    _logger.i('📡 Scanning Wi-Fi networks');

    state = state.copyWith(
      phase: ProvisioningPhase.scanningWiFi,
      progress: 0.5,
      clearError: true,
    );

    try {
      _logger.d('📡 Calling scanWiFiNetworksUseCase...');
      final networks = await _scanWiFiNetworksUseCase();

      state = state.copyWith(
        phase: ProvisioningPhase.idle,
        availableNetworks: networks,
        progress: 0.6,
      );

      _logger.i('✅ Found ${networks.length} Wi-Fi networks');
      for (final network in networks) {
        _logger.d('  - ${network.ssid} (${network.rssi}dBm, ${network.authMode.name})');
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Wi-Fi scan failed: $e');
      _logger.e('Stack trace: $stackTrace');
      _handleError(e);
    }
  }

  /// Provision Wi-Fi
  Future<void> provisionWiFi(WiFiCredentials credentials) async {
    _logger.i('📶 Provisioning Wi-Fi: ${credentials.ssid}');

    state = state.copyWith(
      phase: ProvisioningPhase.sendingCredentials,
      progress: 0.7,
      clearError: true,
    );

    try {
      // Send credentials and apply config
      _logger.d('📶 Sending credentials...');
      state = state.copyWith(phase: ProvisioningPhase.applyingConfig);
      await _provisionWiFiUseCase(credentials);

      // Verify provisioning
      _logger.d('✓ Verifying provisioning...');
      state = state.copyWith(
        phase: ProvisioningPhase.verifying,
        progress: 0.9,
      );

      state = state.copyWith(
        phase: ProvisioningPhase.success,
        progress: 1.0,
      );

      _logger.i('✅ Provisioning completed successfully');
    } catch (e, stackTrace) {
      _logger.e('❌ Provisioning failed: $e');
      _logger.e('Stack trace: $stackTrace');
      _handleError(e);
    }
  }

  /// Complete provisioning flow
  Future<void> provisionDevice({
    required ProvisioningDevice device,
    required String proofOfPossession,
    required WiFiCredentials credentials,
  }) async {
    await connectToDevice(device);

    if (state.hasError) return;

    await establishSecureSession(proofOfPossession: proofOfPossession);

    if (state.hasError) return;

    await scanWiFiNetworks();

    if (state.hasError) return;

    await provisionWiFi(credentials);
  }

  /// Parse QR code
  void parseQrCode(String qrData) {
    _logger.i('Parsing QR code');

    try {
      final data = _parseQrCodeUseCase(qrData);
      state = state.copyWith(qrData: data, clearError: true);
      _logger.i('QR code parsed: ${data.serviceName}');
    } catch (e) {
      _handleError(e);
    }
  }

  /// Provision from QR code
  Future<void> provisionFromQrCode({
    required QrProvisioningData qrData,
    required WiFiCredentials credentials,
  }) async {
    // Find device by service name
    final device = state.discoveredDevices.firstWhere(
      (d) => d.name.contains(qrData.serviceName),
      orElse: () => throw const DeviceError('Device not found'),
    );

    await provisionDevice(
      device: device,
      proofOfPossession: qrData.proofOfPossession,
      credentials: credentials,
    );
  }

  /// Send custom data
  Future<void> sendCustomData(Map<String, String> data) async {
    try {
      await _sendCustomDataUseCase(data);
      _logger.i('Custom data sent');
    } catch (e) {
      _handleError(e);
    }
  }

  /// Reset state
  Future<void> reset() async {
    _logger.i('Resetting provisioning state');
    await _disconnectDeviceUseCase();
    state = const ProvisioningState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Handle error
  void _handleError(Object e) {
    _logger.e('Provisioning error: $e');

    final error = e is ProvisioningError
        ? e
        : ProtocolError('Unexpected error: $e');

    state = state.copyWith(
      phase: ProvisioningPhase.failure,
      error: error,
    );
  }

  @override
  void dispose() {
    _disconnectDeviceUseCase();
    super.dispose();
  }
}

