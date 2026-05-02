/**
 * The State Management Layer of SkyWhisper.
 * 
 * <p>This file defines the Riverpod providers that bridge our hardware 
 * services (HTTP + WebSocket) and local database with the reactive UI.
 * It manages the lifecycle of connections and data fetching.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/daily_average.dart';
import '../data/models/sensor_reading.dart';
import '../data/models/weather_event.dart';
import '../services/sensor_http_service.dart';
import '../services/sensor_ws_service.dart';
import '../services/weather_analysis_service.dart';
import 'database_provider.dart';

// ───────────────────── Service Singletons ─────────────────────

/**
 * Manages the singleton instance of the [SensorHttpService].
 * 
 * <p>The HTTP service is used for initial data synchronization and as a 
 * fallback if real-time streaming is unavailable.
 */
final httpServiceProvider = Provider<SensorHttpService>((ref) {
  final service = SensorHttpService();
  ref.onDispose(() => service.dispose());
  return service;
});

/**
 * Manages the singleton instance of the [SensorWsService].
 * 
 * <p>The WebSocket service handles the low-latency stream of readings 
 * coming directly from the hardware sensors.
 */
final wsServiceProvider = Provider<SensorWsService>((ref) {
  final service = SensorWsService();
  ref.onDispose(() => service.dispose());
  return service;
});

// ───────────────────── Live Data Streams ─────────────────────

/**
 * The primary stream of live sensor readings.
 * 
 * <p>This provider initiates a WebSocket connection as soon as it is 
 * watched by any part of the UI. It emits a new [SensorReading] 
 * roughly every 5 seconds.
 */
final sensorStreamProvider = StreamProvider<SensorReading>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  wsService.connect();
  return wsService.readingStream;
});

/**
 * Exposes the current connectivity state of the hardware link.
 * 
 * <p>Emits [ConnectionStatus] values (connected, connecting, disconnected, 
 * or error) which are used to update the status indicators on the dashboard.
 */
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final wsService = ref.watch(wsServiceProvider);
  return wsService.statusStream;
});

/**
 * Performs a one-off fetch of the latest sensor reading via HTTP.
 * 
 * @return A [Future] containing the latest [SensorReading].
 */
final currentReadingProvider = FutureProvider<SensorReading>((ref) async {
  final httpService = ref.read(httpServiceProvider);
  return httpService.fetchCurrentReading();
});

// ───────────────────── Historical Insights ─────────────────────

/**
 * Aggregates historical data into daily averages for visualization.
 * 
 * <p>Watches the [databaseInitProvider] to ensure the SQLite store is 
 * ready before attempting to query averages for the last 30 days.
 * 
 * @return A list of [DailyAverage] objects, sorted by date.
 */
final dailyAveragesProvider = FutureProvider<List<DailyAverage>>((ref) async {
  await ref.watch(databaseInitProvider.future);

  final dbHelper = ref.read(databaseProvider);
  return dbHelper.getDailyAverages(
    from: DateTime(2026, 4, 1),
    to: DateTime(2026, 5, 2),
  );
});

/**
 * Calculates the running average of sensor readings for the current day.
 * 
 * <p>This provider reactively updates whenever a new reading is 
 * emitted by the [sensorStreamProvider].
 */
final todayAverageProvider = FutureProvider<DailyAverage?>((ref) async {
  ref.watch(sensorStreamProvider);

  final dbHelper = ref.read(databaseProvider);
  return dbHelper.getTodayAverage();
});

/**
 * Fallback provider that retrieves the most recent reading saved in the database.
 * 
 * <p>This is crucial for "Offline Mode," ensuring the UI shows cached 
 * data instead of empty fields when the network is down.
 */
final latestCachedReadingProvider = FutureProvider<SensorReading?>((ref) async {
  await ref.watch(databaseInitProvider.future);

  final dbHelper = ref.read(databaseProvider);
  return dbHelper.getLatestReading();
});

// ───────────────────── Weather Intelligence ─────────────────────

/**
 * Runs the [WeatherAnalysisService] on the latest 30 days of stored data.
 * 
 * <p>This provider encapsulates the "AI" logic of the app, transforming 
 * thousands of raw database rows into a prioritized list of climatic 
 * insights and events.
 * 
 * @return A list of [WeatherEvent]s detected in the recent history.
 */
final weatherAnalysisProvider = FutureProvider<List<WeatherEvent>>((ref) async {
  await ref.watch(databaseInitProvider.future);
  
  final dbHelper = ref.read(databaseProvider);
  
  final now = DateTime.now();
  final startDate = now.subtract(const Duration(days: 32));
  final readings = await dbHelper.getReadingsInRange(startDate, now);
  
  final analysisService = WeatherAnalysisService();
  return analysisService.analyze(readings);
});
