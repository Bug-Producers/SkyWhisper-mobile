/// Main dashboard screen for the SkyWhisper application.
///
/// Assembles all dashboard widgets into a single scrollable view.
/// The layout follows a vertical card-stack pattern common in modern
/// weather and IoT sensor apps: a top header, a live-status bar,
/// side-by-side sensor gauges, a full-width pressure card, and a
/// climate trend chart at the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/climate_chart_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/live_status_bar.dart';
import '../widgets/pressure_card.dart';
import '../widgets/sensor_card.dart';

/// The root screen of the dashboard feature.
///
/// Uses a [SafeArea] and [SingleChildScrollView] so the content is
/// fully visible on devices of all sizes without overflow. Each
/// section is separated by vertical spacing sized with [ScreenUtil].
class DashboardScreen extends StatelessWidget {
  /// Creates a [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(bottom: 32.h),
            child: Column(
              children: [
                /// App brand header.
                const DashboardHeader(),
                SizedBox(height: 12.h),

                /// Live indicator + timestamp row.
                const LiveStatusBar(),
                SizedBox(height: 20.h),

                /// Temperature and Humidity gauges side by side.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      /// Temperature sensor card — blue ring at ~66 %.
                      Expanded(
                        child: SensorCard(
                          icon: Icons.thermostat_outlined,
                          value: '24',
                          unit: '°',
                          label: 'TEMPERATURE',
                          progress: 0.66,
                          ringColor: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(width: 16.w),

                      /// Humidity sensor card — teal ring at ~45 %.
                      Expanded(
                        child: SensorCard(
                          icon: Icons.water_drop_outlined,
                          value: '45',
                          unit: '%',
                          label: 'HUMIDITY',
                          progress: 0.45,
                          ringColor: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                /// Atmospheric pressure full-width card.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: const PressureCard(),
                ),
                SizedBox(height: 16.h),

                /// Climate trend chart card.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: const ClimateChartCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
