/// Reusable circular-gauge sensor card for SkyWhisper.
///
/// Used to present temperature and humidity readings with a large
/// numeric value, a circular progress ring, a centered icon, and a
/// descriptive label. The ring's color, progress fraction, icon, and
/// text are fully parameterized so the same widget works for both
/// sensor types.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';

/// Displays a single sensor reading inside a rounded card.
///
/// The card contains:
/// - A [CustomPaint] circular arc showing [progress] (0.0 – 1.0).
/// - An [icon] in the center of the arc.
/// - A large formatted value ([value] + [unit]).
/// - An uppercase [label] (e.g. "TEMPERATURE").
///
/// The [ringColor] determines the stroke color of the arc.
class SensorCard extends StatelessWidget {
  /// Creates a [SensorCard].
  ///
  /// All parameters are required to ensure the card is fully configured.
  const SensorCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.progress,
    required this.ringColor,
    super.key,
  });

  /// The icon displayed at the center of the circular gauge.
  final IconData icon;

  /// The main numeric reading (e.g. "24").
  final String value;

  /// The unit suffix shown beside the value (e.g. "°" or "%").
  final String unit;

  /// The uppercase label beneath the reading (e.g. "TEMPERATURE").
  final String label;

  /// Progress fraction from 0.0 to 1.0 controlling the arc sweep.
  final double progress;

  /// Stroke color of the progress arc.
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: AppStyles.cardDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Circular gauge ring with centered icon.
          SizedBox(
            width: 90.w,
            height: 90.w,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                ringColor: ringColor,
                trackColor: AppColors.ringTrack,
              ),
              child: Center(
                child: Icon(icon, color: ringColor, size: 26.sp),
              ),
            ),
          ),
          SizedBox(height: 14.h),

          /// Value + unit row (e.g. "24°").
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppStyles.metricLarge),
              Padding(
                padding: EdgeInsets.only(top: 4.h),
                child: Text(unit, style: AppStyles.metricUnit),
              ),
            ],
          ),
          SizedBox(height: 6.h),

          /// Sensor label in small uppercase letters.
          Text(label, style: AppStyles.sensorLabel),
        ],
      ),
    );
  }
}

/// Custom painter that draws the circular progress ring.
///
/// Renders a full-circle track in [trackColor] and overlays an arc
/// of [progress] × 360° in [ringColor] starting from the top (–90°).
class _RingPainter extends CustomPainter {
  /// Creates a [_RingPainter] with the given visual parameters.
  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  /// Fraction of the ring to fill (0.0 – 1.0).
  final double progress;

  /// Color of the filled portion of the arc.
  final Color ringColor;

  /// Color of the unfilled background arc.
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 6.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    /// Track paint — full circle background.
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    /// Progress paint — colored arc overlay.
    final progressPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ringColor != ringColor ||
      oldDelegate.trackColor != trackColor;
}
