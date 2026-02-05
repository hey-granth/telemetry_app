/// Metric chart widget for displaying sensor data over time.
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../devices/domain/models/device.dart';

/// Sensor data chart widget
class SensorChart extends StatelessWidget {
  const SensorChart({
    super.key,
    required this.readings,
    this.showTemperature = true,
    this.showHumidity = true,
    this.showVoltage = false,
    this.height = 220,
  });

  final List<Reading> readings;
  final bool showTemperature;
  final bool showHumidity;
  final bool showVoltage;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final sortedReadings = [...readings]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Legend
          _ChartLegend(
            showTemperature: showTemperature,
            showHumidity: showHumidity,
            showVoltage: showVoltage,
          ),
          const SizedBox(height: AppSpacing.md),

          // Chart
          Expanded(
            child: LineChart(
              _buildChartData(sortedReadings, theme),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(List<Reading> readings, ThemeData theme) {
    final spots = <LineChartBarData>[];

    if (showTemperature) {
      final tempSpots = readings
          .where((r) => r.metrics.temperature != null)
          .map((r) => FlSpot(
                r.timestamp.millisecondsSinceEpoch.toDouble(),
                r.metrics.temperature!,
              ))
          .toList();

      if (tempSpots.isNotEmpty) {
        spots.add(_createLine(tempSpots, AppColors.temperature));
      }
    }

    if (showHumidity) {
      final humiditySpots = readings
          .where((r) => r.metrics.humidity != null)
          .map((r) => FlSpot(
                r.timestamp.millisecondsSinceEpoch.toDouble(),
                r.metrics.humidity!,
              ))
          .toList();

      if (humiditySpots.isNotEmpty) {
        spots.add(_createLine(humiditySpots, AppColors.humidity));
      }
    }

    if (showVoltage) {
      final voltageSpots = readings
          .where((r) => r.metrics.voltage != null)
          .map((r) => FlSpot(
                r.timestamp.millisecondsSinceEpoch.toDouble(),
                r.metrics.voltage! * 10, // Scale for visibility
              ))
          .toList();

      if (voltageSpots.isNotEmpty) {
        spots.add(_createLine(voltageSpots, AppColors.voltage));
      }
    }

    final minX = readings.first.timestamp.millisecondsSinceEpoch.toDouble();
    final maxX = readings.last.timestamp.millisecondsSinceEpoch.toDouble();

    return LineChartData(
      lineBarsData: spots,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            strokeWidth: 1,
            dashArray: [4, 4],
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: 20,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: (maxX - minX) / 4,
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Text(
                DateFormat.Hm().format(date),
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: theme.colorScheme.surface,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date =
                  DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              String unit = '';
              double value = spot.y;

              // Determine unit based on color
              if (spot.bar.color == AppColors.temperature) {
                unit = '°C';
              } else if (spot.bar.color == AppColors.humidity) {
                unit = '%';
              } else if (spot.bar.color == AppColors.voltage) {
                value = value / 10; // Unscale
                unit = 'V';
              }

              return LineTooltipItem(
                '${value.toStringAsFixed(1)}$unit\n${DateFormat.Hm().format(date)}',
                TextStyle(
                  color: spot.bar.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      minY: 0,
    );
  }

  LineChartBarData _createLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({
    required this.showTemperature,
    required this.showHumidity,
    required this.showVoltage,
  });

  final bool showTemperature;
  final bool showHumidity;
  final bool showVoltage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showTemperature)
          _LegendItem(color: AppColors.temperature, label: 'Temperature'),
        if (showTemperature && showHumidity)
          const SizedBox(width: AppSpacing.md),
        if (showHumidity)
          _LegendItem(color: AppColors.humidity, label: 'Humidity'),
        if ((showTemperature || showHumidity) && showVoltage)
          const SizedBox(width: AppSpacing.md),
        if (showVoltage)
          _LegendItem(color: AppColors.voltage, label: 'Voltage'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
