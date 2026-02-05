import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(devicesProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: devicesAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: 5,
          itemBuilder: (context, index) => const DeviceCardSkeleton(),
        ),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(devicesProvider.notifier).refresh(),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return DevicesEmptyState(
              onAddDevice: () => _navigateToOnboarding(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(devicesProvider.notifier).refresh(),
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
