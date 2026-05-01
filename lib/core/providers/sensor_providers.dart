/// Riverpod providers for live sensor data and historical averages.
///
/// This file contains the core state management layer that bridges
/// the ESP32 hardware services (HTTP + WebSocket) with the Flutter
/// UI. Providers expose reactive streams for real-time readings,
/// connection status, and aggregated historical data from SQLite.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/daily_average.dart';
import '../data/models/sensor_reading.dart';
import '../services/sensor_http_service.dart';
import '../services/sensor_ws_service.dart';
import 'database_provider.dart';

// ───────────────────── Service Providers ─────────────────────

/// Provides the [SensorHttpService] singleton.
///
/// Used as a fallback data source when the WebSocket is not yet
/// connected, or for one-off data fetches.
final httpServiceProvider = Provider<SensorHttpService>((ref) {
  final service = SensorHttpService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provides the [SensorWsService] singleton.
///
/// Manages the WebSocket lifecycle including connection, streaming,
/// and auto-reconnect. Disposed when the provider is no longer watched.
final wsServiceProvider = Provider<SensorWsService>((ref) {
  final service = SensorWsService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ───────────────────── Live Data Providers ─────────────────────

/// Streams live sensor readings from the WebSocket connection.
///
/// Automatically connects to the ESP32 when first watched and
/// disposes the connection when all listeners are removed.
///
/// Usage in a widget:
/// ```dart
/// final asyncReading = ref.watch(sensorStreamProvider);
/// asyncReading.when(
///   data: (reading) => Text('${reading.temperature}°C'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// ```
final sensorStreamProvider = StreamProvider<SensorReading>((ref) {
  final wsService = ref.watch(wsServiceProvider);

  /// Initiate the WebSocket connection.
  wsService.connect();

  /// Return the broadcast stream of parsed readings.
  return wsService.readingStream;
});

/// Provides the current [ConnectionStatus] of the WebSocket.
///
/// Widgets can use this to show connection indicators:
/// - 🟢 `connected` — live data flowing.
/// - 🟡 `connecting` — attempting to connect.
/// - 🔴 `disconnected` / `error` — no data; show retry option.
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  return wsService.statusStream;
});

/// Fetches the latest sensor reading via HTTP as a one-shot request.
///
/// Useful for initial data display before the WebSocket connects,
/// or as a manual refresh mechanism.
///
/// Throws [SensorException] subtypes on failure, which the UI
/// should handle with user-friendly error messages.
final currentReadingProvider = FutureProvider<SensorReading>((ref) async {
  final httpService = ref.read(httpServiceProvider);
  return httpService.fetchCurrentReading();
});

// ───────────────────── Historical Data Providers ─────────────────────

/// Provides daily averaged readings from April 1 to today.
///
/// Queries the SQLite database for all days that have stored
/// readings and computes the mean temperature, humidity, and
/// pressure for each day. Results are sorted chronologically.
///
/// This provider is used by the [ClimateChartCard] to render
/// the historical trend line chart.
final dailyAveragesProvider = FutureProvider<List<DailyAverage>>((ref) async {
  /// Wait for the database to be initialized and seeded.
  await ref.watch(databaseInitProvider.future);

  final dbHelper = ref.read(databaseProvider);
  return dbHelper.getDailyAverages(
    from: DateTime(2026, 4, 1),
    to: DateTime(2026, 5, 2),
  );
});

/// Provides today's running average (if any readings exist).
///
/// Updated each time a new reading is saved to the database.
/// Returns `null` if no readings have been recorded today.
final todayAverageProvider = FutureProvider<DailyAverage?>((ref) async {
  /// Re-evaluate when the live stream emits new data.
  ref.watch(sensorStreamProvider);

  final dbHelper = ref.read(databaseProvider);
  return dbHelper.getTodayAverage();
});

/// Provides the latest reading from the database as a fallback.
///
/// Used when the device is offline to show the most recent
/// cached data instead of an empty state.
final latestCachedReadingProvider = FutureProvider<SensorReading?>((ref) async {
  await ref.watch(databaseInitProvider.future);

  final dbHelper = ref.read(databaseProvider);
  return dbHelper.getLatestReading();
});
