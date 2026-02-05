import 'dart:async';
import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';

/// WebSocket message types
enum WsMessageType {
  reading,
  ack,
  pong,
  error,
  unknown,
}

/// Parsed WebSocket message
class WsMessage {
  const WsMessage({
    required this.type,
    this.deviceId,
    this.data,
    this.message,
    this.error,
    this.code,
  });

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'unknown';
    final type = switch (typeStr) {
      'reading' => WsMessageType.reading,
      'ack' => WsMessageType.ack,
      'pong' => WsMessageType.pong,
      'error' => WsMessageType.error,
      _ => WsMessageType.unknown,
    };

    return WsMessage(
      type: type,
      deviceId: json['device_id'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      message: json['message'] as String?,
      error: json['error'] as String?,
      code: json['code'] as String?,
    );
  }

  final WsMessageType type;
  final String? deviceId;
  final Map<String, dynamic>? data;
  final String? message;
  final String? error;
  final String? code;
}

/// WebSocket connection state
enum WsConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// WebSocket client for real-time data streaming.
///
/// Handles connection lifecycle, automatic reconnection,
/// and message parsing.
class WebSocketClient {
  WebSocketClient({
    String? baseUrl,
    this.onMessage,
    this.onConnectionStateChange,
  }) : _baseUrl = baseUrl ?? AppConfig.wsBaseUrl;

  final String _baseUrl;
  final void Function(WsMessage message)? onMessage;
  final void Function(WsConnectionState state)? onConnectionStateChange;

  final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  WsConnectionState _state = WsConnectionState.disconnected;
  WsConnectionState get state => _state;

  String? _currentPath;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  /// Connect to a device stream
  Future<void> connectToDevice(String deviceId) async {
    await connect('/stream/devices/$deviceId');
  }

  /// Connect to all devices stream
  Future<void> connectToAllDevices() async {
    await connect('/stream/all');
  }

  /// Connect to WebSocket endpoint
  Future<void> connect(String path) async {
    if (_state == WsConnectionState.connected && _currentPath == path) {
      return;
    }

    await disconnect();
    _currentPath = path;
    _reconnectAttempts = 0;

    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_currentPath == null) return;

    _setState(WsConnectionState.connecting);

    try {
      final uri = Uri.parse('$_baseUrl$_currentPath');
      _logger.d('WebSocket connecting to: $uri');

      _channel = WebSocketChannel.connect(uri);

      // Wait for connection
      await _channel!.ready;

      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;
      _logger.i('WebSocket connected');

      // Start listening to messages
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Start ping timer to keep connection alive
      _startPingTimer();
    } catch (e) {
      _logger.e('WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final wsMessage = WsMessage.fromJson(json);

      _logger.d('WebSocket message: ${wsMessage.type}');

      if (wsMessage.type == WsMessageType.error) {
        _logger.w('WebSocket error: ${wsMessage.error}');
      }

      onMessage?.call(wsMessage);
    } catch (e) {
      _logger.e('Failed to parse WebSocket message: $e');
    }
  }

  void _onError(Object error) {
    _logger.e('WebSocket error: $error');
    _scheduleReconnect();
  }

  void _onDone() {
    _logger.i('WebSocket connection closed');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_currentPath == null) return;

    _stopPingTimer();
    _subscription?.cancel();
    _channel = null;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Max reconnect attempts reached');
      _setState(WsConnectionState.disconnected);
      return;
    }

    _setState(WsConnectionState.reconnecting);
    _reconnectAttempts++;

    // Exponential backoff
    final delay = Duration(
      seconds: AppConfig.wsReconnectDelaySeconds * _reconnectAttempts,
    );

    _logger
        .d('Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _doConnect);
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => sendPing(),
    );
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Send ping to keep connection alive
  void sendPing() {
    if (_state != WsConnectionState.connected) return;

    try {
      _channel?.sink.add(jsonEncode({'action': 'ping'}));
    } catch (e) {
      _logger.e('Failed to send ping: $e');
    }
  }

  /// Subscribe to additional device
  void subscribeToDevice(String deviceId) {
    if (_state != WsConnectionState.connected) return;

    try {
      _channel?.sink.add(jsonEncode({
        'action': 'subscribe',
        'device_id': deviceId,
      }));
    } catch (e) {
      _logger.e('Failed to subscribe: $e');
    }
  }

  /// Unsubscribe from device
  void unsubscribeFromDevice(String deviceId) {
    if (_state != WsConnectionState.connected) return;

    try {
      _channel?.sink.add(jsonEncode({
        'action': 'unsubscribe',
        'device_id': deviceId,
      }));
    } catch (e) {
      _logger.e('Failed to unsubscribe: $e');
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _currentPath = null;
    _reconnectTimer?.cancel();
    _stopPingTimer();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(WsConnectionState.disconnected);
    _logger.i('WebSocket disconnected');
  }

  void _setState(WsConnectionState state) {
    if (_state != state) {
      _state = state;
      onConnectionStateChange?.call(state);
    }
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
  }
}
