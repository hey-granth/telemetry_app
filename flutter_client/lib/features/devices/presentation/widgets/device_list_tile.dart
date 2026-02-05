import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/models/device.dart';

/// List tile widget for displaying a device in the device list.
class DeviceListTile extends StatelessWidget {
  const DeviceListTile({
    super.key,
    required this.device,
    this.onTap,
  });

  final Device device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = device.latestReading;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Device icon with status color
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
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Text(
                          _buildSubtitle(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (latest?.metrics != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _buildMetricsRow(latest!.metrics, theme),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

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

  Widget _buildMetricsRow(Metrics metrics, ThemeData theme) {
    final items = <Widget>[];

    if (metrics.temperature != null) {
      items.add(_MetricChip(
        icon: Icons.thermostat_outlined,
        value: '${metrics.temperature!.toStringAsFixed(1)}°',
        color: AppColors.temperature,
      ));
    }

    if (metrics.humidity != null) {
      if (items.isNotEmpty) items.add(const SizedBox(width: AppSpacing.sm));
      items.add(_MetricChip(
        icon: Icons.water_drop_outlined,
        value: '${metrics.humidity!.toStringAsFixed(0)}%',
        color: AppColors.humidity,
      ));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }

  String _buildSubtitle() {
    if (!device.isActive) return 'Inactive';

    final duration = device.timeSinceLastSeen;
    if (duration == null) return 'Never seen';

    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
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
