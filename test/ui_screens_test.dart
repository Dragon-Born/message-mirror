import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:message_mirror/logs_screen.dart';
import 'package:message_mirror/payload_template_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Clear any previous mock handlers
    const MethodChannel('msg_mirror_ctrl').setMockMethodCallHandler(null);
    const MethodChannel('msg_mirror_prefs').setMockMethodCallHandler(null);
    const MethodChannel('msg_mirror_logs').setMockMethodCallHandler(null);
  });

  testWidgets('QueueScreen Force Retry invokes platform channel', (tester) async {
    String? invokedMethod;
    const MethodChannel('msg_mirror_ctrl').setMockMethodCallHandler((call) async { invokedMethod = call.method; return null; });
    const MethodChannel('msg_mirror_prefs').setMockMethodCallHandler((call) async {
      if (call.method == 'getRetryQueue') return jsonEncode(<Map<String, dynamic>>[]);
      return null;
    });

    await tester.pumpWidget(MaterialApp(home: const QueueScreen()));
    await tester.pumpAndSettle();

    final btn = find.byTooltip('Force Retry');
    expect(btn, findsOneWidget);
    await tester.tap(btn);
    await tester.pump();
    expect(invokedMethod, 'forceFlushRetry');
  });

  testWidgets('PayloadTemplateScreen saves valid JSON', (tester) async {
    String? savedTemplate;
    const MethodChannel('msg_mirror_prefs').setMockMethodCallHandler((call) async {
      if (call.method == 'getPayloadTemplate') {
        return '';
      }
      if (call.method == 'setPayloadTemplate') {
        savedTemplate = call.arguments as String?;
        return null;
      }
      return null;
    });

    await tester.pumpWidget(MaterialApp(home: const PayloadTemplateScreen()));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    const tpl = '{"message_body":"{{body}}","message_from":"{{from}}"}';
    await tester.enterText(field, tpl);
    await tester.pump();

    final save = find.text('Save');
    expect(save, findsWidgets);
    await tester.tap(save.first);
    await tester.pump();

    expect(savedTemplate, tpl);
  });

  testWidgets('LogsScreen auto-refresh toggles on', (tester) async {
    // Provide some logs so the header (with Live chip) renders
    const MethodChannel('msg_mirror_logs').setMockMethodCallHandler((call) async {
      if (call.method == 'read') return '2025-01-01 D log entry';
      return null;
    });
    await tester.pumpWidget(MaterialApp(home: const LogsScreen()));
    await tester.pumpAndSettle();

    // Toggle auto-refresh on
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Expect switch is ON
    final sw = tester.widget<Switch>(switchFinder);
    expect(sw.value, isTrue);
  });
}


