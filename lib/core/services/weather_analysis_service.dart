import 'dart:math';
import '../data/models/sensor_reading.dart';
import '../data/models/weather_event.dart';

/**
 * The core analysis engine for the SkyWhisper environmental monitoring system.
 * 
 * <p>This service processes raw historical sensor data to identify significant
 * climatic patterns and anomalies. It utilizes various meteorological heuristics
 * to detect events such as heatwaves, storms, and optimal growing conditions.
 */
class WeatherAnalysisService {
  /**
   * Performs a comprehensive multi-dimensional analysis on the provided readings.
   * 
   * <p>This method orchestrates a suite of specialized detection algorithms and
   * aggregates their findings into a chronological timeline of weather events.
   * 
   * @param readings The list of [SensorReading] objects representing historical data points.
   * @return A list of [WeatherEvent] objects identified within the data range, 
   *         sorted newest-to-oldest.
   */
  List<WeatherEvent> analyze(List<SensorReading> readings) {
    if (readings.isEmpty) return [];

    final events = <WeatherEvent>[];
    
    events.addAll(_detectHeatwaves(readings));
    events.addAll(_detectStorms(readings));
    events.addAll(_detectColdFronts(readings));
    events.addAll(_detectExtremeSwings(readings));
    events.addAll(_detectPerfectConditions(readings));
    
    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return events;
  }

  /**
   * Detects sustained high-temperature periods (Heatwaves).
   * 
   * <p>A heatwave is defined as a sequence of 3 or more consecutive days where the 
   * daily average temperature exceeds 28°C.
   * 
   * @param readings The historical readings to scan.
   * @return A list of heatwave [WeatherEvent]s found.
   */
  List<WeatherEvent> _detectHeatwaves(List<SensorReading> readings) {
    final events = <WeatherEvent>[];
    final dailyTemps = <String, List<double>>{};
    
    for (final r in readings) {
      final dateKey = _toDateKey(r.timestamp);
      dailyTemps.putIfAbsent(dateKey, () => []).add(r.temperature);
    }

    final sortedDates = dailyTemps.keys.toList()..sort();
    int consecutiveDays = 0;
    
    for (final dateKey in sortedDates) {
      final avg = dailyTemps[dateKey]!.reduce((a, b) => a + b) / dailyTemps[dateKey]!.length;
      if (avg > 28.0) {
        consecutiveDays++;
        if (consecutiveDays == 3) {
          events.add(WeatherEvent(
            type: 'Heatwave',
            severity: 3,
            timestamp: DateTime.parse(dateKey),
            description: 'We have detected a sustained period of extreme heat. Stay hydrated.',
            icon: 'wb_sunny',
          ));
        }
      } else {
        consecutiveDays = 0;
      }
    }
    return events;
  }

  /**
   * Scans for rapid atmospheric pressure drops associated with incoming storms.
   * 
   * <p>Identifies "Storm Risk" when the barometric pressure falls by more than 
   * 5 hPa within a 12-hour period (3 consecutive 4-hour readings).
   * 
   * @param readings The readings to analyze for pressure trends.
   * @return A list of identified storm risk [WeatherEvent]s.
   */
  List<WeatherEvent> _detectStorms(List<SensorReading> readings) {
    final events = <WeatherEvent>[];
    for (int i = 3; i < readings.length; i++) {
      final current = readings[i];
      final previous = readings[i - 3];
      
      final diff = previous.pressure - current.pressure;
      if (diff > 5.0) {
        events.add(WeatherEvent(
          type: 'Storm Risk',
          severity: 3,
          timestamp: current.timestamp,
          description: 'A sharp pressure drop of ${diff.toStringAsFixed(1)} hPa suggests a storm is brewing.',
          icon: 'thunderstorm',
        ));
        i += 6; 
      }
    }
    return events;
  }

  /**
   * Detects sudden temperature drops representing a cold front arrival.
   * 
   * <p>A cold front event is triggered when the temperature decreases by more 
   * than 6°C between two consecutive 4-hour readings.
   * 
   * @param readings The readings to scan for temperature plunges.
   * @return A list of cold front [WeatherEvent]s.
   */
  List<WeatherEvent> _detectColdFronts(List<SensorReading> readings) {
    final events = <WeatherEvent>[];
    for (int i = 2; i < readings.length; i++) {
      final current = readings[i];
      final previous = readings[i - 1]; 
      
      final diff = previous.temperature - current.temperature;
      if (diff > 6.0) {
        events.add(WeatherEvent(
          type: 'Cold Front',
          severity: 2,
          timestamp: current.timestamp,
          description: 'Temperatures have dropped ${diff.toStringAsFixed(1)}°C very quickly. Bundle up!',
          icon: 'ac_unit',
        ));
      }
    }
    return events;
  }

  /**
   * Identifies days with high diurnal temperature variance.
   * 
   * <p>Triggers an "Extreme Swing" event when the difference between the daily 
   * maximum and minimum temperature exceeds 15°C.
   * 
   * @param readings The readings to group and analyze by day.
   * @return A list of extreme swing [WeatherEvent]s.
   */
  List<WeatherEvent> _detectExtremeSwings(List<SensorReading> readings) {
    final events = <WeatherEvent>[];
    final dailyData = <String, List<double>>{};
    
    for (final r in readings) {
      final dateKey = _toDateKey(r.timestamp);
      dailyData.putIfAbsent(dateKey, () => []).add(r.temperature);
    }

    for (final dateKey in dailyData.keys) {
      final temps = dailyData[dateKey]!;
      final minTemp = temps.reduce(min);
      final maxTemp = temps.reduce(max);
      final range = maxTemp - minTemp;
      
      if (range > 15.0) {
        events.add(WeatherEvent(
          type: 'Extreme Swing',
          severity: 2,
          timestamp: DateTime.parse(dateKey),
          description: 'This day saw a massive ${range.toStringAsFixed(1)}°C swing between day and night.',
          icon: 'thermostat',
        ));
      }
    }
    return events;
  }

  /**
   * Identifies days with optimal environmental parameters for humans and plants.
   * 
   * <p>Criteria: Daily average temperature between 18-24°C AND daily average 
   * humidity between 40-60%.
   * 
   * @param readings The readings to evaluate against the "Perfect Day" profile.
   * @return A list of [WeatherEvent]s for days meeting ideal conditions.
   */
  List<WeatherEvent> _detectPerfectConditions(List<SensorReading> readings) {
    final events = <WeatherEvent>[];
    final dailyData = <String, List<SensorReading>>{};
    
    for (final r in readings) {
      final dateKey = _toDateKey(r.timestamp);
      dailyData.putIfAbsent(dateKey, () => []).add(r);
    }

    for (final dateKey in dailyData.keys) {
      final dayReadings = dailyData[dateKey]!;
      final avgTemp = dayReadings.map((e) => e.temperature).reduce((a, b) => a + b) / dayReadings.length;
      final avgHum = dayReadings.map((e) => e.humidity).reduce((a, b) => a + b) / dayReadings.length;
      
      if (avgTemp >= 18 && avgTemp <= 24 && avgHum >= 40 && avgHum <= 60) {
        events.add(WeatherEvent(
          type: 'Perfect Day',
          severity: 1,
          timestamp: DateTime.parse(dateKey),
          description: 'The weather was perfect today—ideal for both you and your garden.',
          icon: 'eco',
        ));
      }
    }
    return events;
  }

  /**
   * Calculates the current barometric pressure trend.
   * 
   * <p>Compares the most recent reading with data from 12 hours ago.
   * 
   * @param readings The list of readings to check for recent changes.
   * @return A string representing the trend: 'Rising', 'Falling', or 'Steady'.
   */
  String calculatePressureTrend(List<SensorReading> readings) {
    if (readings.length < 3) return 'Steady';
    
    final recent = readings.sublist(readings.length - 3);
    final diff = recent.last.pressure - recent.first.pressure;
    
    if (diff > 1.5) return 'Rising';
    if (diff < -1.5) return 'Falling';
    return 'Steady';
  }

  /**
   * Utility to convert a [DateTime] into a standardized date key.
   * 
   * @param dt The date to format.
   * @return A string in YYYY-MM-DD format.
   */
  String _toDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
