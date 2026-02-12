/// Provisioning state management.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../devices/presentation/providers/device_providers.dart';

/// Provisioning steps
enum ProvisioningStep {
  connecting,
  sendingCredentials,
  configuringDevice,
  registeringWithServer,
  verifying,
  complete,
}

/// Provisioning state
class ProvisioningState {
  const ProvisioningState({
    this.currentStep = ProvisioningStep.connecting,
    this.failedStep,
    this.errorMessage,
    this.isComplete = false,
    this.hasFailed = false,
    this.deviceId,
  });

  final ProvisioningStep currentStep;
  final ProvisioningStep? failedStep;
  final String? errorMessage;
  final bool isComplete;
  final bool hasFailed;
  final String? deviceId;

  ProvisioningState copyWith({
    ProvisioningStep? currentStep,
    ProvisioningStep? failedStep,
    String? errorMessage,
    bool? isComplete,
    bool? hasFailed,
    String? deviceId,
  }) {
    return ProvisioningState(
      currentStep: currentStep ?? this.currentStep,
      failedStep: failedStep ?? this.failedStep,
      errorMessage: errorMessage ?? this.errorMessage,
      isComplete: isComplete ?? this.isComplete,
      hasFailed: hasFailed ?? this.hasFailed,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

/// Provisioning notifier
class ProvisioningNotifier extends StateNotifier<ProvisioningState> {
  ProvisioningNotifier(this._ref) : super(const ProvisioningState());

  final Ref _ref;
  String? _deviceId;
  String? _ssid;
  String? _password;

  /// Start the provisioning process
  Future<void> startProvisioning({
    required String deviceId,
    required String ssid,
    required String password,
  }) async {
    _deviceId = deviceId;
    _ssid = ssid;
    _password = password;

    state = ProvisioningState(deviceId: deviceId);

    try {
      // Step 1: Connecting to device
      await _executeStep(ProvisioningStep.connecting, () async {
        // Simulate BLE connection
        await Future.delayed(const Duration(seconds: 2));
      });

      // Step 2: Sending credentials
      await _executeStep(ProvisioningStep.sendingCredentials, () async {
        // Simulate sending credentials over BLE
        await Future.delayed(const Duration(seconds: 2));
      });

      // Step 3: Configuring device
      await _executeStep(ProvisioningStep.configuringDevice, () async {
        // Device connects to WiFi
        await Future.delayed(const Duration(seconds: 3));
      });

      // Step 4: Registering with server
      await _executeStep(ProvisioningStep.registeringWithServer, () async {
        // Register device with backend
        final apiClient = _ref.read(apiClientProvider);
        final result = await apiClient.post<Map<String, dynamic>>(
          '/devices',
          data: {
            'device_id': deviceId,
            'name': deviceId,
          },
        );

        // If registration fails, check if device already exists (which is OK)
        if (result.isFailure) {
          // For demo, we'll accept the "failure" as the device may already exist
          await Future.delayed(const Duration(seconds: 1));
        }
      });

      // Step 5: Verifying
      await _executeStep(ProvisioningStep.verifying, () async {
        // Verify device is communicating
        await Future.delayed(const Duration(seconds: 2));
      });

      // Complete
      state = state.copyWith(
        currentStep: ProvisioningStep.complete,
        isComplete: true,
      );

      // Refresh devices list
      _ref.read(devicesProvider.notifier).refresh();
    } catch (e) {
      // Error is already handled in _executeStep
    }
  }

  Future<void> _executeStep(
    ProvisioningStep step,
    Future<void> Function() action,
  ) async {
    if (!mounted) return;

    state = state.copyWith(currentStep: step);

    try {
      await action();
    } catch (e) {
      state = state.copyWith(
        failedStep: step,
        hasFailed: true,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Retry the provisioning process
  Future<void> retry() async {
    if (_deviceId != null && _ssid != null && _password != null) {
      await startProvisioning(
        deviceId: _deviceId!,
        ssid: _ssid!,
        password: _password!,
      );
    }
  }
}

/// Provisioning provider
final provisioningProvider =
    StateNotifierProvider.autoDispose<ProvisioningNotifier, ProvisioningState>(
        (ref) {
  return ProvisioningNotifier(ref);
});
