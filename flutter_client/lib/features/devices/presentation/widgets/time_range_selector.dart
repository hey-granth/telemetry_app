import 'package:flutter/material.dart';

import '../providers/device_providers.dart';

/// Widget for selecting time range for data queries.
class TimeRangeSelector extends StatelessWidget {
  const TimeRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: availableTimeRanges.map((range) {
          final isSelected = range == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_formatRange(range)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(range);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatRange(String range) {
    return switch (range) {
      '1h' => '1 Hour',
      '6h' => '6 Hours',
      '24h' => '24 Hours',
      '7d' => '7 Days',
      '30d' => '30 Days',
      _ => range,
    };
  }
}
