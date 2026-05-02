/// Reusable text styles and decoration constants for SkyWhisper.
///
/// Uses [flutter_screenutil] for responsive font scaling. All styles
/// reference [AppColors] to keep the design system cohesive. Typography
/// defaults to the platform font (Roboto on Android, SF Pro on iOS).
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// Provides factory getters for every text style tier used in the app.
///
/// Styles are built lazily so that [ScreenUtil] is guaranteed to be
/// initialized before any `.sp` value is resolved.
abstract final class AppStyles {
  // ───────────────────── Headings ─────────────────────

  /// App bar brand name — bold, uppercase, 18 sp.
  static TextStyle get brandTitle => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
        letterSpacing: 1.2,
      );

  /// Large metric value (e.g. "24°", "1013").
  static TextStyle get metricLarge => TextStyle(
        fontSize: 42.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  /// Medium metric value used in the pressure card.
  static TextStyle get metricMedium => TextStyle(
        fontSize: 36.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.1,
      );

  /// Metric unit suffix (e.g. "°", "%", "hPa").
  static TextStyle get metricUnit => TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ───────────────────── Labels ─────────────────────

  /// All-caps label beneath a sensor value (e.g. "TEMPERATURE").
  static TextStyle get sensorLabel => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 1.5,
      );

  /// Section title (e.g. "Climate").
  static TextStyle get sectionTitle => TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Section subtitle (e.g. "Past 30 days Overview").
  static TextStyle get sectionSubtitle => TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  /// Small caption text used on the live-status bar and chart axes.
  static TextStyle get caption => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  /// Tiny trend label (e.g. "+2.4 hPa/h").
  static TextStyle get trendValue => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.positive,
      );

  /// Pressure sub-label ("ATMOSPHERIC PRESSURE").
  static TextStyle get pressureLabel => TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      );

  /// Card title style — bold, uppercase, 14 sp.
  static TextStyle get cardTitle => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  /// Small label style for secondary metadata.
  static TextStyle get labelSmall => TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  // ───────────────────── Decorations ─────────────────────

  /// Standard card decoration with rounded corners, a subtle border,
  /// and a soft shadow to create the elevated card look.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      );
}
