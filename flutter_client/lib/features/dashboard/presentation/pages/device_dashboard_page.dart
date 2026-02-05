/// Device dashboard page.
///
/// Displays live sensor data and historical charts for a single device.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/connection_indicator.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/metric_display.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../devices/domain/models/device.dart';
import '../../../devices/presentation/providers/device_providers.dart';
import '../../presentation/providers/dashboard_providers.dart';
import '../widgets/metric_chart.dart';
import '../widgets/time_range_selector.dart';

/// Device dashboard page
class DeviceDashboardPage extends ConsumerStatefulWidget {
  const DeviceDashboardPage({
    super.key,
    required this.deviceId,
  });

  final String deviceId;

  @override
  ConsumerState<DeviceDashboardPage> createState() =>
      _DeviceDashboardPageState();
}

class _DeviceDashboardPageState extends ConsumerState<DeviceDashboardPage> {
  String _selectedRange = '24h';

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket for live updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wsConnectionProvider).connectToDevice(widget.deviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceDetailAsync = ref.watch(deviceDetailProvider(widget.deviceId));
    final connectionStatus = ref.watch(connectionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ConnectionIndicator(status: connectionStatus),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(deviceDetailProvider(widget.deviceId).notifier).refresh();
            },
          ),
        ],
      ),
      body: deviceDetailAsync.when(
        loading: () => const _LoadingState(),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.read(deviceDetailProvider(widget.deviceId).notifier).refresh();
          },
        ),
        data: (detail) {
          if (detail.device == null) {
            return ErrorView(
              message: 'Device not found',
              title: 'Device Unavailable',
            );
          }

          return _ContentState(
            device: detail.device!,
            stats: detail.stats,
            history: detail.history ?? [],
            selectedRange: _selectedRange,
            onRangeChanged: (range) {
              setState(() => _selectedRange = range);
              // Refetch with new range
            },
          );
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        children: [
          // Device header skeleton
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Center(child: SkeletonLoader(width: 120, height: 24)),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Metrics skeleton
          Row(
            children: [
              Expanded(child: _MetricSkeleton()),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _MetricSkeleton()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _MetricSkeleton()),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chart skeleton
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Center(child: SkeletonLoader(width: 80, height: 16)),
          ),
        ],
      ),
    );
  }
}

class _MetricSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: const Center(child: SkeletonLoader(width: 60, height: 32)),
    );
  }
}

class _ContentState extends StatelessWidget {
  const _ContentState({
    required this.device,
    required this.stats,
    required this.history,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final Device device;
  final DeviceStats? stats;
  final List<Reading> history;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = device.latestReading?.metrics;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device header
            _DeviceHeader(device: device),
            const SizedBox(height: AppSpacing.lg),

            // Current readings
            Text(
              'Current Readings',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (metrics != null) ...[
              Row(
                children: [
                  if (metrics.temperature != null)
                    Expanded(
                      child: TemperatureMetric(value: metrics.temperature!),
                    ),
                  if (metrics.temperature != null && metrics.humidity != null)
                    const SizedBox(width: AppSpacing.md),
                  if (metrics.humidity != null)
                    Expanded(
                      child: HumidityMetric(value: metrics.humidity!),
                    ),
                ],
              ),
              if (metrics.voltage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: VoltageMetric(value: metrics.voltage!),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ] else
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Text(
                    'Waiting for data...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // Historical chart
            Row(
              children: [
                Expanded(
                  child: Text(
                    'History',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TimeRangeSelector(
                  selected: selectedRange,
                  onChanged: onRangeChanged,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (history.isNotEmpty)
              SensorChart(
                readings: history,
                showTemperature: true,
                showHumidity: true,
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No historical data',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),

            // Stats summary
            if (stats != null) ...[
              Text(
                'Statistics',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatsSummary(stats: stats!),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (device.isOnline ? AppColors.online : AppColors.offline)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.memory_rounded,
              size: 28,
              color: device.isOnline ? AppColors.online : AppColors.offline,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.displayName,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  device.deviceId,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            type: device.isOnline ? StatusType.online : StatusType.offline,
          ),
        ],
      ),
    );
  }
}

class _StatsSummary extends StatelessWidget {
  const _StatsSummary({required this.stats});

  final DeviceStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'Total Readings',
            value: stats.readingCount.toString(),
          ),
          const Divider(height: AppSpacing.lg),
          _StatRow(
            label: 'Avg Temperature',
            value: '${stats.temperature?.avg?.toStringAsFixed(1) ?? '--'}°C',
          ),
          const Divider(height: AppSpacing.lg),
          _StatRow(
            label: 'Avg Humidity',
            value: '${stats.humidity?.avg?.toStringAsFixed(1) ?? '--'}%',
          ),
          const Divider(height: AppSpacing.lg),
          _StatRow(
            label: 'Temp Range',
            value:
                '${stats.temperature?.min?.toStringAsFixed(1) ?? '--'} - ${stats.temperature?.max?.toStringAsFixed(1) ?? '--'}°C',
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
