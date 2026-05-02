import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';

/**
 * A versatile safety-net for our UI.
 * 
 * We use this widget whenever a specific part of the app fails to load data.
 * Instead of showing a blank screen or a cryptic technical error, this 
 * provides a friendly message and a way for the user to try again.
 */
class AppErrorWidget extends StatelessWidget {
  /// Creates an error state with a [message] and an optional [onRetry] callback.
  const AppErrorWidget({
    required this.message,
    this.onRetry,
    super.key,
  });

  /// The human-friendly explanation of what went wrong.
  final String message;

  /// The action to perform when the user taps "Retry". Usually refreshes a provider.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent.withOpacity(0.8),
              size: 40.sp,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.labelSmall.copyWith(color: Colors.white70),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              TextButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh_rounded, size: 18.sp),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
