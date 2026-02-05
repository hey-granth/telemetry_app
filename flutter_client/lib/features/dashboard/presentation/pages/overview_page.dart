/// Overview/Landing page.
///
/// Main dashboard showing system status and quick actions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/connection_indicator.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/metric_display.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../devices/domain/models/device.dart';
import '../../../devices/presentation/providers/device_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/quick_stats_card.dart';
import '../widgets/recent_devices_list.dart';

/// Overview page showing system status and summary
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final connectionStatus = ref.watch(connectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ConnectionIndicator(status: connectionStatus),
          ),
        ],
      ),
      body: devicesAsync.when(
        loading: () => const _LoadingState(),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(devicesProvider.notifier).refresh(),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return _EmptyState(
              onAddDevice: () => _navigateToOnboarding(context),
            );
          }

          return _ContentState(
            devices: devices,
            onAddDevice: () => _navigateToOnboarding(context),
          );
        },
      ),
    );
  }

  void _navigateToOnboarding(BuildContext context) {
    Navigator.of(context).pushNamed('/onboarding');
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddDevice});

  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    return DevicesEmptyState(onAddDevice: onAddDevice);
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Quick Stats'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: const Center(child: SkeletonLoader(width: 60, height: 32)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: const Center(child: SkeletonLoader(width: 60, height: 32)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Recent Devices'),
          ...List.generate(3, (index) => const DeviceCardSkeleton()),
        ],
      ),
    );
  }
}

class _ContentState extends StatelessWidget {
  const _ContentState({
    required this.devices,
    required this.onAddDevice,
  });

  final List<Device> devices;
  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    final onlineDevices = devices.where((d) => d.isOnline).toList();
    final recentDevices = devices.take(5).toList();

    // Calculate average metrics from online devices
    final avgTemp = _calculateAverageMetric(
      onlineDevices,
      (m) => m.temperature,
    );
    final avgHumidity = _calculateAverageMetric(
      onlineDevices,
      (m) => m.humidity,
    );

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh via provider
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick stats section
            const SectionHeader(title: 'Quick Stats'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                children: [
                  Expanded(
                    child: QuickStatsCard(
                      label: 'Total Devices',
                      value: devices.length.toString(),
                      icon: Icons.sensors,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: QuickStatsCard(
                      label: 'Online',
                      value: onlineDevices.length.toString(),
                      icon: Icons.wifi,
                      color: AppColors.online,
                      subtitle: '${_getOnlinePercentage(devices)}%',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Average metrics if available
            if (avgTemp != null || avgHumidity != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Row(
                  children: [
                    if (avgTemp != null)
                      Expanded(
                        child: TemperatureMetric(value: avgTemp),
                      ),
                    if (avgTemp != null && avgHumidity != null)
                      const SizedBox(width: AppSpacing.md),
                    if (avgHumidity != null)
                      Expanded(
                        child: HumidityMetric(value: avgHumidity),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Recent devices section
            SectionHeader(
              title: 'Recent Devices',
              action: TextButton(
                onPressed: () {
                  // Navigate to devices tab
                },
                child: const Text('See All'),
              ),
            ),
            RecentDevicesList(devices: recentDevices),

            // Add device CTA
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddDevice,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Device'),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  double? _calculateAverageMetric(
    List<Device> devices,
    double? Function(Metrics) selector,
  ) {
    final values = devices
        .where((d) => d.latestReading?.metrics != null)
        .map((d) => selector(d.latestReading!.metrics))
        .whereType<double>()
        .toList();

    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  int _getOnlinePercentage(List<Device> devices) {
    if (devices.isEmpty) return 0;
    final online = devices.where((d) => d.isOnline).length;
    return ((online / devices.length) * 100).round();
  }
}
