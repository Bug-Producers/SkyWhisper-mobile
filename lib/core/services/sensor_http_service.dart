/// HTTP service for fetching sensor data from the ESP32 station.
///
/// Communicates with the ESP32's `GET /test` endpoint to retrieve
/// the latest 5-second averaged readings from the AHT20 and BMP280
/// sensors. Includes robust error handling that converts low-level
/// network exceptions into user-friendly [SensorException] types.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/models/sensor_reading.dart';
import 'sensor_exception.dart';

/// Provides HTTP-based access to the ESP32 weather station.
///
/// Use this service as a fallback or initial data fetch when the
/// WebSocket connection is not yet established. The ESP32 runs in
/// Access Point mode at a fixed IP address.
///
/// ```dart
/// final service = SensorHttpService();
/// final reading = await service.fetchCurrentReading();
/// print(reading.temperature); // e.g. 26.45
/// ```
class SensorHttpService {
  /// Creates a [SensorHttpService] with an optional custom [baseUrl].
  ///
  /// Defaults to the ESP32's AP mode address `http://192.168.4.1`.
  SensorHttpService({
    this.baseUrl = 'http://192.168.4.1',
    this.timeout = const Duration(seconds: 5),
  });

  /// The base URL of the ESP32 HTTP server.
  final String baseUrl;

  /// Maximum duration to wait for a response before timing out.
  final Duration timeout;

  /// The underlying HTTP client. Exposed for testing/mocking.
  final http.Client _client = http.Client();

  /// Fetches the latest averaged sensor reading via `GET /test`.
  ///
  /// Returns a [SensorReading] parsed from the JSON response:
  /// ```json
  /// { "temp": 26.45, "hum": 42.10, "pres": 1012.35 }
  /// ```
  ///
  /// Throws:
  /// - [SensorConnectionException] if the device is unreachable.
  /// - [SensorTimeoutException] if the request exceeds [timeout].
  /// - [SensorParseException] if the response body is malformed.
  Future<SensorReading> fetchCurrentReading() async {
    try {
      final uri = Uri.parse('$baseUrl/test');
      final response = await _client.get(uri).timeout(timeout);

      if (response.statusCode != 200) {
        throw SensorConnectionException(
          debugInfo: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SensorReading.fromHttpJson(json);
    } on SocketException catch (e) {
      throw SensorConnectionException(debugInfo: e.toString());
    } on TimeoutException catch (e) {
      throw SensorTimeoutException(debugInfo: e.toString());
    } on FormatException catch (e) {
      throw SensorParseException(debugInfo: e.toString());
    } on SensorException {
      rethrow;
    } catch (e) {
      throw SensorConnectionException(
        userMessage: 'An unexpected error occurred while fetching data.',
        debugInfo: e.toString(),
      );
    }
  }

  /// Disposes the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
