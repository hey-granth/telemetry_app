/// Provisioning progress screen
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/provisioning_entities.dart';
import '../providers/esp32_provisioning_providers.dart';
import '../state/provisioning_state.dart';

/// Provisioning progress and status screen
class ProvisioningProgressScreen extends ConsumerStatefulWidget {
  const ProvisioningProgressScreen({
    required this.credentials,
    super.key,
  });

  final WiFiCredentials credentials;

  @override
  ConsumerState<ProvisioningProgressScreen> createState() =>
      _ProvisioningProgressScreenState();
}

class _ProvisioningProgressScreenState
    extends ConsumerState<ProvisioningProgressScreen> {
  @override
  void initState() {
    super.initState();
    _startProvisioning();
  }

  Future<void> _startProvisioning() async {
    await ref
        .read(esp32ProvisioningProvider.notifier)
        .provisionWiFi(widget.credentials);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esp32ProvisioningProvider);

    return WillPopScope(
      onWillPop: () async => state.isComplete || state.hasError,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Provisioning'),
          automaticallyImplyLeading: state.isComplete || state.hasError,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusIcon(state),
                const SizedBox(height: 32),
                _buildProgressIndicator(state),
                const SizedBox(height: 24),
                _buildStatusText(state),
                const SizedBox(height: 16),
                _buildPhaseText(state),
                const SizedBox(height: 32),
                _buildActionButtons(state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ProvisioningState state) {
    if (state.isComplete) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle,
          size: 80,
          color: Colors.green.shade700,
        ),
      );
    }

    if (state.hasError) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.error,
          size: 80,
          color: Colors.red.shade700,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.router,
        size: 80,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildProgressIndicator(ProvisioningState state) {
    if (state.isComplete || state.hasError) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: state.progress,
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(state.progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(ProvisioningState state) {
    if (state.isComplete) {
      return const Text(
        'Provisioning Successful!',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        textAlign: TextAlign.center,
      );
    }

    if (state.hasError) {
      return Column(
        children: [
          const Text(
            'Provisioning Failed',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Text(
              state.error!.userMessage,
              style: TextStyle(color: Colors.red.shade900),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return const Text(
      'Provisioning Device',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPhaseText(ProvisioningState state) {
    if (state.isComplete || state.hasError) {
      return const SizedBox.shrink();
    }

    return Text(
      _getPhaseDescription(state.phase),
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade600,
      ),
      textAlign: TextAlign.center,
    );
  }

  String _getPhaseDescription(ProvisioningPhase phase) {
    switch (phase) {
      case ProvisioningPhase.idle:
        return 'Preparing...';
      case ProvisioningPhase.scanningDevices:
        return 'Scanning for devices...';
      case ProvisioningPhase.connecting:
        return 'Connecting to device...';
      case ProvisioningPhase.establishingSession:
        return 'Establishing secure session...';
      case ProvisioningPhase.scanningWiFi:
        return 'Scanning Wi-Fi networks...';
      case ProvisioningPhase.sendingCredentials:
        return 'Sending Wi-Fi credentials...';
      case ProvisioningPhase.applyingConfig:
        return 'Applying configuration...';
      case ProvisioningPhase.verifying:
        return 'Verifying connection...';
      case ProvisioningPhase.success:
        return 'Complete';
      case ProvisioningPhase.failure:
        return 'Failed';
    }
  }

  Widget _buildActionButtons(ProvisioningState state) {
    if (state.isLoading) {
      return const SizedBox.shrink();
    }

    if (state.isComplete) {
      return Column(
        children: [
          const Text(
            'Your device has been successfully provisioned and connected to Wi-Fi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _finishProvisioning(),
            icon: const Icon(Icons.check),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      );
    }

    if (state.hasError) {
      return Column(
        children: [
          if (state.error!.isRecoverable) ...[
            ElevatedButton.icon(
              onPressed: () => _retryProvisioning(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () => _cancelProvisioning(),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _retryProvisioning() async {
    ref.read(esp32ProvisioningProvider.notifier).clearError();
    await _startProvisioning();
  }

  void _cancelProvisioning() {
    ref.read(esp32ProvisioningProvider.notifier).reset();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _finishProvisioning() {
    ref.read(esp32ProvisioningProvider.notifier).reset();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

