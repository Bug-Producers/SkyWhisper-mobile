/// Aggregated daily average model for SkyWhisper historical data.
///
/// Represents the mean temperature, humidity, and pressure for a
/// single calendar day, computed from the 4-hour interval readings
/// stored in the SQLite database.
library;

/// A single day's aggregated sensor statistics.
///
/// Created by grouping [SensorReading] rows by date and computing
/// the arithmetic mean for each metric. The [readingCount] field
/// indicates how many data points contributed to the average
/// (expected: up to 6 per day at 4-hour intervals).
class DailyAverage {
  /// Creates a [DailyAverage] with all required fields.
  const DailyAverage({
    required this.date,
    required this.avgTemperature,
    required this.avgHumidity,
    required this.avgPressure,
    required this.readingCount,
  });

  /// The calendar date this average covers (time portion is midnight).
  final DateTime date;

  /// Mean temperature (°C) across all readings for this day.
  final double avgTemperature;

  /// Mean relative humidity (%) across all readings for this day.
  final double avgHumidity;

  /// Mean barometric pressure (hPa) across all readings for this day.
  final double avgPressure;

  /// Number of sensor readings that contributed to this average.
  ///
  /// With a 4-hour interval schedule, the maximum is 6 per day
  /// (00:00, 04:00, 08:00, 12:00, 16:00, 20:00).
  final int readingCount;

  // ───────────────────── SQLite Factory ─────────────────────

  /// Constructs a [DailyAverage] from a SQLite `GROUP BY` result row.
  ///
  /// Expected columns from the query:
  /// ```sql
  /// SELECT date(timestamp) AS day,
  ///        AVG(temperature)   AS avg_temp,
  ///        AVG(humidity)      AS avg_hum,
  ///        AVG(pressure)      AS avg_pres,
  ///        COUNT(*)           AS count
  /// FROM sensor_readings
  /// GROUP BY day
  /// ```
  factory DailyAverage.fromMap(Map<String, dynamic> map) {
    return DailyAverage(
      date: DateTime.parse(map['day'] as String),
      avgTemperature: (map['avg_temp'] as num).toDouble(),
      avgHumidity: (map['avg_hum'] as num).toDouble(),
      avgPressure: (map['avg_pres'] as num).toDouble(),
      readingCount: (map['count'] as num).toInt(),
    );
  }

  // ───────────────────── Utilities ─────────────────────

  /// Returns a human-readable summary for debugging purposes.
  @override
  String toString() =>
      'DailyAverage(date: ${date.toIso8601String().substring(0, 10)}, '
      'avgTemp: ${avgTemperature.toStringAsFixed(1)}°C, '
      'avgHum: ${avgHumidity.toStringAsFixed(1)}%, '
      'avgPres: ${avgPressure.toStringAsFixed(1)} hPa, '
      'readings: $readingCount)';
}
