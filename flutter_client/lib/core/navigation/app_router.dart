/// Navigation routes for the application.
///
/// Centralized route definitions for consistent navigation.
import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/pages/device_dashboard_page.dart';
import '../../features/devices/presentation/pages/device_detail_page.dart';
import '../../features/devices/presentation/pages/devices_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/provisioning/presentation/pages/provisioning_page.dart';
import '../../features/provisioning/presentation/pages/wifi_credentials_page.dart';

/// Named routes
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String devices = '/devices';
  static const String deviceDetail = '/devices/detail';
  static const String onboarding = '/onboarding';
  static const String wifiCredentials = '/provisioning/wifi';
  static const String provisioning = '/provisioning';
  static const String dashboard = '/dashboard';
}

/// Route generator for named navigation
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
      case AppRoutes.devices:
        return _fadeRoute(const DevicesPage(), settings);

      case AppRoutes.deviceDetail:
        final deviceId = settings.arguments as String;
        return _slideRoute(
          DeviceDetailPage(deviceId: deviceId),
          settings,
        );

      case AppRoutes.onboarding:
        return _slideRoute(const OnboardingPage(), settings);

      case AppRoutes.wifiCredentials:
        final args = settings.arguments as WifiCredentialsArgs;
        return _slideRoute(
          WifiCredentialsPage(
            deviceId: args.deviceId,
            deviceName: args.deviceName,
          ),
          settings,
        );

      case AppRoutes.provisioning:
        final args = settings.arguments as ProvisioningArgs;
        return _slideRoute(
          ProvisioningPage(
            deviceId: args.deviceId,
            ssid: args.ssid,
            password: args.password,
          ),
          settings,
        );

      case AppRoutes.dashboard:
        final deviceId = settings.arguments as String;
        return _slideRoute(
          DeviceDashboardPage(deviceId: deviceId),
          settings,
        );

      default:
        return _fadeRoute(
          const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
          settings,
        );
    }
  }

  static Route<T> _fadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  static Route<T> _slideRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

/// Arguments for WiFi credentials page
class WifiCredentialsArgs {
  const WifiCredentialsArgs({
    required this.deviceId,
    required this.deviceName,
  });

  final String deviceId;
  final String deviceName;
}

/// Arguments for provisioning page
class ProvisioningArgs {
  const ProvisioningArgs({
    required this.deviceId,
    required this.ssid,
    required this.password,
  });

  final String deviceId;
  final String ssid;
  final String password;
}
