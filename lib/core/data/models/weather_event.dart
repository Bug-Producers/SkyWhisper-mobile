/// Represents an identified environmental event.
class WeatherEvent {
  const WeatherEvent({
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.description,
    required this.icon,
  });

  /// The category of the event (e.g., Storm, Heatwave).
  final String type;

  /// Severity level: 1 (Low) to 3 (Critical).
  final int severity;

  /// When the event was detected or started.
  final DateTime timestamp;

  /// Human-readable explanation.
  final String description;

  /// Icon identifier for the UI.
  final String icon;

  @override
  String toString() => '$type ($severity): $description at $timestamp';
}
