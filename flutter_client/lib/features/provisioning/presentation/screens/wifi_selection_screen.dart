/// WiFi selection and credentials screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/provisioning_errors.dart';
import '../../domain/entities/provisioning_entities.dart';
import '../providers/esp32_provisioning_providers.dart';
import '../state/provisioning_state.dart';
import 'provisioning_progress_screen.dart';

/// Wi-Fi network selection screen
class WiFiSelectionScreen extends ConsumerStatefulWidget {
  const WiFiSelectionScreen({super.key});

  @override
  ConsumerState<WiFiSelectionScreen> createState() =>
      _WiFiSelectionScreenState();
}

class _WiFiSelectionScreenState extends ConsumerState<WiFiSelectionScreen> {
  WiFiNetwork? _selectedNetwork;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanNetworks();
  }

  Future<void> _scanNetworks() async {
    setState(() => _isScanning = true);
    await ref.read(esp32ProvisioningProvider.notifier).scanWiFiNetworks();
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esp32ProvisioningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Wi-Fi Network'),
      ),
      body: Column(
        children: [
          if (state.hasError) _buildErrorBanner(state.error!),
          if (_isScanning) _buildScanningIndicator(),
          Expanded(
            child: _buildNetworkList(state),
          ),
        ],
      ),
      floatingActionButton: _isScanning
          ? null
          : FloatingActionButton(
              onPressed: _scanNetworks,
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
            child: Text(
              error.userMessage,
              style: TextStyle(color: Colors.red.shade900),
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

  Widget _buildScanningIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Scanning Wi-Fi networks...'),
        ],
      ),
    );
  }

  Widget _buildNetworkList(ProvisioningState state) {
    if (state.availableNetworks.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No networks found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the refresh button to scan again',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.availableNetworks.length,
      itemBuilder: (context, index) {
        final network = state.availableNetworks[index];
        return _buildNetworkCard(network);
      },
    );
  }

  Widget _buildNetworkCard(WiFiNetwork network) {
    final isSelected = _selectedNetwork?.ssid == network.ssid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          _getWiFiIcon(network),
          color: _getSignalColor(network.rssi),
        ),
        title: Text(
          network.ssid,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${_getAuthModeName(network.authMode)} • Signal: ${network.rssi} dBm • Channel: ${network.channel}',
        ),
        trailing: network.isSecure
            ? const Icon(Icons.lock)
            : const Icon(Icons.lock_open),
        onTap: () => _showCredentialsDialog(network),
      ),
    );
  }

  IconData _getWiFiIcon(WiFiNetwork network) {
    final rssi = network.rssi;
    if (rssi >= -50) return Icons.wifi;
    if (rssi >= -70) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }

  String _getAuthModeName(WiFiAuthMode mode) {
    switch (mode) {
      case WiFiAuthMode.open:
        return 'Open';
      case WiFiAuthMode.wep:
        return 'WEP';
      case WiFiAuthMode.wpaPsk:
        return 'WPA';
      case WiFiAuthMode.wpa2Psk:
        return 'WPA2';
      case WiFiAuthMode.wpaWpa2Psk:
        return 'WPA/WPA2';
      case WiFiAuthMode.wpa2Enterprise:
        return 'WPA2 Enterprise';
      case WiFiAuthMode.wpa3Psk:
        return 'WPA3';
      case WiFiAuthMode.wpa2Wpa3Psk:
        return 'WPA2/WPA3';
    }
  }

  void _showCredentialsDialog(WiFiNetwork network) {
    setState(() => _selectedNetwork = network);

    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Connect to ${network.ssid}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (network.isSecure) ...[
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                  obscureText: obscurePassword,
                ),
                const SizedBox(height: 8),
              ],
              Text(
                '${_getAuthModeName(network.authMode)} • Signal: ${network.rssi} dBm',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _selectedNetwork = null);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (network.isSecure && passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter password')),
                  );
                  return;
                }

                Navigator.pop(context);
                _provisionNetwork(network, passwordController.text);
              },
              child: const Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _provisionNetwork(WiFiNetwork network, String password) async {
    final credentials = WiFiCredentials(
      ssid: network.ssid,
      password: password,
    );

    // Navigate to progress screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProvisioningProgressScreen(
          credentials: credentials,
        ),
      ),
    );
  }
}

