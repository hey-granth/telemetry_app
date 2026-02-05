import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalDevices;
  final int onlineDevices;
  final int offlineDevices;
  final int totalReadingsToday;
  final double avgTemperature;
  final double avgHumidity;
  final double avgVoltage;
  final DateTime lastUpdated;

  const DashboardStats({
    required this.totalDevices,
    required this.onlineDevices,
    required this.offlineDevices,
    required this.totalReadingsToday,
    required this.avgTemperature,
    required this.avgHumidity,
    required this.avgVoltage,
    required this.lastUpdated,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalDevices: json['total_devices'] as int,
      onlineDevices: json['online_devices'] as int,
      offlineDevices: json['offline_devices'] as int,
      totalReadingsToday: json['total_readings_today'] as int,
      avgTemperature: (json['avg_temperature'] as num).toDouble(),
      avgHumidity: (json['avg_humidity'] as num).toDouble(),
      avgVoltage: (json['avg_voltage'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_devices': totalDevices,
      'online_devices': onlineDevices,
      'offline_devices': offlineDevices,
      'total_readings_today': totalReadingsToday,
      'avg_temperature': avgTemperature,
      'avg_humidity': avgHumidity,
      'avg_voltage': avgVoltage,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  double get onlinePercentage =>
      totalDevices > 0 ? (onlineDevices / totalDevices) * 100 : 0;

  @override
  List<Object?> get props => [
        totalDevices,
        onlineDevices,
        offlineDevices,
        totalReadingsToday,
        avgTemperature,
        avgHumidity,
        avgVoltage,
        lastUpdated,
      ];
}

class SystemHealth extends Equatable {
  final bool databaseConnected;
  final bool websocketHealthy;
  final int activeConnections;
  final double cpuUsage;
  final double memoryUsage;
  final DateTime checkedAt;

  const SystemHealth({
    required this.databaseConnected,
    required this.websocketHealthy,
    required this.activeConnections,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.checkedAt,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> json) {
    return SystemHealth(
      databaseConnected: json['database_connected'] as bool,
      websocketHealthy: json['websocket_healthy'] as bool,
      activeConnections: json['active_connections'] as int,
      cpuUsage: (json['cpu_usage'] as num).toDouble(),
      memoryUsage: (json['memory_usage'] as num).toDouble(),
      checkedAt: DateTime.parse(json['checked_at'] as String),
    );
  }

  bool get isHealthy => databaseConnected && websocketHealthy;

  @override
  List<Object?> get props => [
        databaseConnected,
        websocketHealthy,
        activeConnections,
        cpuUsage,
        memoryUsage,
        checkedAt,
      ];
}
