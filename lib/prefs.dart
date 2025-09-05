import 'package:flutter/services.dart';
import 'dart:convert';

class Prefs {
  static const MethodChannel _channel = MethodChannel('msg_mirror_prefs');

  static Future<String> getReception() async {
    try {
      final res = await _channel.invokeMethod('getReception');
      return (res ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static Future<void> setReception(String value) async {
    try {
      await _channel.invokeMethod('setReception', value);
    } catch (_) {}
  }

  static Future<String> getEndpoint() async {
    try {
      final res = await _channel.invokeMethod('getEndpoint');
      return (res ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static Future<void> setEndpoint(String value) async {
    try {
      await _channel.invokeMethod('setEndpoint', value);
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> getRetryQueue() async {
    try {
      final res = await _channel.invokeMethod('getRetryQueue');
      final String json = (res ?? '[]').toString();
      final list = (jsonDecode(json) as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> setRetryQueue(List<Map<String, dynamic>> items) async {
    try {
      final json = jsonEncode(items);
      await _channel.invokeMethod('setRetryQueue', json);
    } catch (_) {}
  }

  static Future<String> getPayloadTemplate() async {
    try {
      final res = await _channel.invokeMethod('getPayloadTemplate');
      return (res ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  static Future<void> setPayloadTemplate(String value) async {
    try {
      await _channel.invokeMethod('setPayloadTemplate', value);
    } catch (_) {}
  }
}
