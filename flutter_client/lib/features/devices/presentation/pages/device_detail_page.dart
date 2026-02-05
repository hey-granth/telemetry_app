import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/device.dart';
import '../providers/device_providers.dart';
import '../widgets/live_reading_card.dart';
import '../widgets/metric_chart.dart';
import '../widgets/stats_card.dart';
import '../widgets/time_range_selector.dart';

/// Device detail page.
///
/// Displays detailed information about a device including:
/// - Current readings (live)
/// - Historical charts
/// - Aggregated statistics
class DeviceDetailPage extends ConsumerStatefulWidget {
  const DeviceDetailPage({
    super.key,
    required this.deviceId,
  });

  final String deviceId;

  @override
  ConsumerState<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends ConsumerState<DeviceDetailPage> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(deviceDetailProvider(widget.deviceId));
    final selectedRange = ref.watch(selectedTimeRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceId),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(deviceDetailProvider(widget.deviceId).notifier)
                .refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref
              .read(deviceDetailProvider(widget.deviceId).notifier)
              .refresh(),
        ),
        data: (detail) => _DetailContent(
          detail: detail,
          selectedRange: selectedRange,
          onRangeChanged: (range) {
            ref.read(selectedTimeRangeProvider.notifier).state = range;
            // Refresh with new range
            ref.read(deviceDetailProvider(widget.deviceId).notifier).refresh();
          },
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  final DeviceDetailState detail;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;

  @override
  Widget build(BuildContext context) {
    final device = detail.device;
    final stats = detail.stats;
    final history = detail.history ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by parent
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device status header
            if (device != null) _DeviceHeader(device: device),

            const SizedBox(height: 16),

            // Live reading card
            if (device?.latestReading != null)
              LiveReadingCard(reading: device!.latestReading!),

            const SizedBox(height: 24),

            // Time range selector
            TimeRangeSelector(
              selected: selectedRange,
              onChanged: onRangeChanged,
            ),

            const SizedBox(height: 16),

            // Statistics cards
            if (stats != null) ...[
              Text(
                'Statistics',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _StatsGrid(stats: stats),
              const SizedBox(height: 24),
            ],

            // Charts
            if (history.isNotEmpty) ...[
              Text(
                'History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Temperature chart
              MetricChart(
                title: 'Temperature',
                unit: '°C',
                color: AppTheme.temperatureColor,
                readings: history,
                valueExtractor: (r) => r.metrics.temperature,
              ),
              const SizedBox(height: 16),

              // Humidity chart
              MetricChart(
                title: 'Humidity',
                unit: '%',
                color: AppTheme.humidityColor,
                readings: history,
                valueExtractor: (r) => r.metrics.humidity,
              ),
              const SizedBox(height: 16),

              // Voltage chart
              MetricChart(
                title: 'Voltage',
                unit: 'V',
                color: AppTheme.voltageColor,
                readings: history,
                valueExtractor: (r) => r.metrics.voltage,
              ),
            ],

            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No readings in selected time range'),
                ),
              ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: device.isOnline
                    ? AppTheme.success
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 12),

            // Device info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.isOnline ? 'Online' : _formatLastSeen(device),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),

            // Reading count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${device.readingCount}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'readings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(Device device) {
    final duration = device.timeSinceLastSeen;
    if (duration == null) return 'Never seen';

    if (duration.inMinutes < 60) {
      return 'Last seen ${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return 'Last seen ${duration.inHours}h ago';
    } else {
      return 'Last seen ${duration.inDays}d ago';
    }
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final DeviceStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (stats.temperature != null)
          StatsCard(
            title: 'Temperature',
            stats: stats.temperature!,
            color: AppTheme.temperatureColor,
            icon: Icons.thermostat,
          ),
        if (stats.humidity != null) ...[
          const SizedBox(height: 8),
          StatsCard(
            title: 'Humidity',
            stats: stats.humidity!,
            color: AppTheme.humidityColor,
            icon: Icons.water_drop,
          ),
        ],
        if (stats.voltage != null) ...[
          const SizedBox(height: 8),
          StatsCard(
            title: 'Voltage',
            stats: stats.voltage!,
            color: AppTheme.voltageColor,
            icon: Icons.bolt,
          ),
        ],
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
