import 'dart:io';
import 'package:flutter/services.dart';

class Logger {
  static const MethodChannel _channel = MethodChannel('msg_mirror_logs');

  static Future<void> d(String msg) async {
    await _append('D', msg);
  }

  static Future<void> e(String msg) async {
    await _append('E', msg);
  }

  static Future<void> _append(String level, String msg) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('append', '[$level] $msg');
    } catch (_) {}
  }

  static Future<String> read() async {
    if (!Platform.isAndroid) return '';
    try {
      final res = await _channel.invokeMethod('read');
      return (res ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static Future<void> clear() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('clear');
    } catch (_) {}
  }
}
