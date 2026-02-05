import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Empty state illustration and message.
///
/// Clean visual for when content is not available.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with gradient background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.emptyStateGradientDark
                    : AppColors.emptyStateGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppSpacing.iconXxl,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action button
            if (action != null || (actionLabel != null && onAction != null)) ...[
              const SizedBox(height: AppSpacing.lg),
              action ??
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(actionLabel!),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state specifically for device lists
class DevicesEmptyState extends StatelessWidget {
  const DevicesEmptyState({
    super.key,
    required this.onAddDevice,
  });

  final VoidCallback onAddDevice;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.sensors_off_outlined,
      title: 'No devices yet',
      description: 'Add your first device to start monitoring sensor data.',
      actionLabel: 'Add Device',
      onAction: onAddDevice,
    );
  }
}

/// Empty state for scan results
class ScanEmptyState extends StatelessWidget {
  const ScanEmptyState({
    super.key,
    this.isScanning = false,
    this.onRetry,
  });

  final bool isScanning;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: isScanning ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
      title: isScanning ? 'Scanning for devices...' : 'No devices found',
      description: isScanning
          ? 'Make sure your device is in pairing mode'
          : 'Ensure Bluetooth is enabled and devices are nearby',
      action: isScanning
          ? const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : null,
      actionLabel: isScanning ? null : 'Scan Again',
      onAction: onRetry,
    );
  }
}
