/// Entry point for the SkyWhisper mobile application.
///
/// Initializes [ScreenUtil] with the iPhone-14 design dimensions
/// (390 × 844) and sets up the [MaterialApp] with the dashboard
/// screen as the home route. The design-size values ensure that all
/// `.w`, `.h`, `.sp`, and `.r` extensions produce pixel-perfect
/// results when previewed on the reference device.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'features/dashboard/view/dashboard_screen.dart';

/// Application bootstrap — called by the Flutter engine.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkyWhisperApp());
}

/// Root widget of the SkyWhisper application.
///
/// Wraps the widget tree in [ScreenUtilInit] to enable responsive
/// sizing throughout all descendant widgets. The [designSize]
/// matches the reference Figma frame (390 × 844 logical pixels).
class SkyWhisperApp extends StatelessWidget {
  /// Creates the [SkyWhisperApp] root widget.
  const SkyWhisperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'SkyWhisper',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF4F7FB),
          ),

          /// Wraps the home screen in an [AnnotatedRegion] to
          /// declaratively apply dark status-bar icons.
          home: const AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
            child: DashboardScreen(),
          ),
        );
      },
    );
  }
}
