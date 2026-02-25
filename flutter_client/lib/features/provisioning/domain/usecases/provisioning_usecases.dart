/// Provisioning use cases
library;

import 'package:logger/logger.dart';
import '../entities/provisioning_entities.dart';
import '../repositories/provisioning_repository.dart';

/// Scan for provisioning devices
class ScanForDevicesUseCase {
  ScanForDevicesUseCase(this._repository, {Logger? logger})
      : _logger = logger ?? Logger();

  final ProvisioningRepository _repository;
  final Logger _logger;

  Stream<ProvisioningDevice> call({Duration? timeout}) {
    _logger.i('Executing ScanForDevicesUseCase');
    return _repository.scanForDevices(timeout: timeout);
  }
}

/// Connect to a provisioning device
class ConnectToDeviceUseCase {
  ConnectToDeviceUseCase(this._repository, {Logger? logger})
      : _logger = logger ?? Logger();

  final ProvisioningRepository _repository;
  final Logger _logger;

  Future<void> call(ProvisioningDevice device) async {
    _logger.i('Executing ConnectToDeviceUseCase for ${device.name}');
    await _repository.connectToDevice(device);
  }
}

/// Establish secure session
class EstablishSecureSessionUseCase {
  EstablishSecureSessionUseCase(this._repository, {Logger? logger})
      : _logger = logger ?? Logger();

  final ProvisioningRepository _repository;
  final Logger _logger;

  Future<void> call({required String proofOfPossession}) async {
    _logger.i('Executing EstablishSecureSessionUseCase');
    await _repository.establishSecureSession(
      proofOfPossession: proofOfPossession,
    );
  }
}

/// Scan for Wi-Fi networks
class ScanWiFiNetworksUseCase {
  ScanWiFiNetworksUseCase(this._repository, {Logger? logger})
      : _logger = logger ?? Logger();

  final ProvisioningRepository _repository;
  final Logger _logger;

  Future<List<WiFiNetwork>> call() async {
    _logger.i('Executing ScanWiFiNetworksUseCase');
    return await _repository.scanWiFiNetworks();
  }
}

/// Provision device with Wi-Fi credentials
class ProvisionWiFiUseCase {
  ProvisionWiFiUseCase(this._repository, {Logger? logger})
      : _logger = logger ?? Logger();

  final ProvisioningRepository _repository;
  final Logger _logger;

  Future<void> call(WiFiCredentials credentials) async {
    _logger.i('Executing ProvisionWiFiUseCase');
    await _repository.provisionWiFi(credentials);
  }
}

/// Get provisioning status
class GetProvisioningStatusUseCase {
  GetProvisioningStatusUseCase(this._repository, {Logger? logger})
      : _logger = logger ?? Logger();

  final ProvisioningRepository _repository;
  final Logger _logger;

  Future<ProvisioningStatus> call() async {
    _logger.d('Executing GetProvisioningStatusUseCase');
    return await _repository.getStatus();
  }
}

/// Send custom data to device
class SendCustomDataUseCase {
  SendCustomDataUseCase(this._repository, {Logger? logger})
      : _logger = logger ?? Logger();

  final ProvisioningRepository _repository;
  final Logger _logger;

  Future<void> call(Map<String, String> data) async {
    _logger.i('Executing SendCustomDataUseCase');
    await _repository.sendCustomData(data);
  }
}


/// Disconnect from device
class DisconnectDeviceUseCase {
  DisconnectDeviceUseCase(this._repository, {Logger? logger})
      : _logger = logger ?? Logger();

  final ProvisioningRepository _repository;
  final Logger _logger;

  Future<void> call() async {
    _logger.i('Executing DisconnectDeviceUseCase');
    await _repository.disconnect();
  }
}

