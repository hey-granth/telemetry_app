// Widget tests for Telemetry Client

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:telemetry_client/main.dart';

void main() {
  testWidgets('App initializes and shows landing screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TelemetryApp()));

    // Wait for initialization
    await tester.pumpAndSettle();

    // Verify app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
