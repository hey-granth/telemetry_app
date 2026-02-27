/// Device discovery screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/provisioning_errors.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../domain/entities/provisioning_entities.dart';
import '../providers/esp32_provisioning_providers.dart';
import '../state/provisioning_state.dart';
import 'wifi_selection_screen.dart';

/// ESP32 device discovery screen
class DeviceDiscoveryScreen extends ConsumerStatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  ConsumerState<DeviceDiscoveryScreen> createState() =>
      _DeviceDiscoveryScreenState();
}

class _DeviceDiscoveryScreenState
    extends ConsumerState<DeviceDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissionsAndScan();
  }

  Future<void> _checkPermissionsAndScan() async {
    // Check if permissions are required on this platform
    if (!PermissionHelper.isPermissionHandlingSupported) {
      debugPrint('Platform does not require permission handling - starting scan');
      _startScan();
      return;
    }

    // Request permissions
    final granted = await PermissionHelper.checkAndRequestBlePermissions();

    if (granted) {
      _startScan();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permission is required for BLE scanning'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startScan() {
    ref.read(esp32ProvisioningProvider.notifier).startDeviceScan(
          timeout: const Duration(seconds: 30),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esp32ProvisioningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32 Provisioning'),
      ),
      body: Column(
        children: [
          if (state.hasError)
            _buildErrorBanner(state.error!),
          _buildScanningIndicator(state),
          Expanded(
            child: _buildDeviceList(state),
          ),
        ],
      ),
      floatingActionButton: state.phase == ProvisioningPhase.scanningDevices
          ? null
          : FloatingActionButton(
              onPressed: _startScan,
              child: const Icon(Icons.refresh),
            ),
    );
  }

  Widget _buildErrorBanner(ProvisioningError error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                Text(
                  error.userMessage,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(esp32ProvisioningProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanningIndicator(ProvisioningState state) {
    if (state.phase != ProvisioningPhase.scanningDevices) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scanning for ESP32 devices...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Found ${state.discoveredDevices.length} device(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your ESP32 is powered on and advertising',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(ProvisioningState state) {
    if (state.discoveredDevices.isEmpty &&
        state.phase != ProvisioningPhase.scanningDevices) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No ESP32 devices found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Make sure:\n'
                '• ESP32 is powered on\n'
                '• Device is in provisioning mode\n'
                '• Bluetooth is enabled\n'
                '• You\'re within range',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap the refresh button to scan again',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.discoveredDevices.length,
      itemBuilder: (context, index) {
        final device = state.discoveredDevices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(ProvisioningDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSignalColor(device.rssi),
          child: const Icon(Icons.router, color: Colors.white),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Signal: ${device.rssi} dBm\n${device.transportType.name.toUpperCase()}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showDeviceDialog(device),
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }

  void _showDeviceDialog(ProvisioningDevice device) {
    final popController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect to ${device.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: popController,
              decoration: const InputDecoration(
                labelText: 'Proof of Possession (PoP)',
                hintText: 'Enter device PoP',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'The PoP can be found on the device or in its documentation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _connectToDevice(device, popController.text);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToDevice(ProvisioningDevice device, String pop) async {
    if (pop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Proof of Possession')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Connecting...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Connect and establish session
    await ref.read(esp32ProvisioningProvider.notifier).connectToDevice(device);

    if (!mounted) return;

    final state = ref.read(esp32ProvisioningProvider);
    if (state.hasError) {
      Navigator.pop(context);
      return;
    }

    await ref
        .read(esp32ProvisioningProvider.notifier)
        .establishSecureSession(proofOfPossession: pop);

    if (!mounted) return;

    final finalState = ref.read(esp32ProvisioningProvider);
    Navigator.pop(context);

    if (finalState.hasError) {
      return;
    }

    // Navigate to Wi-Fi selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WiFiSelectionScreen(),
      ),
    );
  }

}


