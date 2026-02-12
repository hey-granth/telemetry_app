/// Manual test for ESP32 BLE provisioning flow
///
/// This file demonstrates the complete provisioning workflow.
/// Run this to test BLE scanning and provisioning without UI.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../features/provisioning/presentation/providers/esp32_provisioning_providers.dart';
import '../features/provisioning/presentation/state/provisioning_state.dart';
import '../features/provisioning/domain/entities/provisioning_entities.dart';

/// Test ESP32 provisioning flow
class ProvisioningFlowTest {
  ProvisioningFlowTest({required this.ref});

  final WidgetRef ref;
  final _logger = Logger();

  /// Run complete provisioning test
  Future<void> runTest() async {
    _logger.i('🧪 Starting ESP32 Provisioning Flow Test');

    // Test 1: Device Scan
    _logger.i('\n📡 TEST 1: BLE Device Scan');
    final devices = await _testDeviceScan();

    if (devices.isEmpty) {
      _logger.e('❌ No devices found - ensure ESP32 is powered on and advertising');
      return;
    }

    // Test 2: Connect to first device
    _logger.i('\n🔌 TEST 2: Connect to Device');
    final device = devices.first;
    final connected = await _testConnect(device);

    if (!connected) {
      _logger.e('❌ Connection failed');
      return;
    }

    // Test 3: Establish Secure Session
    _logger.i('\n🔐 TEST 3: Establish Secure Session');
    const testPop = 'abcd1234'; // Test proof-of-possession
    final sessionEstablished = await _testSecureSession(testPop);

    if (!sessionEstablished) {
      _logger.e('❌ Secure session failed');
      return;
    }

    // Test 4: Scan Wi-Fi Networks
    _logger.i('\n📡 TEST 4: Scan Wi-Fi Networks');
    final networks = await _testWiFiScan();

    if (networks.isEmpty) {
      _logger.w('⚠️ No Wi-Fi networks found');
    }

    // Test 5: Send Credentials (commented out - would require real network)
    _logger.i('\n📶 TEST 5: Send Wi-Fi Credentials');
    _logger.i('⏭️ Skipping credential submission (requires valid SSID/password)');
    // await _testProvision('YourSSID', 'YourPassword');

    _logger.i('\n✅ Provisioning flow test completed');
  }

  Future<List<ProvisioningDevice>> _testDeviceScan() async {
    final notifier = ref.read(esp32ProvisioningProvider.notifier);

    _logger.i('Starting BLE scan for 15 seconds...');
    await notifier.startDeviceScan(timeout: const Duration(seconds: 15));

    final state = ref.read(esp32ProvisioningProvider);

    if (state.hasError) {
      _logger.e('Scan error: ${state.error!.userMessage}');
      return [];
    }

    _logger.i('Found ${state.discoveredDevices.length} device(s):');
    for (final device in state.discoveredDevices) {
      _logger.i('  - ${device.name} (${device.id})');
      _logger.i('    RSSI: ${device.rssi}dBm, Transport: ${device.transportType.name}');
    }

    return state.discoveredDevices;
  }

  Future<bool> _testConnect(ProvisioningDevice device) async {
    final notifier = ref.read(esp32ProvisioningProvider.notifier);

    _logger.i('Connecting to ${device.name}...');
    await notifier.connectToDevice(device);

    final state = ref.read(esp32ProvisioningProvider);

    if (state.hasError) {
      _logger.e('Connection error: ${state.error!.userMessage}');
      return false;
    }

    _logger.i('✅ Connected successfully');
    return true;
  }

  Future<bool> _testSecureSession(String pop) async {
    final notifier = ref.read(esp32ProvisioningProvider.notifier);

    _logger.i('Establishing secure session with PoP: $pop');
    await notifier.establishSecureSession(proofOfPossession: pop);

    final state = ref.read(esp32ProvisioningProvider);

    if (state.hasError) {
      _logger.e('Session error: ${state.error!.userMessage}');
      return false;
    }

    _logger.i('✅ Secure session established');
    return true;
  }

  Future<List<WiFiNetwork>> _testWiFiScan() async {
    final notifier = ref.read(esp32ProvisioningProvider.notifier);

    _logger.i('Scanning for Wi-Fi networks...');
    await notifier.scanWiFiNetworks();

    final state = ref.read(esp32ProvisioningProvider);

    if (state.hasError) {
      _logger.e('Wi-Fi scan error: ${state.error!.userMessage}');
      return [];
    }

    _logger.i('Found ${state.availableNetworks.length} network(s):');
    for (final network in state.availableNetworks) {
      _logger.i('  - ${network.ssid}');
      _logger.i('    RSSI: ${network.rssi}dBm, Auth: ${network.authMode.name}, Ch: ${network.channel}');
    }

    return state.availableNetworks;
  }

  // ignore: unused_element
  Future<bool> _testProvision(String ssid, String password) async {
    final notifier = ref.read(esp32ProvisioningProvider.notifier);

    final credentials = WiFiCredentials(ssid: ssid, password: password);

    _logger.i('Sending credentials for $ssid...');
    await notifier.provisionWiFi(credentials);

    final state = ref.read(esp32ProvisioningProvider);

    if (state.hasError) {
      _logger.e('Provisioning error: ${state.error!.userMessage}');
      return false;
    }

    if (state.phase == ProvisioningPhase.success) {
      _logger.i('✅ Provisioning successful');
      return true;
    }

    _logger.w('Provisioning phase: ${state.phase}');
    return false;
  }
}

/// Helper to print current provisioning state
void printProvisioningState(ProvisioningState state) {
  final logger = Logger();

  logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  logger.i('Provisioning State:');
  logger.i('  Phase: ${state.phase.name}');
  logger.i('  Progress: ${(state.progress * 100).toStringAsFixed(0)}%');
  logger.i('  Devices: ${state.discoveredDevices.length}');
  logger.i('  Networks: ${state.availableNetworks.length}');

  if (state.selectedDevice != null) {
    logger.i('  Selected: ${state.selectedDevice!.name}');
  }

  if (state.hasError) {
    logger.e('  Error: ${state.error!.userMessage}');
  }

  logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

