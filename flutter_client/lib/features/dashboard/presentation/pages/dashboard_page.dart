import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/dashboard_providers.dart';
import '../widgets/stats_card.dart';
import '../widgets/system_health_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final healthAsync = ref.watch(systemHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(systemHealthProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(systemHealthProvider);
          await Future.wait([
            ref.read(dashboardStatsProvider.future),
            ref.read(systemHealthProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              statsAsync.when(
                data: (stats) => _buildStatsGrid(context, stats, ref),
                loading: () => const _LoadingGrid(),
                error: (error, _) => _ErrorCard(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(dashboardStatsProvider),
                ),
              ),
              const SizedBox(height: 24),
              healthAsync.when(
                data: (health) => SystemHealthCard(
                  health: health,
                  onRefresh: () => ref.invalidate(systemHealthProvider),
                ),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => _ErrorCard(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(systemHealthProvider),
                ),
              ),
              const SizedBox(height: 24),
              statsAsync.when(
                data: (stats) => _buildAveragesSection(context, stats),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s your IoT platform overview',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildStatsGrid(
    BuildContext context,
    dynamic stats,
    WidgetRef ref,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        StatsCard(
          title: 'Total Devices',
          value: stats.totalDevices.toString(),
          icon: Icons.devices,
          iconColor: Colors.blue,
          onTap: () => _navigateToDevices(context),
        ),
        StatsCard(
          title: 'Online',
          value: stats.onlineDevices.toString(),
          subtitle: '${stats.onlinePercentage.toStringAsFixed(1)}% uptime',
          icon: Icons.wifi,
          iconColor: Colors.green,
        ),
        StatsCard(
          title: 'Offline',
          value: stats.offlineDevices.toString(),
          icon: Icons.wifi_off,
          iconColor: Colors.red,
        ),
        StatsCard(
          title: 'Readings Today',
          value: _formatNumber(stats.totalReadingsToday),
          icon: Icons.analytics,
          iconColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAveragesSection(BuildContext context, dynamic stats) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average Readings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                label: 'Temperature',
                value: stats.avgTemperature,
                unit: '°C',
                icon: Icons.thermostat,
                color: Colors.orange,
                minValue: -10,
                maxValue: 50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Humidity',
                value: stats.avgHumidity,
                unit: '%',
                icon: Icons.water_drop,
                color: Colors.blue,
                minValue: 0,
                maxValue: 100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                label: 'Voltage',
                value: stats.avgVoltage,
                unit: 'V',
                icon: Icons.bolt,
                color: Colors.amber,
                minValue: 0,
                maxValue: 5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  void _navigateToDevices(BuildContext context) {
    // Navigate to devices page
    Navigator.of(context).pushNamed('/devices');
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: List.generate(
        4,
        (_) => const Card(
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load data',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
