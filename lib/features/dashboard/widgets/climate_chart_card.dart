/// Climate overview chart card for SkyWhisper.
///
/// Renders a 30-day climate line chart using [fl_chart] with a
/// gradient-filled area beneath the curve. Includes a title,
/// subtitle, and a simple three-dot page indicator at the bottom to
/// hint at horizontal pagination between chart data sets.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_styles.dart';

/// Displays the "Climate – Past 30 days Overview" card.
///
/// The chart data is currently hardcoded to match the design
/// reference image. In a production build this would be driven by
/// a view-model or stream of sensor history data.
class ClimateChartCard extends StatelessWidget {
  /// Creates a [ClimateChartCard].
  const ClimateChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Card heading.
          Text('Climate', style: AppStyles.sectionTitle),
          SizedBox(height: 4.h),
          Text('Past 30 days Overview', style: AppStyles.sectionSubtitle),
          SizedBox(height: 24.h),

          /// The actual line chart.
          SizedBox(
            height: 180.h,
            child: LineChart(_buildChartData()),
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

  /// Builds the [LineChartData] configuration for the climate chart.
  ///
  /// Key settings:
  /// - X-axis represents days 1–30.
  /// - Y-axis is hidden; grid lines are faint vertical dashes.
  /// - The area beneath the curve is filled with a vertical blue
  ///   gradient that fades to transparent.
  /// - Touch interactions are disabled for a static presentation.
  LineChartData _buildChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: false,
        verticalInterval: 10,
        getDrawingVerticalLine: (value) => FlLine(
          color: AppColors.border,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 10,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const SizedBox.shrink();
              return Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  value.toInt().toString(),
                  style: AppStyles.caption,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 35,
      minY: 0,
      maxY: 100,
      lineTouchData: const LineTouchData(enabled: false),
      lineBarsData: [
        LineChartBarData(
          spots: _sampleSpots,
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

  /// Hardcoded sample data points that approximate the curve shown
  /// in the SkyWhisper design reference image.
  static final List<FlSpot> _sampleSpots = const [
    FlSpot(1, 20),
    FlSpot(3, 18),
    FlSpot(5, 22),
    FlSpot(8, 30),
    FlSpot(10, 45),
    FlSpot(12, 42),
    FlSpot(15, 48),
    FlSpot(18, 50),
    FlSpot(20, 47),
    FlSpot(22, 52),
    FlSpot(25, 55),
    FlSpot(28, 53),
    FlSpot(30, 60),
    FlSpot(32, 68),
    FlSpot(35, 80),
  ];
}
