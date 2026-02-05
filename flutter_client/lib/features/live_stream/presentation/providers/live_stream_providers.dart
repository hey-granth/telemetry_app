import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/websocket_client.dart';
import '../../../devices/domain/models/device.dart';
import '../../../devices/presentation/providers/device_providers.dart';

/// WebSocket client provider
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient(
    onMessage: (message) {
      // Handle incoming messages
      if (message.type == WsMessageType.reading && message.data != null) {
        final reading = Reading.fromJson(message.data!);
        final deviceId = message.deviceId ?? reading.deviceId;

        // Update devices list
        ref
            .read(devicesProvider.notifier)
            .updateLatestReading(deviceId, reading);

        // Update device detail if viewing
        ref.read(deviceDetailProvider(deviceId).notifier).addReading(reading);

        // Notify live stream listeners
        ref.read(liveReadingsProvider.notifier).addReading(reading);
      }
    },
    onConnectionStateChange: (state) {
      ref.read(wsConnectionStateProvider.notifier).state = state;
    },
  );

  ref.onDispose(() => client.dispose());

  return client;
});

/// WebSocket connection state provider
final wsConnectionStateProvider = StateProvider<WsConnectionState>((ref) {
  return WsConnectionState.disconnected;
});

/// Live readings stream
class LiveReadingsNotifier extends StateNotifier<List<Reading>> {
  LiveReadingsNotifier() : super([]);

  static const int _maxReadings = 100;

  void addReading(Reading reading) {
    state = [reading, ...state.take(_maxReadings - 1)];
  }

  void clear() {
    state = [];
  }
}

final liveReadingsProvider =
    StateNotifierProvider<LiveReadingsNotifier, List<Reading>>((ref) {
  return LiveReadingsNotifier();
});

/// Active subscriptions provider
final activeSubscriptionsProvider = StateProvider<Set<String>>((ref) {
  return {};
});

/// Live stream controller for managing WebSocket subscriptions
class LiveStreamController {
  LiveStreamController(this._ref);

  final Ref _ref;

  WebSocketClient get _client => _ref.read(webSocketClientProvider);

  /// Connect to a specific device stream
  Future<void> connectToDevice(String deviceId) async {
    await _client.connectToDevice(deviceId);
    _ref.read(activeSubscriptionsProvider.notifier).update((state) {
      return {...state, deviceId};
    });
  }

  /// Connect to all devices stream
  Future<void> connectToAll() async {
    await _client.connectToAllDevices();
    _ref.read(activeSubscriptionsProvider.notifier).update((state) {
      return {...state, '__all__'};
    });
  }

  /// Subscribe to additional device (on existing connection)
  void subscribeToDevice(String deviceId) {
    _client.subscribeToDevice(deviceId);
    _ref.read(activeSubscriptionsProvider.notifier).update((state) {
      return {...state, deviceId};
    });
  }

  /// Unsubscribe from device
  void unsubscribeFromDevice(String deviceId) {
    _client.unsubscribeFromDevice(deviceId);
    _ref.read(activeSubscriptionsProvider.notifier).update((state) {
      final newState = {...state};
      newState.remove(deviceId);
      return newState;
    });
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    await _client.disconnect();
    _ref.read(activeSubscriptionsProvider.notifier).state = {};
    _ref.read(liveReadingsProvider.notifier).clear();
  }

  /// Check if connected
  bool get isConnected =>
      _ref.read(wsConnectionStateProvider) == WsConnectionState.connected;
}

/// Live stream controller provider
final liveStreamControllerProvider = Provider<LiveStreamController>((ref) {
  return LiveStreamController(ref);
});
