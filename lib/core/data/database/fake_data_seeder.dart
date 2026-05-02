/**
 * The synthetic data generation engine for the SkyWhisper historical database.
 * 
 * <p>This seeder populates the local SQLite database with realistic sensor readings
 * representing one month of climate history. It ensures that the application has 
 * immediate visualization data upon its first execution.
 */

import 'dart:math';
import 'database_helper.dart';
import '../models/sensor_reading.dart';
class FakeDataSeeder {
  /**
   * Initializes the seeder with the provided database helper.
   * 
   * @param _dbHelper The [DatabaseHelper] instance used for persistence operations.
   */
  FakeDataSeeder(this._dbHelper);

  /** The gateway to the SQLite database. */
  final DatabaseHelper _dbHelper;

  /** 
   * The pseudo-random number generator for sensor jitter.
   * Fixed seed (42) used for deterministic data generation across resets. 
   */
  final _random = Random(42);

  // ───────────────────── Simulation Parameters ─────────────────────

  /** The starting point of the historical simulation range. */
  static final DateTime _startDate = DateTime(2026, 4, 1);

  /** The ending point of the historical simulation range. */
  static final DateTime _endDate = DateTime(2026, 5, 2);

  /** 
   * The specific hours within each day that a reading is generated.
   * Six samples per day at 4-hour intervals. 
   */
  static const List<int> _readingHours = [0, 4, 8, 12, 16, 20];

  // ───────────────────── Operations ─────────────────────

  /**
   * Executes the seeding process if the database is currently empty.
   * 
   * <p>Checks the internal 'data_seeded' flag to ensure idempotency. If the 
   * flag is absent, it generates the synthetic reading set and batch-inserts it.
   * 
   * @return A [Future] that resolves to true if data was seeded, false otherwise.
   */
  Future<bool> seedIfNeeded() async {
    final alreadySeeded = await _dbHelper.isDataSeeded();
    if (alreadySeeded) return false;

    final readings = _generateReadings();
    await _dbHelper.insertReadingsBatch(readings);

    await _dbHelper.markDataSeeded();
    return true;
  }

  /**
   * Generates a complete sequence of realistic [SensorReading] objects.
   * 
   * <p>The generation logic models natural phenomena:
   * <ul>
   *   <li>Seasonal warming trends</li>
   *   <li>Diurnal temperature and humidity cycles</li>
   *   <li>Atmospheric pressure fluctuations</li>
   *   <li>Specific environmental event injections (storms, heatwaves)</li>
   * </ul>
   * 
   * @return An unmodifiable list of synthetic [SensorReading] objects.
   */
  List<SensorReading> _generateReadings() {
    final readings = <SensorReading>[];
    var currentPressure = 1013.0;
    final totalDays = _endDate.difference(_startDate).inDays;

    for (var day = 0; day <= totalDays; day++) {
      final date = _startDate.add(Duration(days: day));

      final seasonalOffset = (day / totalDays) * 6.0;
      final baseTemp = 12.0 + seasonalOffset;

      for (final hour in _readingHours) {
        final timestamp = DateTime(date.year, date.month, date.day, hour);

        final hourAngle = (hour - 14) * (pi / 12);
        var diurnalSwing = -5.0 * cos(hourAngle);
        
        bool isStorm = date.day >= 10 && date.day <= 12 && date.month == 4;
        bool isHeatwave = date.day >= 22 && date.day <= 26 && date.month == 4;
        bool isColdFront = date.day == 15 && date.month == 4 && hour >= 12;
        bool isExtremeSwing = date.day == 18 && date.month == 4;

        var tempOffset = 0.0;
        var humOffset = 0.0;
        var presOffset = 0.0;

        if (isStorm) {
          tempOffset = -4.0;
          humOffset = 25.0;
          presOffset = -12.0;
        } else if (isHeatwave) {
          tempOffset = 10.0;
          humOffset = -15.0;
        } else if (isColdFront) {
          tempOffset = -10.0;
        } else if (isExtremeSwing) {
          diurnalSwing *= 1.8; 
        }

        final jitter = (_random.nextDouble() - 0.5) * 2.0;
        final temperature = baseTemp + diurnalSwing + tempOffset + jitter;

        final humJitter = (_random.nextDouble() - 0.5) * 8.0;
        final humidity =
            (55.0 - (diurnalSwing * 2.0) + humOffset + humJitter).clamp(20.0, 95.0);

        final pressureStep = (_random.nextDouble() - 0.5) * 0.8;
        currentPressure = (currentPressure + pressureStep + (presOffset / 6))
            .clamp(990.0, 1030.0);

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
