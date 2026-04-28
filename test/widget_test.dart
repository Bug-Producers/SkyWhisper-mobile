/// Basic widget test for the SkyWhisper application.
///
/// Verifies that the [SkyWhisperApp] widget tree can be built and
/// that the dashboard screen renders the "SKYWHISPER" brand title.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_whisper/main.dart';

void main() {
  testWidgets('Dashboard renders brand title', (WidgetTester tester) async {
    await tester.pumpWidget(const SkyWhisperApp());
    expect(find.text('SKYWHISPER'), findsOneWidget);
  });
}
