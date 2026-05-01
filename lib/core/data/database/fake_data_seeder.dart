/// One-time fake data seeder for SkyWhisper historical readings.
///
/// Generates realistic sensor data at 4-hour intervals from
/// April 1, 2026 through May 2, 2026 (32 days × 6 readings = 192
/// rows). The data simulates realistic daily temperature cycles,
/// humidity patterns, and barometric pressure trends.
library;

import 'dart:math';

import '../models/sensor_reading.dart';
import 'database_helper.dart';

/// Seeds the SQLite database with synthetic historical sensor data.
///
/// This class generates plausible weather data that follows natural
/// patterns:
/// - **Temperature**: Sinusoidal daily cycle (cool at night, warm
///   midday) with a gradual seasonal warming trend from April to May.
/// - **Humidity**: Inversely correlated with temperature — higher at
///   night, lower during warm afternoons.
/// - **Pressure**: Slow random walk around 1013 hPa, simulating
///   the passage of high/low pressure systems.
///
/// The seeder is idempotent — it checks the `data_seeded` flag in
/// the `app_metadata` table before inserting and sets it afterward.
class FakeDataSeeder {
  /// Creates a [FakeDataSeeder] bound to the given [_dbHelper].
  FakeDataSeeder(this._dbHelper);

  /// Reference to the database helper for inserts and metadata checks.
  final DatabaseHelper _dbHelper;

  /// Random number generator for adding natural jitter to values.
  final _random = Random(42); // Fixed seed for reproducible data.

  // ───────────────────── Configuration ─────────────────────

  /// Start of the fake data range (inclusive).
  static final DateTime _startDate = DateTime(2026, 4, 1);

  /// End of the fake data range (inclusive).
  static final DateTime _endDate = DateTime(2026, 5, 2);

  /// Hours at which readings are taken each day.
  ///
  /// Six readings per day at 4-hour intervals: midnight, 4 AM,
  /// 8 AM, noon, 4 PM, and 8 PM.
  static const List<int> _readingHours = [0, 4, 8, 12, 16, 20];

  // ───────────────────── Seeding Logic ─────────────────────

  /// Seeds the database with fake data if it hasn't been done yet.
  ///
  /// Returns `true` if new data was inserted, `false` if the
  /// database was already seeded from a previous app launch.
  Future<bool> seedIfNeeded() async {
    /// Check the idempotency guard.
    final alreadySeeded = await _dbHelper.isDataSeeded();
    if (alreadySeeded) return false;

    /// Generate all readings and batch-insert them.
    final readings = _generateReadings();
    await _dbHelper.insertReadingsBatch(readings);

    /// Set the guard flag to prevent re-seeding.
    await _dbHelper.markDataSeeded();

    return true;
  }

  /// Generates the complete list of fake [SensorReading] objects.
  ///
  /// Iterates day-by-day from [_startDate] to [_endDate] and
  /// creates one reading per slot in [_readingHours].
  List<SensorReading> _generateReadings() {
    final readings = <SensorReading>[];

    /// Pressure starts at a typical sea-level baseline.
    var currentPressure = 1013.0;

    /// Calculate total number of days for the seasonal trend.
    final totalDays = _endDate.difference(_startDate).inDays;

    for (var day = 0; day <= totalDays; day++) {
      final date = _startDate.add(Duration(days: day));

      /// Seasonal warming: base temperature rises ~4°C over the
      /// 32-day span (spring warming from April into May).
      final seasonalOffset = (day / totalDays) * 4.0;

      for (final hour in _readingHours) {
        final timestamp = DateTime(date.year, date.month, date.day, hour);

        /// Temperature model:
        /// - Base: 22°C (spring average for a temperate region).
        /// - Diurnal cycle: ±6°C sinusoidal, peaking at 14:00.
        /// - Seasonal trend: +0 to +4°C over the month.
        /// - Random jitter: ±1.5°C for natural variation.
        final hourAngle = (hour - 14) * (pi / 12); // Peak at 14:00.
        final diurnalSwing = -6.0 * cos(hourAngle);
        final jitter = (_random.nextDouble() - 0.5) * 3.0;
        final temperature = 22.0 + seasonalOffset + diurnalSwing + jitter;

        /// Humidity model:
        /// - Base: 55% (moderate spring humidity).
        /// - Inversely correlated with temperature deviation.
        /// - Random jitter: ±5%.
        final humJitter = (_random.nextDouble() - 0.5) * 10.0;
        final humidity =
            (55.0 - (diurnalSwing * 2.5) + humJitter).clamp(25.0, 85.0);

        /// Pressure model:
        /// - Random walk: ±0.3 hPa per reading.
        /// - Clamped to realistic range: 998–1028 hPa.
        final pressureStep = (_random.nextDouble() - 0.5) * 0.6;
        currentPressure =
            (currentPressure + pressureStep).clamp(998.0, 1028.0);

        readings.add(SensorReading(
          temperature: double.parse(temperature.toStringAsFixed(2)),
          humidity: double.parse(humidity.toStringAsFixed(2)),
          pressure: double.parse(currentPressure.toStringAsFixed(2)),
          timestamp: timestamp,
        ));
      }
    }

    return readings;
  }
}
