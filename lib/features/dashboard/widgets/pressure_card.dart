/// Atmospheric pressure card for the SkyWhisper dashboard.
///
/// Displays the current barometric pressure reading (in hPa) along
/// with an icon, descriptive labels, and a small trend indicator.
/// Now accepts a dynamic [pressure] value from the live sensor
/// stream via Riverpod providers.
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
///
/// When [pressure] is `null` (no live data), displays "--" as a
/// placeholder to indicate the sensor hasn't reported yet.
class PressureCard extends StatelessWidget {
  /// Creates a [PressureCard] with an optional live [pressure] value.
  const PressureCard({
    this.pressure,
    super.key,
  });

  /// Current barometric pressure in hPa. Null when offline or loading.
  final double? pressure;

  @override
  Widget build(BuildContext context) {
    /// Format the pressure display value.
    final displayValue = pressure != null
        ? pressure!.toStringAsFixed(0)
        : '--';

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
                    Text(displayValue, style: AppStyles.metricMedium),
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
              Text(
                pressure != null ? '+2.4' : '--',
                style: AppStyles.trendValue,
              ),
              Text('hPa/h', style: AppStyles.trendValue),
            ],
          ),
        ],
      ),
    );
  }
}
