/// Custom exception types for SkyWhisper sensor communication.
///
/// Provides a sealed hierarchy of typed exceptions that carry both
/// a developer-facing [debugInfo] string and a user-friendly
/// [userMessage] suitable for display in SnackBars or error banners.
library;

/// Base exception type for all sensor-related errors.
///
/// This is a sealed class so that `switch` statements over exception
/// types are exhaustive and the compiler can verify all cases are
/// handled.
sealed class SensorException implements Exception {
  /// Creates a [SensorException] with the given messages.
  const SensorException({
    required this.userMessage,
    this.debugInfo,
  });

  /// A short, non-technical message safe to display to the user.
  ///
  /// Example: "Unable to reach the weather station. Please check
  /// your WiFi connection."
  final String userMessage;

  /// Optional technical details for logging and debugging.
  ///
  /// Example: "SocketException: OS Error: Connection refused, errno = 111"
  final String? debugInfo;

  @override
  String toString() => '$runtimeType: $userMessage'
      '${debugInfo != null ? ' ($debugInfo)' : ''}';
}

/// Thrown when the app cannot establish a network connection to the
/// ESP32 access point (e.g. WiFi not connected, device powered off).
class SensorConnectionException extends SensorException {
  /// Creates a [SensorConnectionException].
  const SensorConnectionException({
    super.userMessage =
        'Unable to reach the weather station.\nPlease check your WiFi connection.',
    super.debugInfo,
  });
}

/// Thrown when an HTTP request or WebSocket handshake exceeds the
/// configured timeout duration.
class SensorTimeoutException extends SensorException {
  /// Creates a [SensorTimeoutException].
  const SensorTimeoutException({
    super.userMessage =
        'The weather station is taking too long to respond.\nPlease try again.',
    super.debugInfo,
  });
}

/// Thrown when the received JSON payload cannot be parsed into a
/// valid [SensorReading] (e.g. missing keys, wrong types).
class SensorParseException extends SensorException {
  /// Creates a [SensorParseException].
  const SensorParseException({
    super.userMessage =
        'Received unexpected data from the station.\nThe firmware may need updating.',
    super.debugInfo,
  });
}

/// Thrown when the WebSocket connection drops unexpectedly.
class SensorDisconnectException extends SensorException {
  /// Creates a [SensorDisconnectException].
  const SensorDisconnectException({
    super.userMessage =
        'Lost connection to the weather station.\nReconnecting automatically…',
    super.debugInfo,
  });
}
