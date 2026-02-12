/// ESP32 Provisioning providers
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../core/config/provisioning_config.dart';
import '../../data/repositories/provisioning_repository_impl.dart';
import '../../domain/repositories/provisioning_repository.dart';
import '../../domain/usecases/provisioning_usecases.dart';
import '../state/provisioning_state.dart';

/// Logger provider
final esp32LoggerProvider = Provider<Logger>((ref) => Logger());

/// Provisioning config provider
final esp32ProvisioningConfigProvider = Provider<ProvisioningConfig>(
  (ref) => ProvisioningConfig.defaultConfig,
);

/// Provisioning repository provider
final esp32ProvisioningRepositoryProvider = Provider<ProvisioningRepository>((ref) {
  final config = ref.watch(esp32ProvisioningConfigProvider);
  final logger = ref.watch(esp32LoggerProvider);

  return ProvisioningRepositoryImpl(
    config: config,
    logger: logger,
  );
});

/// Use case providers
final esp32ScanForDevicesUseCaseProvider = Provider<ScanForDevicesUseCase>((ref) {
  final repository = ref.watch(esp32ProvisioningRepositoryProvider);
  final logger = ref.watch(esp32LoggerProvider);
  return ScanForDevicesUseCase(repository, logger: logger);
});

final esp32ConnectToDeviceUseCaseProvider = Provider<ConnectToDeviceUseCase>((ref) {
  final repository = ref.watch(esp32ProvisioningRepositoryProvider);
  final logger = ref.watch(esp32LoggerProvider);
  return ConnectToDeviceUseCase(repository, logger: logger);
});

final esp32EstablishSecureSessionUseCaseProvider =
    Provider<EstablishSecureSessionUseCase>((ref) {
  final repository = ref.watch(esp32ProvisioningRepositoryProvider);
  final logger = ref.watch(esp32LoggerProvider);
  return EstablishSecureSessionUseCase(repository, logger: logger);
});

final esp32ScanWiFiNetworksUseCaseProvider = Provider<ScanWiFiNetworksUseCase>((ref) {
  final repository = ref.watch(esp32ProvisioningRepositoryProvider);
  final logger = ref.watch(esp32LoggerProvider);
  return ScanWiFiNetworksUseCase(repository, logger: logger);
});

final esp32ProvisionWiFiUseCaseProvider = Provider<ProvisionWiFiUseCase>((ref) {
  final repository = ref.watch(esp32ProvisioningRepositoryProvider);
  final logger = ref.watch(esp32LoggerProvider);
  return ProvisionWiFiUseCase(repository, logger: logger);
});

final esp32GetProvisioningStatusUseCaseProvider =
    Provider<GetProvisioningStatusUseCase>((ref) {
  final repository = ref.watch(esp32ProvisioningRepositoryProvider);
  final logger = ref.watch(esp32LoggerProvider);
  return GetProvisioningStatusUseCase(repository, logger: logger);
});

final esp32SendCustomDataUseCaseProvider = Provider<SendCustomDataUseCase>((ref) {
  final repository = ref.watch(esp32ProvisioningRepositoryProvider);
  final logger = ref.watch(esp32LoggerProvider);
  return SendCustomDataUseCase(repository, logger: logger);
});

final esp32ParseQrCodeUseCaseProvider = Provider<ParseQrCodeUseCase>((ref) {
  final repository = ref.watch(esp32ProvisioningRepositoryProvider);
  final logger = ref.watch(esp32LoggerProvider);
  return ParseQrCodeUseCase(repository, logger: logger);
});

final esp32DisconnectDeviceUseCaseProvider = Provider<DisconnectDeviceUseCase>((ref) {
  final repository = ref.watch(esp32ProvisioningRepositoryProvider);
  final logger = ref.watch(esp32LoggerProvider);
  return DisconnectDeviceUseCase(repository, logger: logger);
});

/// Main ESP32 provisioning state provider
final esp32ProvisioningProvider =
    StateNotifierProvider<ProvisioningNotifier, ProvisioningState>((ref) {
  final logger = ref.watch(esp32LoggerProvider);

  return ProvisioningNotifier(
    scanForDevicesUseCase: ref.watch(esp32ScanForDevicesUseCaseProvider),
    connectToDeviceUseCase: ref.watch(esp32ConnectToDeviceUseCaseProvider),
    establishSecureSessionUseCase:
        ref.watch(esp32EstablishSecureSessionUseCaseProvider),
    scanWiFiNetworksUseCase: ref.watch(esp32ScanWiFiNetworksUseCaseProvider),
    provisionWiFiUseCase: ref.watch(esp32ProvisionWiFiUseCaseProvider),
    getProvisioningStatusUseCase:
        ref.watch(esp32GetProvisioningStatusUseCaseProvider),
    sendCustomDataUseCase: ref.watch(esp32SendCustomDataUseCaseProvider),
    parseQrCodeUseCase: ref.watch(esp32ParseQrCodeUseCaseProvider),
    disconnectDeviceUseCase: ref.watch(esp32DisconnectDeviceUseCaseProvider),
    logger: logger,
  );
});

