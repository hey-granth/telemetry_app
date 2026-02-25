/// Example: ESP32 Provisioning Usage
///
/// This file demonstrates how to use the ESP32 provisioning system
/// in your Flutter application.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../features/provisioning/domain/entities/provisioning_entities.dart';
import '../features/provisioning/presentation/providers/esp32_provisioning_providers.dart';
import '../features/provisioning/presentation/state/provisioning_state.dart';
import '../features/provisioning/presentation/screens/device_discovery_screen.dart';

final _logger = Logger();

/// Example: Launch provisioning flow
class ProvisioningExample extends ConsumerWidget {
  const ProvisioningExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Setup')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Manual provisioning button
            ElevatedButton.icon(
              icon: const Icon(Icons.bluetooth),
              label: const Text('Provision Device via BLE'),
              onPressed: () => _launchManualProvisioning(context),
            ),
          ],
        ),
      ),
    );
  }

  void _launchManualProvisioning(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeviceDiscoveryScreen(),
      ),
    );
  }
}

/// Example: Programmatic provisioning
class ProgrammaticProvisioningExample extends ConsumerStatefulWidget {
  const ProgrammaticProvisioningExample({super.key});

  @override
  ConsumerState<ProgrammaticProvisioningExample> createState() =>
      _ProgrammaticProvisioningExampleState();
}

class _ProgrammaticProvisioningExampleState
    extends ConsumerState<ProgrammaticProvisioningExample> {

  Future<void> _provisionDevice() async {
    final notifier = ref.read(esp32ProvisioningProvider.notifier);

    try {
      // Step 1: Scan for devices
      _logger.i('Scanning for devices...');
      await notifier.startDeviceScan(timeout: const Duration(seconds: 30));

      // Step 2: Select a device (first one in this example)
      final state = ref.read(esp32ProvisioningProvider);
      if (state.discoveredDevices.isEmpty) {
        _logger.w('No devices found');
        return;
      }

      final device = state.discoveredDevices.first;
      _logger.i('Found device: ${device.name}');

      // Step 3: Connect to device
      _logger.i('Connecting...');
      await notifier.connectToDevice(device);

      // Step 4: Establish secure session
      _logger.i('Establishing secure session...');
      await notifier.establishSecureSession(
        proofOfPossession: 'abcd1234', // Device-specific PoP
      );

      // Step 5: Scan Wi-Fi networks
      _logger.i('Scanning Wi-Fi networks...');
      await notifier.scanWiFiNetworks();

      // Step 6: Provision Wi-Fi
      _logger.i('Provisioning Wi-Fi...');
      await notifier.provisionWiFi(
        WiFiCredentials(
          ssid: 'MyNetwork',
          password: 'mypassword',
        ),
      );

      _logger.i('✅ Provisioning complete!');
    } catch (e, st) {
      _logger.e('❌ Provisioning failed: $e', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esp32ProvisioningProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Programmatic Provisioning')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _provisionDevice,
                child: const Text('Start Provisioning'),
              ),
            const SizedBox(height: 16),
            Text('Phase: ${state.phase}'),
            Text('Progress: ${(state.progress * 100).toInt()}%'),
            if (state.hasError)
              Text('Error: ${state.error!.userMessage}',
                  style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}


/// Example: Custom data exchange
class CustomDataExample extends ConsumerWidget {
  const CustomDataExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Data')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Send custom configuration data to device
            await ref.read(esp32ProvisioningProvider.notifier).sendCustomData({
              'device_id': 'ESP32_SENSOR_001',
              'location': 'Living Room',
              'api_endpoint': 'https://api.example.com/telemetry',
              'update_interval': '60',
            });
          },
          child: const Text('Send Custom Data'),
        ),
      ),
    );
  }
}

/// Example: Listening to provisioning state
class ProvisioningListenerExample extends ConsumerWidget {
  const ProvisioningListenerExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to provisioning state changes
    ref.listen<ProvisioningState>(
      esp32ProvisioningProvider,
      (previous, next) {
        // React to state changes
        if (next.isComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Provisioning successful!')),
          );
        } else if (next.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!.userMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    final state = ref.watch(esp32ProvisioningProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('State Listener')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Phase: ${state.phase}'),
            Text('Devices Found: ${state.discoveredDevices.length}'),
            Text('Networks Found: ${state.availableNetworks.length}'),
            if (state.selectedDevice != null)
              Text('Selected: ${state.selectedDevice!.name}'),
          ],
        ),
      ),
    );
  }
}

