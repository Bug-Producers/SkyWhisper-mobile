/// Top header bar displaying the SkyWhisper brand identity.
///
/// Shows a cloud icon alongside the "SKYWHISPER" brand name in the
/// primary blue color. The header sits at the top of the dashboard
/// and establishes the visual identity of the application.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';

/// A stateless widget that renders the SkyWhisper app-bar header.
///
/// Consists of a [Row] containing a cloud icon and the brand title,
/// separated by a small gap. Uses [AppStyles.brandTitle] for consistent
/// typography and [AppColors.primary] for the icon tint.
class DashboardHeader extends StatelessWidget {
  /// Creates a [DashboardHeader].
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          /// Cloud icon representing the "Sky" motif.
          Icon(
            Icons.cloud_outlined,
            color: AppColors.primary,
            size: 26.sp,
          ),
          SizedBox(width: 8.w),

          /// Brand name in uppercase bold styling.
          Text('SKYWHISPER', style: AppStyles.brandTitle),
        ],
      ),
    );
  }
}
