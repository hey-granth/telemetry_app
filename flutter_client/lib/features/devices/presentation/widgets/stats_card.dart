import 'package:flutter/material.dart';

import '../../domain/models/device.dart';

/// Card displaying aggregated statistics for a metric.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.title,
    required this.stats,
    required this.color,
    required this.icon,
  });

  final String title;
  final MetricStats stats;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatValue(
                    label: 'Min',
                    value: _formatValue(stats.min),
                    unit: stats.unit,
                    color: color,
                  ),
                ),
                Expanded(
                  child: _StatValue(
                    label: 'Avg',
                    value: _formatValue(stats.avg),
                    unit: stats.unit,
                    color: color,
                    isHighlighted: true,
                  ),
                ),
                Expanded(
                  child: _StatValue(
                    label: 'Max',
                    value: _formatValue(stats.max),
                    unit: stats.unit,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatValue(double? value) {
    if (value == null) return '--';
    return value.toStringAsFixed(1);
  }
}

class _StatValue extends StatelessWidget {
  const _StatValue({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: isHighlighted
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : null,
          decoration: isHighlighted
              ? BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlighted ? 20 : 16,
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                  color: isHighlighted ? color : theme.colorScheme.onSurface,
                ),
              ),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
