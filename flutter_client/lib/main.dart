/// Telemetry Client Application
///
/// Flutter client for IoT telemetry data platform.
/// Consumes REST and WebSocket APIs from the backend.
library telemetry_client;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/navigation/app_router.dart';
import 'core/state/app_lifecycle.dart';
import 'core/state/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/presentation/pages/landing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: TelemetryApp(),
    ),
  );
}

/// Root application widget.
class TelemetryApp extends ConsumerStatefulWidget {
  const TelemetryApp({super.key});

  @override
  ConsumerState<TelemetryApp> createState() => _TelemetryAppState();
}

class _TelemetryAppState extends ConsumerState<TelemetryApp> {
  @override
  void initState() {
    super.initState();
    // Transition from booting to landing after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLifecycleProvider.notifier).showLanding();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const LandingScreen(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
