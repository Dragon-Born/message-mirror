import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel('msg_mirror_perm');

  static Future<bool> hasNotificationAccess() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod('hasNotificationAccess') as bool;
  }

  static Future<void> openNotificationAccess() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('openNotificationAccess');
  }

  static Future<bool> hasPostNotifications() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod('hasPostNotifications') as bool;
  }

  static Future<void> openNotificationSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('openNotificationSettings');
  }

  static Future<bool> hasReadSms() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod('hasReadSms') as bool;
  }

  static Future<void> openAppDetails() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('openAppDetails');
  }

  static Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod('isIgnoringBatteryOptimizations') as bool;
  }

  static Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('openBatterySettings');
  }

  // Data Saver helpers
  // Android returns:
  // 1 = RESTRICT_BACKGROUND_STATUS_DISABLED (Data Saver OFF)
  // 2 = RESTRICT_BACKGROUND_STATUS_WHITELISTED (Data Saver ON, app whitelisted)
  // 3 = RESTRICT_BACKGROUND_STATUS_ENABLED (Data Saver ON, app NOT whitelisted)
  static Future<int> getDataSaverStatus() async {
    if (!Platform.isAndroid) return 3;
    return await _channel.invokeMethod('getDataSaverStatus') as int;
  }

  static Future<void> openDataSaverSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('openDataSaverSettings');
  }

  static Future<bool> requestPostNotifications() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestReadSms() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.sms.request();
    return status.isGranted;
  }
}
