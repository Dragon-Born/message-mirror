import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:message_mirror/logger.dart';
import 'package:message_mirror/prefs.dart';
import 'package:message_mirror/template_renderer.dart';

abstract class RetryQueueStore {
  Future<List<Map<String, dynamic>>> get();
  Future<void> set(List<Map<String, dynamic>> items);
}

class PrefsRetryQueueStore implements RetryQueueStore {
  @override
  Future<List<Map<String, dynamic>>> get() => Prefs.getRetryQueue();

  @override
  Future<void> set(List<Map<String, dynamic>> items) => Prefs.setRetryQueue(items);
}

class MessageStream {
  static const MethodChannel _channel = MethodChannel('msg_mirror');

  String reception;
  String endpoint = '';
  String? payloadTemplate; // User-defined JSON template
  final Set<String> _recentKeys = <String>{};
  final List<String> _recentOrder = <String>[];
  static const int _recentCap = 300;
  // Minimal retry queue with exponential backoff
  final List<Map<String, dynamic>> _retryQueue = <Map<String, dynamic>>[];
  int _backoffMs = 2000;
  static const int _maxBackoffMs = 60000;
  Timer? _retryTimer;
  static const int _retryCap = 50;
  final http.Client _http;
  final RetryQueueStore _queueStore;

  MessageStream({required this.reception, String? endpoint, http.Client? httpClient, RetryQueueStore? queueStore})
      : _http = httpClient ?? http.Client(),
        _queueStore = queueStore ?? PrefsRetryQueueStore() {
    if (endpoint != null && endpoint.isNotEmpty) {
      this.endpoint = endpoint;
    }
  }

  void start() {
    _channel.setMethodCallHandler(_onNative);
    Logger.d('Dart handler registered (reception=${reception.isEmpty ? 'EMPTY' : 'SET'})');
    _restoreQueue();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      final tpl = await Prefs.getPayloadTemplate();
      if (tpl.trim().isNotEmpty) payloadTemplate = tpl;
    } catch (_) {}
  }

  Future<dynamic> _onNative(MethodCall call) async {
    try {
      await Logger.d('Native call: ${call.method}');
      switch (call.method) {
        case 'onNotification':
          final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
          await Logger.d('onNotification args: ' + args.toString());
          final payload = await _buildNotifPayload(args);
          if (payload != null) {
            await Logger.d('Sending notification payload: ${payload['message_from']}');
            final ok = await _sendToApi(payload);
            if (!ok) {
              _enqueueRetry(payload);
            }
          } else {
            await Logger.d('Notification payload skipped (group summary or empty)');
          }
          break;
        case 'onSms':
          final Map<dynamic, dynamic> args = call.arguments as Map<dynamic, dynamic>;
          await Logger.d('onSms args: ' + args.toString());
          final payload = _buildSmsPayload(args);
          if (payload != null) {
            await Logger.d('Sending SMS payload from ${payload['message_from']}');
            final ok = await _sendToApi(payload);
            if (!ok) {
              _enqueueRetry(payload);
            }
          } else {
            await Logger.d('SMS payload skipped (empty body)');
          }
          break;
        case 'forceRetry':
          await Logger.d('Force retry requested');
          await _flushRetryQueue(force: true);
          break;
      }
    } catch (err) {
      await Logger.e('Handler error: $err');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _buildNotifPayload(Map<dynamic, dynamic> m) async {
    final String app = (m['app'] ?? '').toString();
    final String title = (m['title'] ?? '').toString();
    final String text = (m['text'] ?? '').toString().trim();
    final bool isGroupSummary = (m['isGroupSummary'] ?? false) == true;
    final int whenMs = (m['when'] is int) ? (m['when'] as int) : 0;
    final String subText = (m['subText'] ?? '').toString();
    final String summaryText = (m['summaryText'] ?? '').toString();
    final String bigText = (m['bigText'] ?? '').toString();
    final String infoText = (m['infoText'] ?? '').toString();
    final String people = (m['people'] ?? '').toString();
    final String largeIcon = (m['largeIcon'] ?? '').toString();
    final String picture = (m['picture'] ?? '').toString();
    final String category = (m['category'] ?? '').toString();
    final String priority = (m['priority'] ?? '').toString();
    final String channelId = (m['channelId'] ?? '').toString();
    final String actions = (m['actions'] ?? '').toString();
    final String groupKey = (m['groupKey'] ?? '').toString();
    final String visibility = (m['visibility'] ?? '').toString();
    final String color = (m['color'] ?? '').toString();
    final String badgeIconType = (m['badgeIconType'] ?? '').toString();
    // Skip obvious ongoing/background work notifications
    if (text.contains('doing work in the background')) {
      Logger.d('Skip background-work notification');
      return null;
    }
    // Only forward from allowed packages (persisted in prefs via native channel)
    final allowed = await _getAllowedPackages();
    if (allowed.isNotEmpty && !allowed.contains(app)) {
      Logger.d('Skip non-allowed app: $app');
      return null;
    }
    if (app == 'lol.arian.notifmirror') {
      Logger.d('Skip self notification');
      return null;
    }
    if (isGroupSummary) {
      Logger.d('Skip group summary');
      return null;
    }
    final String body = text.isNotEmpty ? text : title;
    if (body.isEmpty) {
      Logger.d('Skip notification with empty body');
      return null;
    }
    final key = _notifKey(app, whenMs);
    if (_isDuplicate(key)) {
      Logger.d('Skip duplicate notification key=$key');
      return null;
    }
    final dateStr = _formatDate(DateTime.fromMillisecondsSinceEpoch(whenMs == 0 ? DateTime.now().millisecondsSinceEpoch : whenMs));
    final extraValues = <String, String>{
      'title': title,
      'text': text,
      'when': whenMs.toString(),
      'isGroupSummary': isGroupSummary.toString(),
      'subText': subText,
      'summaryText': summaryText,
      'bigText': bigText,
      'infoText': infoText,
      'people': people,
      'largeIcon': largeIcon,
      'picture': picture,
      'category': category,
      'priority': priority,
      'channelId': channelId,
      'actions': actions,
      'groupKey': groupKey,
      'visibility': visibility,
      'color': color,
      'badgeIconType': badgeIconType,
    };
    final base = _renderPayload(
      from: title,
      body: body,
      date: dateStr,
      app: app,
      type: 'notification',
      extraValues: extraValues,
    );
    return base;
  }
  Future<Set<String>> _getAllowedPackages() async {
    try {
      const MethodChannel ch = MethodChannel('msg_mirror_prefs');
      final list = await ch.invokeMethod('getAllowedPackages') as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic>? _buildSmsPayload(Map<dynamic, dynamic> m) {
    final String from = (m['from'] ?? '').toString();
    final String body = (m['body'] ?? '').toString();
    final int dateMs = (m['date'] is int) ? (m['date'] as int) : 0;
    if (body.isEmpty) return null;
    final key = _smsKey(from, dateMs);
    if (_isDuplicate(key)) {
      Logger.d('Skip duplicate SMS key=$key');
      return null;
    }
    final dateStr = _formatDate(DateTime.fromMillisecondsSinceEpoch(dateMs == 0 ? DateTime.now().millisecondsSinceEpoch : dateMs));
    return _renderPayload(
      from: from,
      body: body,
      date: dateStr,
      app: 'sms',
      type: 'sms',
    );
  }

  Map<String, dynamic> _renderPayload({required String from, required String body, required String date, required String app, required String type, Map<String, String>? extraValues}) {
    final defaultPayload = <String, dynamic>{
      'message_body': body,
      'message_from': from,
      'message_date': date,
      'app': app,
      'type': type,
    };
    if (reception.isNotEmpty) defaultPayload['reception'] = reception;
    final tpl = payloadTemplate;
    if (tpl == null || tpl.trim().isEmpty) {
      return defaultPayload;
    }
    final values = <String, String>{
      'body': body,
      'from': from,
      'date': date,
      'app': app,
      'type': type,
      'reception': reception,
    };
    if (extraValues != null && extraValues.isNotEmpty) {
      values.addAll(extraValues);
    }
    final map = TemplateRenderer.render(tpl, values, fallback: defaultPayload);
    return map;
  }

  

  Future<bool> _sendToApi(Map<String, dynamic> payload) async {
    final uri = Uri.parse(endpoint);
    try {
      final resp = await _http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 12));
      await Logger.d('POST done: status=${resp.statusCode}, len=${resp.body.length}');
      if (resp.statusCode >= 400) {
        await Logger.e('POST error body: ${resp.body}');
        return false;
      }
      return true;
    } catch (err) {
      await Logger.e('POST failed: $err');
      return false;
    }
  }

  void _enqueueRetry(Map<String, dynamic> payload) {
    if (_retryQueue.length >= _retryCap) {
      _retryQueue.removeAt(0);
    }
    _retryQueue.add(payload);
    _persistQueue();
    _scheduleRetry();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(milliseconds: _backoffMs), _flushRetryQueue);
    Logger.d('Retry scheduled in ${_backoffMs}ms (queue=${_retryQueue.length})');
    _backoffMs = (_backoffMs * 2).clamp(2000, _maxBackoffMs);
  }

  Future<void> _flushRetryQueue({bool force = false}) async {
    if (_retryQueue.isEmpty) {
      _backoffMs = 2000;
      return;
    }
    await Logger.d('Retry flush start: size=${_retryQueue.length} force=$force');
    final current = List<Map<String, dynamic>>.from(_retryQueue);
    _retryQueue.clear();
    for (final payload in current) {
      final ok = await _sendToApi(payload);
      if (!ok) {
        _retryQueue.add(payload);
        if (!force) {
          // Stop early on first failure in normal mode to respect backoff pacing
          break;
        }
      }
    }
    await _persistQueue();
    await Logger.d('Retry flush done: remaining=${_retryQueue.length}');
    if (_retryQueue.isNotEmpty) {
      if (force) {
        // On force, schedule next attempt with minimal backoff
        _backoffMs = 2000;
      }
      _scheduleRetry();
    } else {
      _backoffMs = 2000;
    }
  }

  Future<void> _persistQueue() async {
    try {
      await _queueStore.set(_retryQueue);
    } catch (_) {}
  }

  Future<void> _restoreQueue() async {
    try {
      final items = await _queueStore.get();
      _retryQueue.clear();
      _retryQueue.addAll(items);
      if (_retryQueue.isNotEmpty) {
        _scheduleRetry();
      }
    } catch (_) {}
  }

  String _notifKey(String app, int whenMs) => '$app|$whenMs';
  String _smsKey(String from, int dateMs) => 'sms|$from|$dateMs';

  bool _isDuplicate(String key) {
    if (_recentKeys.contains(key)) return true;
    _recentKeys.add(key);
    _recentOrder.add(key);
    if (_recentOrder.length > _recentCap) {
      final old = _recentOrder.removeAt(0);
      _recentKeys.remove(old);
    }
    return false;
  }
  String _formatDate(DateTime dt) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    final y = dt.year.toString().padLeft(4, '0');
    final mo = two(dt.month);
    final d = two(dt.day);
    final h = two(dt.hour);
    final mi = two(dt.minute);
    return '$y-$mo-$d $h:$mi';
  }

  // Test helpers
  List<Map<String, dynamic>> debugGetQueue() => List<Map<String, dynamic>>.from(_retryQueue);
  int debugGetBackoffMs() => _backoffMs;
  Future<void> debugFlushRetryQueue({bool force = false}) => _flushRetryQueue(force: force);
  void debugEnqueueRetry(Map<String, dynamic> payload) => _enqueueRetry(payload);
  void dispose() { _retryTimer?.cancel(); }

  Future<void> debugProcessSms(Map<String, dynamic> args) async {
    final payload = _buildSmsPayload(args);
    if (payload != null) {
      final ok = await _sendToApi(payload);
      if (!ok) {
        _enqueueRetry(payload);
      }
    }
  }

  Future<void> debugProcessNotification(Map<String, dynamic> args) async {
    final payload = await _buildNotifPayload(args);
    if (payload != null) {
      final ok = await _sendToApi(payload);
      if (!ok) {
        _enqueueRetry(payload);
      }
    }
  }
}
