import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Metric display card for sensor values.
///
/// Shows value, unit, and optional trend indicator.
class MetricDisplay extends StatelessWidget {
  const MetricDisplay({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.color,
    this.icon,
    this.trend,
    this.compact = false,
  });

  final String label;
  final String value;
  final String unit;
  final Color? color;
  final IconData? icon;
  final double? trend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.colorScheme.primary;

    if (compact) {
      return _CompactMetricDisplay(
        label: label,
        value: value,
        unit: unit,
        color: displayColor,
        icon: icon,
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with label and icon
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: displayColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Value with unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: displayColor,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                unit,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (trend != null) ...[
                const Spacer(),
                _TrendIndicator(trend: trend!),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactMetricDisplay extends StatelessWidget {
  const _CompactMetricDisplay({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({required this.trend});

  final double trend;

  @override
  Widget build(BuildContext context) {
    final isPositive = trend > 0;
    final isZero = trend.abs() < 0.01;
    final color = isZero
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : isPositive
            ? AppColors.success
            : AppColors.error;
    final icon = isZero
        ? Icons.remove_rounded
        : isPositive
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text(
          '${isPositive ? '+' : ''}${trend.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Temperature metric display
class TemperatureMetric extends StatelessWidget {
  const TemperatureMetric({
    super.key,
    required this.value,
    this.trend,
    this.compact = false,
  });

  final double value;
  final double? trend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return MetricDisplay(
      label: 'Temperature',
      value: value.toStringAsFixed(1),
      unit: '°C',
      color: AppColors.temperature,
      icon: Icons.thermostat_outlined,
      trend: trend,
      compact: compact,
    );
  }
}

/// Humidity metric display
class HumidityMetric extends StatelessWidget {
  const HumidityMetric({
    super.key,
    required this.value,
    this.trend,
    this.compact = false,
  });

  final double value;
  final double? trend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return MetricDisplay(
      label: 'Humidity',
      value: value.toStringAsFixed(1),
      unit: '%',
      color: AppColors.humidity,
      icon: Icons.water_drop_outlined,
      trend: trend,
      compact: compact,
    );
  }
}

/// Voltage metric display
class VoltageMetric extends StatelessWidget {
  const VoltageMetric({
    super.key,
    required this.value,
    this.trend,
    this.compact = false,
  });

  final double value;
  final double? trend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return MetricDisplay(
      label: 'Voltage',
      value: value.toStringAsFixed(2),
      unit: 'V',
      color: AppColors.voltage,
      icon: Icons.bolt_outlined,
      trend: trend,
      compact: compact,
    );
  }
}
