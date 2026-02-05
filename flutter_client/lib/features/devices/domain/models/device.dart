import 'package:equatable/equatable.dart';

/// Device domain model.
///
/// Immutable representation of an IoT device.
class Device extends Equatable {
  const Device({
    required this.id,
    required this.deviceId,
    required this.isActive,
    required this.createdAt,
    this.name,
    this.lastSeenAt,
    this.readingCount = 0,
    this.latestReading,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      name: json['name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
      readingCount: json['reading_count'] as int? ?? 0,
      latestReading: json['latest_reading'] != null
          ? Reading.fromJson(json['latest_reading'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String deviceId;
  final String? name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastSeenAt;
  final int readingCount;
  final Reading? latestReading;

  /// Display name (name or device_id)
  String get displayName => name ?? deviceId;

  /// Check if device is online (seen in last 5 minutes)
  bool get isOnline {
    if (lastSeenAt == null) return false;
    return DateTime.now().difference(lastSeenAt!).inMinutes < 5;
  }

  /// Time since last seen
  Duration? get timeSinceLastSeen {
    if (lastSeenAt == null) return null;
    return DateTime.now().difference(lastSeenAt!);
  }

  @override
  List<Object?> get props => [
        id,
        deviceId,
        name,
        isActive,
        createdAt,
        lastSeenAt,
        readingCount,
        latestReading,
      ];

  Device copyWith({
    String? id,
    String? deviceId,
    String? name,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastSeenAt,
    int? readingCount,
    Reading? latestReading,
  }) {
    return Device(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      readingCount: readingCount ?? this.readingCount,
      latestReading: latestReading ?? this.latestReading,
    );
  }
}

/// Sensor reading domain model.
///
/// Immutable representation of a sensor reading.
class Reading extends Equatable {
  const Reading({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.metrics,
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metrics: Metrics.fromJson(json['metrics'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String deviceId;
  final DateTime timestamp;
  final Metrics metrics;

  @override
  List<Object?> get props => [id, deviceId, timestamp, metrics];
}

/// Sensor metrics value object.
///
/// Contains sensor readings with explicit units.
class Metrics extends Equatable {
  const Metrics({
    this.temperature,
    this.humidity,
    this.voltage,
  });

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      voltage: (json['voltage'] as num?)?.toDouble(),
    );
  }

  /// Temperature in degrees Celsius
  final double? temperature;

  /// Relative humidity percentage
  final double? humidity;

  /// Power/battery voltage in volts
  final double? voltage;

  /// Check if any metric is present
  bool get hasAnyMetric =>
      temperature != null || humidity != null || voltage != null;

  @override
  List<Object?> get props => [temperature, humidity, voltage];
}

/// Device statistics domain model.
class DeviceStats extends Equatable {
  const DeviceStats({
    required this.deviceId,
    required this.timeRange,
    required this.readingCount,
    this.firstReading,
    this.lastReading,
    this.temperature,
    this.humidity,
    this.voltage,
  });

  factory DeviceStats.fromJson(Map<String, dynamic> json) {
    return DeviceStats(
      deviceId: json['device_id'] as String,
      timeRange:
          TimeRangeInfo.fromJson(json['time_range'] as Map<String, dynamic>),
      readingCount: json['reading_count'] as int,
      firstReading: json['first_reading'] != null
          ? DateTime.parse(json['first_reading'] as String)
          : null,
      lastReading: json['last_reading'] != null
          ? DateTime.parse(json['last_reading'] as String)
          : null,
      temperature: json['temperature'] != null
          ? MetricStats.fromJson(json['temperature'] as Map<String, dynamic>)
          : null,
      humidity: json['humidity'] != null
          ? MetricStats.fromJson(json['humidity'] as Map<String, dynamic>)
          : null,
      voltage: json['voltage'] != null
          ? MetricStats.fromJson(json['voltage'] as Map<String, dynamic>)
          : null,
    );
  }

  final String deviceId;
  final TimeRangeInfo timeRange;
  final int readingCount;
  final DateTime? firstReading;
  final DateTime? lastReading;
  final MetricStats? temperature;
  final MetricStats? humidity;
  final MetricStats? voltage;

  @override
  List<Object?> get props => [
        deviceId,
        timeRange,
        readingCount,
        firstReading,
        lastReading,
        temperature,
        humidity,
        voltage,
      ];
}

/// Statistical metrics for a single metric type.
class MetricStats extends Equatable {
  const MetricStats({
    this.min,
    this.max,
    this.avg,
    required this.unit,
  });

  factory MetricStats.fromJson(Map<String, dynamic> json) {
    return MetricStats(
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      avg: (json['avg'] as num?)?.toDouble(),
      unit: json['unit'] as String,
    );
  }

  final double? min;
  final double? max;
  final double? avg;
  final String unit;

  @override
  List<Object?> get props => [min, max, avg, unit];
}

/// Time range information.
class TimeRangeInfo extends Equatable {
  const TimeRangeInfo({
    required this.start,
    required this.end,
  });

  factory TimeRangeInfo.fromJson(Map<String, dynamic> json) {
    return TimeRangeInfo(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);

  @override
  List<Object?> get props => [start, end];
}
