import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:message_mirror/message_stream.dart';

class _FakeClient extends http.BaseClient {
  bool succeed;
  _FakeClient({required this.succeed});
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bodyBytes = utf8.encode(await (request as http.Request).finalize().bytesToString());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (succeed) {
      return http.StreamedResponse(Stream.value(bodyBytes), 200, request: request);
    }
    return http.StreamedResponse(Stream.value(bodyBytes), 503, request: request);
  }
}

class _MemoryStore implements RetryQueueStore {
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> get() async => List<Map<String, dynamic>>.from(_items);
  @override
  Future<void> set(List<Map<String, dynamic>> items) async { _items = List<Map<String, dynamic>>.from(items); }
}

Map<String, dynamic> _payload(int i) => {
  'message_body': 'b$i',
  'message_from': 'f$i',
  'message_date': '2025-09-21 10:0$i',
  'app': 'sms',
  'type': 'sms',
};

void main() {
  test('enqueue and backoff increase', () async {
    final store = _MemoryStore();
    final client = _FakeClient(succeed: false);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    // enqueue two payloads
    s.debugEnqueueRetry(_payload(1));
    expect(s.debugGetQueue().length, 1);
    final b1 = s.debugGetBackoffMs();
    s.debugEnqueueRetry(_payload(2));
    final b2 = s.debugGetBackoffMs();
    expect(b2, greaterThanOrEqualTo(b1));
    s.dispose();
  });

  test('restore on start schedules retry', () async {
    WidgetsFlutterBinding.ensureInitialized();
    final store = _MemoryStore();
    await store.set([_payload(1)]);
    final client = _FakeClient(succeed: false);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    s.start();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(s.debugGetQueue().length, 1);
    s.dispose();
  });

  test('force flush drains when server recovers', () async {
    WidgetsFlutterBinding.ensureInitialized();
    final store = _MemoryStore();
    final client = _FakeClient(succeed: false);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    s.debugEnqueueRetry(_payload(1));
    s.debugEnqueueRetry(_payload(2));
    expect(s.debugGetQueue().length, 2);
    // still failing; flush force keeps them in queue
    await s.debugFlushRetryQueue(force: true);
    expect(s.debugGetQueue().length, 2);
    // server recovers
    client.succeed = true;
    await s.debugFlushRetryQueue(force: true);
    expect(s.debugGetQueue().isEmpty, true);
    // backoff reset after empty
    expect(s.debugGetBackoffMs(), 2000);
    s.dispose();
  });

  test('backoff doubles and caps at 60000ms', () async {
    final store = _MemoryStore();
    final client = _FakeClient(succeed: false);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    int last = s.debugGetBackoffMs();
    // Schedule many times to exceed cap
    for (int i = 0; i < 10; i++) {
      s.debugEnqueueRetry(_payload(i));
      final b = s.debugGetBackoffMs();
      expect(b >= last, true);
      last = b;
    }
    expect(last <= 60000, true);
    s.dispose();
  });
}


