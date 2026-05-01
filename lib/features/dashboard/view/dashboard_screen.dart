/// Main dashboard screen for the SkyWhisper application.
///
/// Assembles all dashboard widgets into a single scrollable view.
/// The layout follows a vertical card-stack pattern common in modern
/// weather and IoT sensor apps: a top header, a live-status bar,
/// side-by-side sensor gauges, a full-width pressure card, and a
/// climate trend chart at the bottom.
///
/// This screen is a [ConsumerStatefulWidget] that watches Riverpod
/// providers for live sensor data, connection status, and historical
/// averages. It initializes the database, seeds fake data on first
/// launch, and activates the background reading scheduler.
library;

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

/// The root screen of the dashboard feature.
///
/// Uses [ConsumerStatefulWidget] to interact with Riverpod providers.
/// On initialization, it:
/// 1. Initializes the SQLite database.
/// 2. Seeds fake historical data (first launch only).
/// 3. Activates the 4-hour background reading scheduler.
/// 4. Connects to the ESP32 WebSocket for live data streaming.
class DashboardScreen extends ConsumerStatefulWidget {
  /// Creates a [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    /// Schedule provider initialization after the first frame to
    /// avoid modifying provider state during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      /// Initialize database and seed fake data.
      ref.read(databaseInitProvider.future);

      /// Activate the background scheduler for 4-hour saves.
      ref.read(readingSchedulerProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Watch the live sensor stream for real-time updates.
    final sensorAsync = ref.watch(sensorStreamProvider);

    /// Watch connection status for the live indicator.
    final statusAsync = ref.watch(connectionStatusProvider);

    /// Resolve the current connection status, defaulting to disconnected.
    final connectionStatus =
        statusAsync.valueOrNull ?? ConnectionStatus.disconnected;

    /// Extract the latest reading values with sensible defaults.
    /// When no live data is available, show dashes or fallback values.
    final temperature = sensorAsync.valueOrNull?.temperature;
    final humidity = sensorAsync.valueOrNull?.humidity;
    final pressure = sensorAsync.valueOrNull?.pressure;

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
                LiveStatusBar(
                  status: connectionStatus,
                  lastReading: sensorAsync.valueOrNull,
                ),
                SizedBox(height: 20.h),

                /// Temperature and Humidity gauges side by side.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      /// Temperature sensor card — dynamic value.
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

                      /// Humidity sensor card — dynamic value.
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

                /// Atmospheric pressure full-width card.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: PressureCard(
                    pressure: pressure,
                  ),
                ),
                SizedBox(height: 16.h),

                /// Climate trend chart card (from SQLite daily averages).
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
