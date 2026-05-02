import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/sensor_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/data/models/weather_event.dart';
import '../../../core/widgets/app_error_widget.dart';

/**
 * A beautiful, glassmorphic card that presents the "Story" of your weather.
 * 
 * Instead of just showing raw data, this widget watches the [weatherAnalysisProvider]
 * and displays a list of the most significant events (storms, heatwaves, etc.) 
 * identified by our analysis engine.
 */
class WeatherInsightsCard extends ConsumerWidget {
  /// Creates a [WeatherInsightsCard].
  const WeatherInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// We watch the analysis provider. This triggers a scan of the 
    /// last 30 days of data whenever the app starts or data changes.
    final analysisAsync = ref.watch(weatherAnalysisProvider);

    return Container(
      width: double.infinity,
      decoration: AppStyles.cardDecoration,
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: AppColors.primary, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'WEATHER INSIGHTS',
                style: AppStyles.cardTitle.copyWith(letterSpacing: 1.2),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          
          /**
           * Handling different data states:
           * - Data: Shows the list of events (or an empty message).
           * - Loading: Shows a subtle progress indicator.
           * - Error: Shows our friendly [AppErrorWidget] with a retry option.
           */
          analysisAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Text(
                      'Your environment has been stable. No significant events detected lately.',
                      textAlign: TextAlign.center,
                      style: AppStyles.labelSmall,
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length > 5 ? 5 : events.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _InsightItem(event: event);
                },
              );
            },
            loading: () => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: const CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => AppErrorWidget(
              message: 'We had a little trouble analyzing your weather history.',
              onRetry: () => ref.invalidate(weatherAnalysisProvider),
            ),
          ),
        ],
      ),
    );
  }
}

/**
 * An individual row within the Insights Card.
 * 
 * Each item uses color-coding to indicate the severity of the event:
 * - Orange: Critical/Warning (Severity 3)
 * - Blue: Information/Notice (Severity 2)
 * - Teal: Positive/Optimal (Severity 1)
 */
class _InsightItem extends StatelessWidget {
  const _InsightItem({required this.event});

  final WeatherEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _getSeverityColor(event.severity);
    final iconData = _getIconData(event.icon);

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Colored icon badge for the event type.
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: color, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// Event Category (e.g., STORM, HEATWAVE).
                    Text(
                      event.type.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    /// Simple date marker.
                    Text(
                      DateFormat('MMM dd').format(event.timestamp),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                /// The "Human" description of the event.
                Text(
                  event.description,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Maps severity level to a meaningful UI color.
  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 3:
        return Colors.orange;
      case 2:
        return AppColors.primary;
      case 1:
        return AppColors.teal;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Maps icon identifiers from the analysis engine to actual Flutter Icons.
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'wb_sunny':
        return Icons.wb_sunny_outlined;
      case 'thunderstorm':
        return Icons.thunderstorm_outlined;
      case 'ac_unit':
        return Icons.ac_unit_outlined;
      case 'thermostat':
        return Icons.thermostat_outlined;
      case 'eco':
        return Icons.eco_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
