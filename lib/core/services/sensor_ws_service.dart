/// WebSocket service for real-time sensor data streaming.
///
/// Connects to the ESP32's WebSocket endpoint at `ws://192.168.4.1/ws`
/// and provides a broadcast [Stream] of [SensorReading] objects parsed
/// from incoming JSON messages. Includes auto-reconnect logic with
/// exponential backoff.
library;

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/models/sensor_reading.dart';
import 'sensor_exception.dart';

// ───────────────────── Connection Status ─────────────────────

/// Represents the current state of the WebSocket connection.
enum ConnectionStatus {
  /// Not connected and not attempting to connect.
  disconnected,

  /// Actively attempting to establish a connection.
  connecting,

  /// Connection is open and receiving data.
  connected,

  /// Connection failed or was lost unexpectedly.
  error,
}

// ───────────────────── WebSocket Service ─────────────────────

/// Manages the WebSocket connection to the ESP32 weather station.
///
/// The ESP32 broadcasts JSON messages every 5 seconds:
/// ```json
/// { "t": 26.45, "h": 42.10, "p": 1012.35 }
/// ```
///
/// Usage:
/// ```dart
/// final service = SensorWsService();
/// service.readingStream.listen((reading) => print(reading));
/// await service.connect();
/// ```
class SensorWsService {
  /// Creates a [SensorWsService] with an optional custom [wsUrl].
  SensorWsService({
    this.wsUrl = 'ws://192.168.4.1/ws',
    this.maxReconnectDelay = const Duration(seconds: 30),
  });

  /// The WebSocket URL of the ESP32 station.
  final String wsUrl;

  /// Maximum delay between reconnection attempts.
  final Duration maxReconnectDelay;

  /// The underlying WebSocket channel (null when disconnected).
  WebSocketChannel? _channel;

  /// Subscription to the channel's stream.
  StreamSubscription? _subscription;

  /// Broadcast controller for parsed sensor readings.
  final _readingController = StreamController<SensorReading>.broadcast();

  /// Broadcast controller for connection status changes.
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  /// Current reconnection attempt count (for exponential backoff).
  int _reconnectAttempt = 0;

  /// Timer for scheduled reconnection attempts.
  Timer? _reconnectTimer;

  /// Whether the service has been intentionally disposed.
  bool _disposed = false;

  /// Current connection status.
  ConnectionStatus _status = ConnectionStatus.disconnected;

  // ───────────────────── Public Streams ─────────────────────

  /// Stream of parsed [SensorReading] objects from the WebSocket.
  ///
  /// This is a broadcast stream — multiple listeners are supported.
  /// Readings are emitted every ~5 seconds while connected.
  Stream<SensorReading> get readingStream => _readingController.stream;

  /// Stream of [ConnectionStatus] changes.
  ///
  /// Emits whenever the connection state transitions (e.g. from
  /// `connecting` to `connected`, or `connected` to `error`).
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// The current connection status (synchronous getter).
  ConnectionStatus get status => _status;

  // ───────────────────── Connection Lifecycle ─────────────────────

  /// Opens the WebSocket connection to the ESP32.
  ///
  /// If already connected, this method is a no-op. On failure,
  /// the service automatically schedules a reconnection attempt
  /// with exponential backoff.
  Future<void> connect() async {
    if (_disposed) return;
    if (_status == ConnectionStatus.connected) return;

    _updateStatus(ConnectionStatus.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      /// Listen to incoming messages IMMEDIATELY. MUST be done before awaiting ready
      /// to avoid dropping messages or hanging the handshake on mobile platforms.
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      /// Wait for the connection to be established.
      await _channel!.ready;

      _reconnectAttempt = 0;
      _updateStatus(ConnectionStatus.connected);
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }

  /// Gracefully closes the WebSocket connection.
  ///
  /// Does **not** trigger auto-reconnect. Use this when the user
  /// intentionally navigates away or the app goes to background.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;

    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Permanently disposes all resources.
  ///
  /// After calling this, the service cannot be reused. Create a
  /// new instance if reconnection is needed.
  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _readingController.close();
    await _statusController.close();
  }

  // ───────────────────── Private Handlers ─────────────────────

  /// Handles an incoming WebSocket message.
  ///
  /// Parses the JSON string into a [SensorReading] and pushes it
  /// to the [readingStream]. Malformed messages are silently
  /// discarded with a debug log to avoid crashing the stream.
  void _onMessage(dynamic message) {
    try {
      final String payload;
      if (message is List<int>) {
        payload = utf8.decode(message);
      } else {
        payload = message.toString();
      }
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final reading = SensorReading.fromWsJson(json);
      _readingController.add(reading);
    } catch (e) {
      /// Don't crash the stream on a single bad message.
      _readingController.addError(
        SensorParseException(debugInfo: 'Bad WS message: $message'),
      );
    }
  }

  /// Handles a WebSocket stream error.
  void _onError(Object error) {
    _updateStatus(ConnectionStatus.error);
    _readingController.addError(
      SensorDisconnectException(debugInfo: error.toString()),
    );
    _scheduleReconnect();
  }

  /// Handles the WebSocket stream closing (server-side or network).
  void _onDone() {
    if (_disposed) return;
    _updateStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  // ───────────────────── Reconnection Logic ─────────────────────

  /// Schedules a reconnection attempt with exponential backoff.
  ///
  /// Delay sequence: 2s → 4s → 8s → 16s → 30s (capped).
  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    final delay = Duration(
      seconds: (2 * (1 << _reconnectAttempt))
          .clamp(2, maxReconnectDelay.inSeconds),
    );

    _reconnectAttempt++;

    _reconnectTimer = Timer(delay, () {
      if (!_disposed) connect();
    });
  }

  /// Updates the status and notifies listeners.
  void _updateStatus(ConnectionStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }
}
