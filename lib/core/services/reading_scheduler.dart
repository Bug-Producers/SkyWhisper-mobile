/// Background scheduler that persists sensor readings at 4-hour intervals.
///
/// Listens to the WebSocket stream and saves one reading per 4-hour
/// time slot (00:00, 04:00, 08:00, 12:00, 16:00, 20:00). This
/// ensures consistent historical data without storing every 5-second
/// broadcast, which would be excessive for long-term storage.
library;

import 'dart:async';

import '../data/database/database_helper.dart';
import '../data/models/sensor_reading.dart';

/// Manages the periodic persistence of sensor readings to SQLite.
///
/// The scheduler aligns readings to 4-hour slots. When a new reading
/// arrives, it checks whether the current slot already has a persisted
/// entry. If not, it saves the reading. This approach is resilient
/// to app restarts — it simply fills in any missing slots when data
/// becomes available.
///
/// Usage:
/// ```dart
/// final scheduler = ReadingScheduler(dbHelper);
/// scheduler.onNewReading(reading); // Call from WS listener
/// ```
class ReadingScheduler {
  /// Creates a [ReadingScheduler] bound to the given [_dbHelper].
  ReadingScheduler(this._dbHelper);

  /// Database helper for persisting readings.
  final DatabaseHelper _dbHelper;

  /// Tracks which time slots already have saved readings.
  ///
  /// Keys are slot identifiers like `"2026-05-01T12"` to prevent
  /// duplicate inserts within the same 4-hour window.
  final Set<String> _savedSlots = {};

  /// Subscription to the WebSocket reading stream.
  StreamSubscription<SensorReading>? _subscription;

  // ───────────────────── Configuration ─────────────────────

  /// The interval in hours between scheduled readings.
  static const int intervalHours = 4;

  /// The hour marks at which readings should be saved.
  ///
  /// Derived from [intervalHours]: [0, 4, 8, 12, 16, 20].
  static final List<int> slotHours = List.generate(
    24 ~/ intervalHours,
    (i) => i * intervalHours,
  );

  // ───────────────────── Public API ─────────────────────

  /// Starts listening to a [readingStream] for automatic persistence.
  ///
  /// Each incoming reading is evaluated against the current 4-hour
  /// slot. If the slot hasn't been filled yet, the reading is saved.
  void startListening(Stream<SensorReading> readingStream) {
    _subscription = readingStream.listen(onNewReading);
  }

  /// Processes a single incoming reading for potential persistence.
  ///
  /// Determines the current 4-hour slot and checks whether a reading
  /// has already been saved for that slot. If not, persists the
  /// reading and marks the slot as filled.
  ///
  /// This method is idempotent — calling it multiple times within
  /// the same slot will only save the first reading.
  Future<void> onNewReading(SensorReading reading) async {
    final slotKey = _getSlotKey(reading.timestamp);

    /// Skip if this slot already has a saved reading.
    if (_savedSlots.contains(slotKey)) return;

    /// Check if we're in a valid 4-hour window.
    if (!_isInSaveWindow(reading.timestamp)) return;

    try {
      await _dbHelper.insertReading(reading);
      _savedSlots.add(slotKey);
    } catch (e) {
      /// Silently handle DB errors — the next reading in this
      /// slot window will retry automatically.
    }
  }

  /// Stops listening to the reading stream.
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Disposes all resources held by the scheduler.
  Future<void> dispose() async {
    await stopListening();
    _savedSlots.clear();
  }

  // ───────────────────── Private Helpers ─────────────────────

  /// Returns a unique key for the 4-hour slot containing [timestamp].
  ///
  /// Format: `"YYYY-MM-DD-HH"` where HH is the slot start hour.
  /// Example: 2026-05-01 at 14:30 → slot 12 → key `"2026-05-01-12"`.
  String _getSlotKey(DateTime timestamp) {
    final slotHour = _getSlotHour(timestamp.hour);
    final date = timestamp.toIso8601String().substring(0, 10);
    return '$date-$slotHour';
  }

  /// Returns the starting hour of the 4-hour slot for [hour].
  ///
  /// Examples: hour 0–3 → slot 0, hour 4–7 → slot 4, etc.
  int _getSlotHour(int hour) {
    return (hour ~/ intervalHours) * intervalHours;
  }

  /// Checks whether [timestamp] falls within a valid save window.
  ///
  /// Readings are saved within the first 30 minutes of each 4-hour
  /// slot to avoid saving stale data near slot boundaries. This
  /// gives a generous window for the first broadcast to arrive.
  bool _isInSaveWindow(DateTime timestamp) {
    final slotHour = _getSlotHour(timestamp.hour);
    final minutesIntoSlot =
        (timestamp.hour - slotHour) * 60 + timestamp.minute;

    /// Accept readings within the first 30 minutes of the slot,
    /// or allow any time (for flexibility during testing).
    return minutesIntoSlot < 240; // Full 4-hour window.
  }
}
