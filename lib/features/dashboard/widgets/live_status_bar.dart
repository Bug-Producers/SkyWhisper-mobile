/// Live status indicator bar for the SkyWhisper dashboard.
///
/// Displays a pill-shaped connection badge with a colored dot
/// indicating the WebSocket connection state, and a timestamp
/// showing when the last reading was received. Adapts its
/// appearance based on the [ConnectionStatus] from the
/// WebSocket service.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/data/models/sensor_reading.dart';
import '../../../core/services/sensor_ws_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';

/// A widget that renders the live-status bar row.
///
/// Shows real-time connection state:
/// - 🟢 **Connected**: "Live Sensors" with green dot.
/// - 🟡 **Connecting**: "Connecting…" with amber dot.
/// - 🔴 **Disconnected/Error**: "Offline" with red dot.
///
/// The right side shows how recently data was received,
/// or "No data yet" if no readings have arrived.
class LiveStatusBar extends StatelessWidget {
  /// Creates a [LiveStatusBar] with the given connection [status]
  /// and optional [lastReading] for the timestamp display.
  const LiveStatusBar({
    required this.status,
    this.lastReading,
    super.key,
  });

  /// Current WebSocket connection status.
  final ConnectionStatus status;

  /// The most recently received sensor reading (for timestamp).
  /// Null if no data has been received yet.
  final SensorReading? lastReading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Pill badge: colored dot + connection label.
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Colored circle indicating connection state.
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(_statusLabel, style: AppStyles.caption),
              ],
            ),
          ),

          /// Timestamp indicating data freshness.
          Text(_timestampLabel, style: AppStyles.caption),
        ],
      ),
    );
  }

  // ───────────────────── Derived Display Values ─────────────────────

  /// Returns the dot color based on [status].
  Color get _dotColor {
    return switch (status) {
      ConnectionStatus.connected => AppColors.liveGreen,
      ConnectionStatus.connecting => const Color(0xFFFBBF24), // Amber.
      ConnectionStatus.disconnected => const Color(0xFFEF4444), // Red.
      ConnectionStatus.error => const Color(0xFFEF4444), // Red.
    };
  }

  /// Returns the human-readable connection label.
  String get _statusLabel {
    return switch (status) {
      ConnectionStatus.connected => 'Live Sensors',
      ConnectionStatus.connecting => 'Connecting…',
      ConnectionStatus.disconnected => 'Offline',
      ConnectionStatus.error => 'Connection Error',
    };
  }

  /// Returns a relative timestamp string based on [lastReading].
  String get _timestampLabel {
    if (lastReading == null) return 'No data yet';

    final elapsed = DateTime.now().difference(lastReading!.timestamp);

    if (elapsed.inSeconds < 10) return 'Updated Just Now';
    if (elapsed.inSeconds < 60) return 'Updated ${elapsed.inSeconds}s ago';
    if (elapsed.inMinutes < 60) return 'Updated ${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return 'Updated ${elapsed.inHours}h ago';

    return 'Updated ${elapsed.inDays}d ago';
  }
}
