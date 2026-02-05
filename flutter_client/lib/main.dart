/// Telemetry Client Application
///
/// Flutter client for IoT telemetry data platform.
/// Consumes REST and WebSocket APIs from the backend.
library telemetry_client;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/devices/presentation/pages/devices_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: TelemetryApp(),
    ),
  );
}

/// Root application widget.
class TelemetryApp extends StatelessWidget {
  const TelemetryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const DevicesPage(),
    );
  }
}
