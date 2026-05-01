/// Immutable data model representing a single sensor snapshot.
///
/// Encapsulates temperature, humidity, and pressure readings from the
/// AHT20 + BMP280 sensor pair on the ESP32 weather station. Provides
/// factory constructors for parsing both HTTP and WebSocket JSON
/// formats, as well as SQLite row serialization.
library;

/// A single point-in-time sensor measurement.
///
/// The ESP32 broadcasts 5-second averaged data. Each [SensorReading]
/// captures one such broadcast along with the [timestamp] at which
/// the app received (or generated) it.
///
/// Two JSON key formats are supported:
/// - **HTTP** (`GET /test`): `{ "temp", "hum", "pres" }`
/// - **WebSocket** (`/ws`):  `{ "t", "h", "p" }`
class SensorReading {
  /// Creates a [SensorReading] with all required fields.
  const SensorReading({
    this.id,
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.timestamp,
  });

  /// Auto-incremented primary key from SQLite. Null for unsaved readings.
  final int? id;

  /// Averaged temperature in degrees Celsius (°C).
  ///
  /// Derived from the AHT20 and BMP280 sensor fusion on the ESP32.
  final double temperature;

  /// Relative humidity percentage (%) from the AHT20 sensor.
  final double humidity;

  /// Barometric pressure in hectopascals (hPa) from the BMP280 sensor.
  final double pressure;

  /// UTC timestamp of when this reading was captured.
  final DateTime timestamp;

  // ───────────────────── JSON Factories ─────────────────────

  /// Parses a [SensorReading] from the **HTTP** JSON response.
  ///
  /// Expected keys: `temp`, `hum`, `pres`.
  /// Throws [FormatException] if required keys are missing.
  ///
  /// ```json
  /// { "temp": 26.45, "hum": 42.10, "pres": 1012.35 }
  /// ```
  factory SensorReading.fromHttpJson(Map<String, dynamic> json) {
    return SensorReading(
      temperature: (json['temp'] as num).toDouble(),
      humidity: (json['hum'] as num).toDouble(),
      pressure: (json['pres'] as num).toDouble(),
      timestamp: DateTime.now(),
    );
  }

  /// Parses a [SensorReading] from a **WebSocket** JSON message.
  ///
  /// Expected keys: `t`, `h`, `p`.
  ///
  /// ```json
  /// { "t": 26.45, "h": 42.10, "p": 1012.35 }
  /// ```
  factory SensorReading.fromWsJson(Map<String, dynamic> json) {
    return SensorReading(
      temperature: (json['t'] as num).toDouble(),
      humidity: (json['h'] as num).toDouble(),
      pressure: (json['p'] as num).toDouble(),
      timestamp: DateTime.now(),
    );
  }

  // ───────────────────── SQLite Serialization ─────────────────────

  /// Converts this reading to a [Map] suitable for SQLite insertion.
  ///
  /// The [timestamp] is stored as an ISO-8601 string for portability.
  /// The [id] field is omitted so SQLite auto-generates it.
  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'pressure': pressure,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Reconstructs a [SensorReading] from a SQLite row [Map].
  ///
  /// Expects columns: `id`, `temperature`, `humidity`, `pressure`,
  /// and `timestamp` (ISO-8601 string).
  factory SensorReading.fromMap(Map<String, dynamic> map) {
    return SensorReading(
      id: map['id'] as int?,
      temperature: (map['temperature'] as num).toDouble(),
      humidity: (map['humidity'] as num).toDouble(),
      pressure: (map['pressure'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  // ───────────────────── Utilities ─────────────────────

  /// Returns a human-readable summary for debugging purposes.
  @override
  String toString() =>
      'SensorReading(temp: ${temperature.toStringAsFixed(1)}°C, '
      'hum: ${humidity.toStringAsFixed(1)}%, '
      'pres: ${pressure.toStringAsFixed(1)} hPa, '
      'time: $timestamp)';

  /// Creates a copy of this reading with optional field overrides.
  SensorReading copyWith({
    int? id,
    double? temperature,
    double? humidity,
    double? pressure,
    DateTime? timestamp,
  }) {
    return SensorReading(
      id: id ?? this.id,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
