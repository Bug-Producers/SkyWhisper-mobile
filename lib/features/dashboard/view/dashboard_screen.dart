/**
 * The primary view of the SkyWhisper application.
 * 
 * This screen acts as the "Command Center," bringing together all our sensor 
 * widgets into a clean, scrollable interface. It's designed to feel like a 
 * premium dashboard, with live status updates at the top and deep historical 
 * insights at the bottom.
 * 
 * We use a vertical stack of cards to organize information:
 * 1. A visual brand header.
 * 2. A live connectivity status bar.
 * 3. Individual gauges for Temperature and Humidity.
 * 4. A specialized card for Barometric Pressure.
 * 5. A historical trend chart.
 * 6. An AI-powered weather insights panel.
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/providers/reading_scheduler_provider.dart';
import '../../../core/providers/sensor_providers.dart';
import '../../../core/services/sensor_ws_service.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/climate_chart_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/live_status_bar.dart';
import '../widgets/pressure_card.dart';
import '../widgets/sensor_card.dart';
import '../widgets/weather_insights_card.dart';
class DashboardScreen extends ConsumerStatefulWidget {
  /// Creates the [DashboardScreen] entry point.
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    /**
     * We wait for the first frame to render before starting our heavy lifting.
     * This ensures the app feels snappy and doesn't "stutter" during startup.
     */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      /**
       * First, we make sure our database is ready. 
       * We force a one-time data reset here to ensure the latest realistic 
       * weather patterns are applied to your dashboard.
       */
      final db = ref.read(databaseProvider);
      db.clearAllData().then((_) {
        ref.read(databaseInitProvider.future);
      });

      /**
       * Next, we fire up the "Background Guard." 
       * This scheduler ensures that even when you aren't looking at the screen, 
       * the app is quietly saving data every 4 hours for your history charts.
       */
      ref.read(readingSchedulerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    /// We watch the live sensor stream. Every 5 seconds when the ESP32
    /// sends a message, this whole UI refreshes automatically.
    final sensorAsync = ref.watch(sensorStreamProvider);

    /// We also track the connection status to show you if the station is 
    /// online, offline, or trying to reconnect.
    final statusAsync = ref.watch(connectionStatusProvider);
    final connectionStatus =
        statusAsync.valueOrNull ?? ConnectionStatus.disconnected;

    /// We extract the raw values. If we don't have data yet, we use null 
    /// so the widgets can show their "empty" state (--) gracefully.
    final temperature = sensorAsync.valueOrNull?.temperature;
    final humidity = sensorAsync.valueOrNull?.humidity;
    final pressure = sensorAsync.valueOrNull?.pressure;

    /**
     * Error Monitoring:
     * If something goes wrong with the sensor stream, we'll pop up a 
     * friendly notification at the bottom so you aren't left wondering why.
     */
    ref.listen(sensorStreamProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Heads up: We had trouble reaching the sensors. (${next.error})'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(bottom: 32.h),
            child: Column(
              children: [
                /// The brand identity header.
                const DashboardHeader(),
                SizedBox(height: 12.h),

                /// The real-time connectivity pill.
                LiveStatusBar(
                  status: connectionStatus,
                  lastReading: sensorAsync.valueOrNull,
                ),
                SizedBox(height: 20.h),

                /**
                 * Gauge Section:
                 * We place the two most important metrics side-by-side for 
                 * quick comparison.
                 */
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      /// Temperature Gauge.
                      Expanded(
                        child: SensorCard(
                          icon: Icons.thermostat_outlined,
                          value: temperature != null
                              ? temperature.toStringAsFixed(0)
                              : '--',
                          unit: '°',
                          label: 'TEMPERATURE',
                          progress: temperature != null
                              ? (temperature / 50).clamp(0.0, 1.0)
                              : 0.0,
                          ringColor: AppColors.primaryDark,
                        ),
                      ),
                      SizedBox(width: 16.w),

                      /// Humidity Gauge.
                      Expanded(
                        child: SensorCard(
                          icon: Icons.water_drop_outlined,
                          value: humidity != null
                              ? humidity.toStringAsFixed(0)
                              : '--',
                          unit: '%',
                          label: 'HUMIDITY',
                          progress: humidity != null
                              ? (humidity / 100).clamp(0.0, 1.0)
                              : 0.0,
                          ringColor: AppColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                /// The Atmospheric Pressure card takes up the full width for clarity.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: PressureCard(
                    pressure: pressure,
                  ),
                ),
                SizedBox(height: 16.h),

                /// The Climate Chart visualizes how your environment has changed over time.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: const ClimateChartCard(),
                ),
                SizedBox(height: 16.h),

                /// The Insights Card uses AI logic to spot patterns like heatwaves or storms.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: const WeatherInsightsCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
