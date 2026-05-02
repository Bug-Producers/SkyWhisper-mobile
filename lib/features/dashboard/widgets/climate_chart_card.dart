/// Climate overview chart card for SkyWhisper.
///
/// Renders a historical climate line chart using [fl_chart] with a
/// gradient-filled area beneath the curve. Data is sourced from
/// the SQLite database via the [dailyAveragesProvider], showing
/// daily averaged temperature readings from April 1 to May 2.
///
/// Includes a title, subtitle, and a three-dot page indicator
/// for potential future metric switching (temp / humidity / pressure).
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/data/models/daily_average.dart';
import '../../../core/providers/sensor_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';
import '../../../core/widgets/app_error_widget.dart';

/// Displays the "Climate – Daily Averages" chart card.
///
/// Uses a [ConsumerWidget] to watch the [dailyAveragesProvider]
/// and reactively render chart data from the SQLite database.
/// Shows a loading spinner while data is being fetched, and an
/// error message if the query fails.
class ClimateChartCard extends ConsumerWidget {
  /// Creates a [ClimateChartCard].
  const ClimateChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// Watch the daily averages provider for chart data.
    final averagesAsync = ref.watch(dailyAveragesProvider);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Card heading.
          Text('Climate', style: AppStyles.sectionTitle),
          SizedBox(height: 4.h),
          Text('Apr 1 – May 2 Daily Averages', style: AppStyles.sectionSubtitle),
          SizedBox(height: 24.h),

          /// The chart area — handles loading, error, and data states.
          SizedBox(
            height: 180.h,
            child: averagesAsync.when(
              /// ── Data loaded: render the line chart ──
              data: (averages) {
                if (averages.isEmpty) {
                  return Center(
                    child: Text(
                      'No historical data available',
                      style: AppStyles.caption,
                    ),
                  );
                }
                return LineChart(_buildChartData(averages));
              },

              /// ── Loading: show a subtle spinner ──
              loading: () => Center(
                child: SizedBox(
                  width: 32.w,
                  height: 32.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),

              /// ── Error: show user-friendly message ──
              error: (error, _) => AppErrorWidget(
                message: 'Unable to load chart data',
                onRetry: () => ref.invalidate(dailyAveragesProvider),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          /// Three-dot page indicator centered at the bottom.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isActive = index == 0;
              return Container(
                width: isActive ? 20.w : 6.w,
                height: 6.w,
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.ringTrack,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ───────────────────── Chart Configuration ─────────────────────

  /// Builds the [LineChartData] from the list of [DailyAverage].
  ///
  /// Each day is mapped to an X position (0-based day index) and
  /// the Y value is the daily average temperature. The chart is
  /// configured with:
  /// - X-axis: date labels at 7-day intervals.
  /// - Y-axis: hidden for a clean look.
  /// - Smooth curved line with gradient area fill.
  /// - Touch disabled for static presentation.
  LineChartData _buildChartData(List<DailyAverage> averages) {
    /// Convert daily averages to chart data points.
    final spots = averages.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.avgTemperature,
      );
    }).toList();

    /// Calculate Y-axis bounds with padding.
    final minTemp = averages
        .map((a) => a.avgTemperature)
        .reduce((a, b) => a < b ? a : b);
    final maxTemp = averages
        .map((a) => a.avgTemperature)
        .reduce((a, b) => a > b ? a : b);
    final yPadding = (maxTemp - minTemp) * 0.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: false,
        verticalInterval: 7,
        getDrawingVerticalLine: (value) => FlLine(
          color: AppColors.border,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 7,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= averages.length) {
                return const SizedBox.shrink();
              }

              /// Format date as "Apr 8", "Apr 15", etc.
              final date = averages[index].date;
              final label = DateFormat('MMM d').format(date);

              return Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(label, style: AppStyles.caption),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (averages.length - 1).toDouble(),
      minY: minTemp - yPadding,
      maxY: maxTemp + yPadding,
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.chartLine,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.chartGradientStart,
                AppColors.chartGradientEnd,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
