import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/websocket_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../devices/domain/models/device.dart';
import '../providers/live_stream_providers.dart';

/// Live stream page showing real-time readings.
class LiveStreamPage extends ConsumerStatefulWidget {
  const LiveStreamPage({
    super.key,
    this.deviceId,
  });

  /// Optional device ID to filter readings.
  /// If null, shows all device readings.
  final String? deviceId;

  @override
  ConsumerState<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends ConsumerState<LiveStreamPage> {
  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    final controller = ref.read(liveStreamControllerProvider);
    if (widget.deviceId != null) {
      controller.connectToDevice(widget.deviceId!);
    } else {
      controller.connectToAll();
    }
  }

  @override
  void dispose() {
    ref.read(liveStreamControllerProvider).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(wsConnectionStateProvider);
    final readings = ref.watch(liveReadingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceId != null
            ? 'Live: ${widget.deviceId}'
            : 'Live Stream'),
        actions: [
          _ConnectionIndicator(state: connectionState),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Connection banner
          if (connectionState != WsConnectionState.connected)
            _ConnectionBanner(state: connectionState),

          // Readings list
          Expanded(
            child: readings.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: readings.length,
                    itemBuilder: (context, index) {
                      return _ReadingTile(reading: readings[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(liveReadingsProvider.notifier).clear();
        },
        tooltip: 'Clear',
        child: const Icon(Icons.clear_all),
      ),
    );
  }
}

class _ConnectionIndicator extends StatelessWidget {
  const _ConnectionIndicator({required this.state});

  final WsConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (state) {
      WsConnectionState.connected => (AppTheme.success, Icons.wifi),
      WsConnectionState.connecting => (AppTheme.warning, Icons.wifi_find),
      WsConnectionState.reconnecting => (AppTheme.warning, Icons.wifi_find),
      WsConnectionState.disconnected => (AppTheme.error, Icons.wifi_off),
    };

    return Container(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state});

  final WsConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (message, color) = switch (state) {
      WsConnectionState.connecting => ('Connecting...', AppTheme.warning),
      WsConnectionState.reconnecting => ('Reconnecting...', AppTheme.warning),
      WsConnectionState.disconnected => ('Disconnected', AppTheme.error),
      WsConnectionState.connected => ('Connected', AppTheme.success),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: color.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: state == WsConnectionState.connecting ||
                    state == WsConnectionState.reconnecting
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensors,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for readings...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Readings will appear here in real-time',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({required this.reading});

  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = reading.metrics;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  reading.deviceId,
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  _formatTime(reading.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (metrics.temperature != null)
                  _MetricBadge(
                    icon: Icons.thermostat,
                    value: '${metrics.temperature!.toStringAsFixed(1)}°C',
                    color: AppTheme.temperatureColor,
                  ),
                if (metrics.humidity != null) ...[
                  const SizedBox(width: 8),
                  _MetricBadge(
                    icon: Icons.water_drop,
                    value: '${metrics.humidity!.toStringAsFixed(1)}%',
                    color: AppTheme.humidityColor,
                  ),
                ],
                if (metrics.voltage != null) ...[
                  const SizedBox(width: 8),
                  _MetricBadge(
                    icon: Icons.bolt,
                    value: '${metrics.voltage!.toStringAsFixed(2)}V',
                    color: AppTheme.voltageColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
