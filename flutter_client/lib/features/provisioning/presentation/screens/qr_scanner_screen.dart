/// QR code scanner screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../providers/esp32_provisioning_providers.dart';
import 'wifi_selection_screen.dart';

/// QR code scanner for automatic provisioning
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission required for QR scanning'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          _buildQrView(),
          _buildOverlay(),
          if (_isProcessing) _buildProcessingIndicator(),
        ],
      ),
    );
  }

  Widget _buildQrView() {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Theme.of(context).primaryColor,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: 300,
      ),
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        const Spacer(),
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.all(24),
          child: const Column(
            children: [
              Text(
                'Scan Device QR Code',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Position the QR code within the frame',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing QR code...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _processQrCode(scanData.code!);
      }
    });
  }

  Future<void> _processQrCode(String qrData) async {
    setState(() => _isProcessing = true);

    try {
      // Parse QR code
      ref.read(esp32ProvisioningProvider.notifier).parseQrCode(qrData);

      final state = ref.read(esp32ProvisioningProvider);

      if (state.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!.userMessage),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isProcessing = false);
        }
        return;
      }

      final qrDataParsed = state.qrData;
      if (qrDataParsed == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to parse QR code'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isProcessing = false);
        }
        return;
      }

      // Start device scan to find the device
      await ref.read(esp32ProvisioningProvider.notifier).startDeviceScan(
            timeout: const Duration(seconds: 15),
          );

      if (!mounted) return;

      final scanState = ref.read(esp32ProvisioningProvider);

      // Find device by name
      final device = scanState.discoveredDevices.where(
        (d) => d.name.contains(qrDataParsed.serviceName),
      ).firstOrNull;

      if (device == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Device "${qrDataParsed.serviceName}" not found nearby'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isProcessing = false);
        }
        return;
      }

      // Connect to device
      await ref
          .read(esp32ProvisioningProvider.notifier)
          .connectToDevice(device);

      if (!mounted) return;

      final connectState = ref.read(esp32ProvisioningProvider);
      if (connectState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(connectState.error!.userMessage),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Establish secure session
      await ref
          .read(esp32ProvisioningProvider.notifier)
          .establishSecureSession(
            proofOfPossession: qrDataParsed.proofOfPossession,
          );

      if (!mounted) return;

      final sessionState = ref.read(esp32ProvisioningProvider);
      if (sessionState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(sessionState.error!.userMessage),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Navigate to Wi-Fi selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WiFiSelectionScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }
}

