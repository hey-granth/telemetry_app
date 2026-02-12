import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/app_lifecycle.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../providers/device_providers.dart';
import '../widgets/device_list_tile.dart';
import 'device_detail_page.dart';

/// Main devices list page.
///
/// Displays all registered devices with their current status.
class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
    // Fetch devices after first frame if backend is reachable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataIfNeeded();
    });
  }

  void _fetchDataIfNeeded() {
    if (_hasFetched) return;

    final backendStatus = ref.read(backendStatusProvider);
    if (backendStatus.isReachable) {
      _hasFetched = true;
      ref.read(devicesProvider.notifier).fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesProvider);
    final backendStatus = ref.watch(backendStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          if (backendStatus.isReachable)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() => _hasFetched = true);
                ref.read(devicesProvider.notifier).fetch();
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: !backendStatus.isReachable && !_hasFetched
          ? _OfflineState(
              onRetry: () {
                setState(() => _hasFetched = false);
                _fetchDataIfNeeded();
              },
              onAddDevice: () => _navigateToOnboarding(context),
            )
          : devicesAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: 5,
                itemBuilder: (context, index) => const DeviceCardSkeleton(),
              ),
              error: (error, stack) => ErrorView(
                message: error.toString(),
                onRetry: () {
                  setState(() => _hasFetched = false);
                  ref.read(devicesProvider.notifier).fetch();
                },
              ),
              data: (devices) {
                if (devices.isEmpty) {
                  return DevicesEmptyState(
                    onAddDevice: () => _navigateToOnboarding(context),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () {
                    setState(() => _hasFetched = true);
                    return ref.read(devicesProvider.notifier).fetch();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return DeviceListTile(
                        device: device,
                        onTap: () => _navigateToDetail(context, device.deviceId),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToOnboarding(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String deviceId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DeviceDetailPage(deviceId: deviceId),
      ),
    );
  }

  void _navigateToOnboarding(BuildContext context) {
    Navigator.of(context).pushNamed('/onboarding');
  }
}

class _OfflineState extends StatelessWidget {
  const _OfflineState({
    required this.onRetry,
    required this.onAddDevice,
  });

  final VoidCallback onRetry;
  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Backend Offline',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cannot load devices from server.\nYou can still add new devices via BLE.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAddDevice,
              icon: const Icon(Icons.add),
              label: const Text('Add Device via BLE'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}

