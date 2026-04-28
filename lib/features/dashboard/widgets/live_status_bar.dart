/// Live status indicator bar for the SkyWhisper dashboard.
///
/// Displays a pill-shaped "Live Sensors" badge with a pulsing green
/// dot on the left, and a "Updated Just Now" timestamp on the right.
/// This bar communicates that the displayed data is current and
/// streaming from connected sensors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';

/// A stateless widget that renders the live-status bar row.
///
/// The green dot uses a small filled [CircleAvatar] and the pill
/// badge is a [Container] with a rounded border. Both sides of the
/// row are wrapped in a [Padding] for consistent spacing.
class LiveStatusBar extends StatelessWidget {
  /// Creates a [LiveStatusBar].
  const LiveStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Pill badge: green dot + "Live Sensors" label.
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
                /// Animated green circle indicating live status.
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: AppColors.liveGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                Text('Live Sensors', style: AppStyles.caption),
              ],
            ),
          ),

          /// Timestamp indicating data freshness.
          Text('Updated Just Now', style: AppStyles.caption),
        ],
      ),
    );
  }
}
