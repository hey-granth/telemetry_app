/// Onboarding page for device discovery and selection.
///
/// Entry point for adding new devices via BLE scanning.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/discovered_device_card.dart';

/// Onboarding page for device discovery
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  @override
  void initState() {
    super.initState();
    // Start scanning when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bleScanProvider.notifier).startScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(bleScanProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (scanState.isScanning)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Scanning...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Instructions header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.bluetooth_searching,
                        size: 20,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Looking for devices',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Make sure your ESP32 device is powered on and in pairing mode.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(context, scanState),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, scanState),
    );
  }

  Widget _buildContent(BuildContext context, BleScanState scanState) {
    if (scanState.error != null) {
      return ErrorView(
        message: scanState.error!,
        title: 'Scan failed',
        onRetry: () => ref.read(bleScanProvider.notifier).startScan(),
      );
    }

    if (scanState.isScanning && scanState.devices.isEmpty) {
      return _LoadingState();
    }

    if (scanState.devices.isEmpty) {
      return ScanEmptyState(
        isScanning: scanState.isScanning,
        onRetry: () => ref.read(bleScanProvider.notifier).startScan(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(bleScanProvider.notifier).startScan();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: scanState.devices.length,
        itemBuilder: (context, index) {
          final device = scanState.devices[index];
          return DiscoveredDeviceCard(
            device: device,
            onTap: () => _selectDevice(device),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BleScanState scanState) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: scanState.isScanning
                  ? () => ref.read(bleScanProvider.notifier).stopScan()
                  : () => ref.read(bleScanProvider.notifier).startScan(),
              icon: Icon(
                scanState.isScanning ? Icons.stop : Icons.refresh,
              ),
              label: Text(
                scanState.isScanning ? 'Stop Scan' : 'Scan Again',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: FilledButton(
              onPressed: () => _manualEntry(),
              child: const Text('Manual Entry'),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDevice(DiscoveredDevice device) {
    Navigator.of(context).pushNamed(
      '/provisioning/wifi',
      arguments: WifiCredentialsArgs(
        deviceId: device.id,
        deviceName: device.name,
      ),
    );
  }

  void _manualEntry() {
    // Show manual device ID entry dialog
    showDialog(
      context: context,
      builder: (context) => const _ManualEntryDialog(),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) => const DeviceCardSkeleton(),
    );
  }
}

class _ManualEntryDialog extends ConsumerStatefulWidget {
  const _ManualEntryDialog();

  @override
  ConsumerState<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends ConsumerState<_ManualEntryDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Enter Device ID'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter the device ID shown on your ESP32 device.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g., esp32_001',
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() => _error = null);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  void _submit() {
    final deviceId = _controller.text.trim();
    if (deviceId.isEmpty) {
      setState(() => _error = 'Device ID is required');
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(deviceId)) {
      setState(() => _error = 'Invalid device ID format');
      return;
    }

    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(
      '/provisioning/wifi',
      arguments: WifiCredentialsArgs(
        deviceId: deviceId,
        deviceName: deviceId,
      ),
    );
  }
}

