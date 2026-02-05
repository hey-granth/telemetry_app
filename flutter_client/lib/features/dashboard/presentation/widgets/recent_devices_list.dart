/// Recent devices list widget.
///
/// Displays a list of recently active devices with quick status.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../devices/domain/models/device.dart';

class RecentDevicesList extends StatelessWidget {
  const RecentDevicesList({
    super.key,
    required this.devices,
    this.onDeviceTap,
  });

  final List<Device> devices;
  final void Function(Device)? onDeviceTap;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: devices.map((device) {
        return RecentDeviceCard(
          device: device,
          onTap: onDeviceTap != null ? () => onDeviceTap!(device) : null,
        );
      }).toList(),
    );
  }
}

class RecentDeviceCard extends StatelessWidget {
  const RecentDeviceCard({
    super.key,
    required this.device,
    this.onTap,
  });

  final Device device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metrics = device.latestReading?.metrics;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Device icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (device.isOnline ? AppColors.online : AppColors.offline)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.memory_rounded,
                  color: device.isOnline ? AppColors.online : AppColors.offline,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Device info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.displayName,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(
                          type: device.isOnline
                              ? StatusType.online
                              : StatusType.offline,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (metrics != null)
                      _MetricsSummary(metrics: metrics)
                    else
                      Text(
                        _getLastSeenText(device),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Chevron
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLastSeenText(Device device) {
    if (device.lastSeenAt == null) {
      return 'Never connected';
    }

    final diff = DateTime.now().difference(device.lastSeenAt!);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _MetricsSummary extends StatelessWidget {
  const _MetricsSummary({required this.metrics});

  final Metrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <Widget>[];

    if (metrics.temperature != null) {
      items.add(_MetricChip(
        icon: Icons.thermostat_outlined,
        value: '${metrics.temperature!.toStringAsFixed(1)}°C',
        color: AppColors.temperature,
      ));
    }

    if (metrics.humidity != null) {
      items.add(_MetricChip(
        icon: Icons.water_drop_outlined,
        value: '${metrics.humidity!.toStringAsFixed(0)}%',
        color: AppColors.humidity,
      ));
    }

    if (metrics.voltage != null) {
      items.add(_MetricChip(
        icon: Icons.bolt_outlined,
        value: '${metrics.voltage!.toStringAsFixed(1)}V',
        color: AppColors.voltage,
      ));
    }

    if (items.isEmpty) {
      return Text(
        'No data',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: items,
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
