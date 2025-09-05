import 'dart:io';
import 'package:flutter/services.dart';

class PlatformControls {
  static const MethodChannel _channel = MethodChannel('msg_mirror_ctrl');

  static Future<void> startService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startService');
    } catch (_) {}
  }

  static Future<void> stopService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}
  }

  static Future<bool> isServiceRunning() async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod('isServiceRunning');
      return res == true;
    } catch (_) {
      return false;
    }
  }
}
