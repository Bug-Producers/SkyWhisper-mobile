/// Atmospheric pressure card for the SkyWhisper dashboard.
///
/// Displays the current barometric pressure reading (in hPa) along
/// with an icon, descriptive labels, and a small trend indicator
/// showing the rate of change (e.g. "+2.4 hPa/h") with a directional
/// trend arrow icon.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';

/// A stateless widget presenting the atmospheric pressure reading.
///
/// Layout is a single [Row] with three logical sections:
/// 1. A circular icon container on the left.
/// 2. The pressure label and value in the center.
/// 3. A trend indicator with arrow and delta text on the right.
class PressureCard extends StatelessWidget {
  /// Creates a [PressureCard].
  const PressureCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: AppStyles.cardDecoration,
      child: Row(
        children: [
          /// Leading icon inside a soft blue circle.
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.air_rounded,
              color: AppColors.primary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),

          /// Center block: label + value + unit.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ATMOSPHERIC', style: AppStyles.pressureLabel),
                Text('PRESSURE', style: AppStyles.pressureLabel),
                SizedBox(height: 4.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('1013', style: AppStyles.metricMedium),
                    SizedBox(width: 4.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text('hPa', style: AppStyles.metricUnit),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// Trailing trend indicator.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.trending_up_rounded,
                  color: AppColors.positive, size: 22.sp),
              SizedBox(height: 4.h),
              Text('+2.4', style: AppStyles.trendValue),
              Text('hPa/h', style: AppStyles.trendValue),
            ],
          ),
        ],
      ),
    );
  }
}
