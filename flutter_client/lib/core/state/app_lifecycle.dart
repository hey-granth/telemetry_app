/// Application lifecycle state management.
///
/// Manages the app's boot sequence and backend connectivity state.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application lifecycle states
enum AppLifecycleState {
  /// App is initializing
  booting,

  /// Showing landing screen, backend status being checked
  landing,

  /// Backend is reachable, app is ready
  ready,

  /// Backend is unreachable, but app is usable in degraded mode
  degraded,
}

/// Backend connectivity state
class BackendStatus {
  const BackendStatus({
    required this.isReachable,
    this.lastChecked,
    this.errorMessage,
  });

  final bool isReachable;
  final DateTime? lastChecked;
  final String? errorMessage;

  BackendStatus copyWith({
    bool? isReachable,
    DateTime? lastChecked,
    String? errorMessage,
  }) {
    return BackendStatus(
      isReachable: isReachable ?? this.isReachable,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage,
    );
  }
}

/// App lifecycle state notifier
class AppLifecycleNotifier extends StateNotifier<AppLifecycleState> {
  AppLifecycleNotifier() : super(AppLifecycleState.booting);

  void showLanding() {
    state = AppLifecycleState.landing;
  }

  void markReady() {
    state = AppLifecycleState.ready;
  }

  void markDegraded() {
    state = AppLifecycleState.degraded;
  }
}

/// Backend status notifier
class BackendStatusNotifier extends StateNotifier<BackendStatus> {
  BackendStatusNotifier() : super(const BackendStatus(isReachable: false));

  void markReachable() {
    state = BackendStatus(
      isReachable: true,
      lastChecked: DateTime.now(),
    );
  }

  void markUnreachable(String? error) {
    state = BackendStatus(
      isReachable: false,
      lastChecked: DateTime.now(),
      errorMessage: error,
    );
  }

  void reset() {
    state = const BackendStatus(isReachable: false);
  }
}

/// App lifecycle provider
final appLifecycleProvider =
    StateNotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
  (ref) => AppLifecycleNotifier(),
);

/// Backend status provider
final backendStatusProvider =
    StateNotifierProvider<BackendStatusNotifier, BackendStatus>(
  (ref) => BackendStatusNotifier(),
);

