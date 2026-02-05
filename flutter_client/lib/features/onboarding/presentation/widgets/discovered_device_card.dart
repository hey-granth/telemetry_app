/// Discovered device card widget.
///
/// Card displaying a BLE-discovered device for selection.
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/onboarding_providers.dart';

class DiscoveredDeviceCard extends StatelessWidget {
  const DiscoveredDeviceCard({
    super.key,
    required this.device,
    this.onTap,
  });

  final DiscoveredDevice device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: device.isPaired
              ? AppColors.success.withOpacity(0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Signal strength indicator
              _SignalStrengthIcon(rssi: device.rssi),
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
                            device.name,
                            style: theme.textTheme.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(
                          type: device.isPaired
                              ? StatusType.paired
                              : StatusType.newDevice,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: [
                        Text(
                          device.id,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '•',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          device.signalQuality,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getSignalColor(device.signalStrength),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action icon
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

  Color _getSignalColor(int strength) {
    if (strength >= 80) return AppColors.success;
    if (strength >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

class _SignalStrengthIcon extends StatelessWidget {
  const _SignalStrengthIcon({required this.rssi});

  final int rssi;

  @override
  Widget build(BuildContext context) {
    final strength = _getStrengthLevel();
    final color = _getColor();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Center(
        child: _SignalBars(level: strength, color: color),
      ),
    );
  }

  int _getStrengthLevel() {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }

  Color _getColor() {
    if (rssi >= -60) return AppColors.success;
    if (rssi >= -75) return AppColors.warning;
    return AppColors.error;
  }
}

class _SignalBars extends StatelessWidget {
  const _SignalBars({
    required this.level,
    required this.color,
  });

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final height = 6.0 + (index * 4);
        final isActive = index < level;

        return Container(
          width: 4,
          height: height,
          margin: EdgeInsets.only(left: index > 0 ? 2 : 0),
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
