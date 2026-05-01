/// Riverpod provider for the background reading scheduler.
///
/// Manages the [ReadingScheduler] lifecycle, binding it to the
/// WebSocket stream so that one reading is automatically persisted
/// every 4 hours without any user interaction.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/reading_scheduler.dart';
import 'database_provider.dart';
import 'sensor_providers.dart';

/// Provides and manages the [ReadingScheduler] instance.
///
/// When this provider is first read, it creates a scheduler bound
/// to the database and starts listening to the WebSocket stream.
/// The scheduler is disposed when the provider scope is destroyed.
///
/// To activate the scheduler, simply read or watch this provider
/// in the app's root widget:
/// ```dart
/// ref.read(readingSchedulerProvider);
/// ```
final readingSchedulerProvider = Provider<ReadingScheduler>((ref) {
  final dbHelper = ref.watch(databaseProvider);
  final scheduler = ReadingScheduler(dbHelper);

  /// Get the WebSocket service's reading stream.
  final wsService = ref.watch(wsServiceProvider);
  scheduler.startListening(wsService.readingStream);

  /// Clean up when the provider is disposed.
  ref.onDispose(() => scheduler.dispose());

  return scheduler;
});
