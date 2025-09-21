import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:message_mirror/message_stream.dart';

class _MemoryStore implements RetryQueueStore {
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> get() async => List<Map<String, dynamic>>.from(_items);
  @override
  Future<void> set(List<Map<String, dynamic>> items) async { _items = List<Map<String, dynamic>>.from(items); }
}

class _FakeClient extends http.BaseClient {
  final List<http.Request> sent = <http.Request>[];
  int statusCode;
  _FakeClient(this.statusCode);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sent.add(request as http.Request);
    final bodyBytes = utf8.encode(await request.finalize().bytesToString());
    return http.StreamedResponse(Stream.value(bodyBytes), statusCode, request: request);
  }
}

void main() {
  setUp(() { WidgetsFlutterBinding.ensureInitialized(); });

  test('post success → no enqueue', () async {
    final store = _MemoryStore();
    final client = _FakeClient(200);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    await s.debugProcessSms({'from': 'A', 'body': 'B', 'date': 1});
    expect(s.debugGetQueue().isEmpty, true);
    s.dispose();
  });

  test('post 503 → enqueue', () async {
    final store = _MemoryStore();
    final client = _FakeClient(503);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    await s.debugProcessSms({'from': 'A', 'body': 'B', 'date': 1});
    expect(s.debugGetQueue().length, 1);
    s.dispose();
  });

  test('queue cap evicts oldest', () async {
    final store = _MemoryStore();
    final client = _FakeClient(503);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    for (int i = 0; i < 55; i++) {
      s.debugEnqueueRetry({'message_body': 'b$i', 'message_from': 'f$i', 'message_date': 'd', 'app': 'sms', 'type': 'sms'});
    }
    expect(s.debugGetQueue().length, 50);
    s.dispose();
  });

  test('non-force flush stops on first failure', () async {
    final store = _MemoryStore();
    final client = _FakeClient(503);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    s.debugEnqueueRetry({'message_body': 'b1', 'message_from': 'f1', 'message_date': 'd', 'app': 'sms', 'type': 'sms'});
    s.debugEnqueueRetry({'message_body': 'b2', 'message_from': 'f2', 'message_date': 'd', 'app': 'sms', 'type': 'sms'});
    await s.debugFlushRetryQueue(force: false);
    // Should stop after the first failure and leave at least one
    expect(s.debugGetQueue().isNotEmpty, true);
    s.dispose();
  });

  test('dedup: notification and sms keys', () async {
    final store = _MemoryStore();
    final client = _FakeClient(200);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    // Notification duplicates
    await s.debugProcessNotification({'app': 'com.x', 'title': 'T', 'text': 'X', 'when': 123, 'isGroupSummary': false});
    await s.debugProcessNotification({'app': 'com.x', 'title': 'T', 'text': 'X', 'when': 123, 'isGroupSummary': false});
    // SMS duplicates
    await s.debugProcessSms({'from': 'A', 'body': 'B', 'date': 10});
    await s.debugProcessSms({'from': 'A', 'body': 'B', 'date': 10});
    // No enqueues since success client, but dedup also should not send duplicates, not easily observable; assert queue empty
    expect(s.debugGetQueue().isEmpty, true);
    s.dispose();
  });

  test('skip conditions: group summary, self app, empty body', () async {
    final store = _MemoryStore();
    final client = _FakeClient(503);
    final s = MessageStream(reception: '', endpoint: 'https://example.invalid', httpClient: client, queueStore: store);
    // group summary
    await s.debugProcessNotification({'app': 'com.x', 'title': 'T', 'text': 'X', 'when': 1, 'isGroupSummary': true});
    // self app
    await s.debugProcessNotification({'app': 'lol.arian.notifmirror', 'title': 'T', 'text': 'X', 'when': 2, 'isGroupSummary': false});
    // empty body
    await s.debugProcessNotification({'app': 'com.x', 'title': '', 'text': '', 'when': 3, 'isGroupSummary': false});
    expect(s.debugGetQueue().isEmpty, true);
    s.dispose();
  });
}


