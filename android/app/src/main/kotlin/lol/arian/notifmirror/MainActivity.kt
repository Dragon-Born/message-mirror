package lol.arian.notifmirror

import android.content.Intent
import android.os.Bundle
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.app.NotificationManager
import android.os.PowerManager
import android.net.ConnectivityManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.LruCache
import kotlin.concurrent.thread
import java.io.ByteArrayOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "msg_mirror_ctrl"
    private val prefsChannelName = "msg_mirror_prefs"
    private val permChannelName = "msg_mirror_perm"
    private val logsChannelName = "msg_mirror_logs"
    private val appsChannelName = "msg_mirror_apps"

    // In-memory icon cache to avoid repeated decoding/compression
    private val iconCache = LruCache<String, ByteArray>(200)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val intent = Intent(this, AlwaysOnService::class.java)
                        startForegroundService(intent)
                        result.success(null)
                    }
                    "stopService" -> {
                        val intent = Intent(this, AlwaysOnService::class.java)
                        stopService(intent)
                        // Proactively reflect stopped state for faster UI feedback
                        try {
                            val p = getSharedPreferences("msg_mirror", Context.MODE_PRIVATE)
                            p.edit().putBoolean("service_running", false).apply()
                        } catch (_: Exception) {}
                        result.success(null)
                    }
                    "isServiceRunning" -> {
                        val p = getSharedPreferences("msg_mirror", Context.MODE_PRIVATE)
                        result.success(p.getBoolean("service_running", false))
                    }
                    "forceFlushRetry" -> {
                        // Relay a 'forceRetry' call to any active Flutter engines (UI and background)
                        runOnUiThread {
                            try {
                                io.flutter.embedding.engine.FlutterEngineCache.getInstance().get("ui_engine")?.let { eng ->
                                    MethodChannel(eng.dartExecutor.binaryMessenger, "msg_mirror").invokeMethod("forceRetry", null)
                                }
                            } catch (_: Exception) {}
                            try {
                                io.flutter.embedding.engine.FlutterEngineCache.getInstance().get("always_on_engine")?.let { eng ->
                                    MethodChannel(eng.dartExecutor.binaryMessenger, "msg_mirror").invokeMethod("forceRetry", null)
                                }
                            } catch (_: Exception) {}
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        val prefs = getSharedPreferences("msg_mirror", Context.MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, prefsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getReception" -> {
                        result.success(prefs.getString("reception", ""))
                    }
                    "setReception" -> {
                        val v = call.arguments as? String ?: ""
                        prefs.edit().putString("reception", v).apply()
                        result.success(null)
                    }
                    "getEndpoint" -> {
                        result.success(prefs.getString("endpoint", ""))
                    }
                    "setEndpoint" -> {
                        val v = call.arguments as? String ?: ""
                        prefs.edit().putString("endpoint", v).apply()
                        result.success(null)
                    }
                    "getSmsEnabled" -> {
                        result.success(prefs.getBoolean("sms_enabled", true))
                    }
                    "setSmsEnabled" -> {
                        val v = (call.arguments as? Boolean) ?: true
                        prefs.edit().putBoolean("sms_enabled", v).apply()
                        result.success(null)
                    }
                    "getAllowedPackages" -> {
                        val set = prefs.getStringSet("allowed_packages", setOf()) ?: setOf()
                        result.success(set.toList())
                    }
                    "setAllowedPackages" -> {
                        val list = (call.arguments as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
                        prefs.edit().putStringSet("allowed_packages", list.toSet()).apply()
                        result.success(null)
                    }
                    "getRetryQueue" -> {
                        result.success(prefs.getString("retry_queue", "[]"))
                    }
                    "setRetryQueue" -> {
                        val v = call.arguments as? String ?: "[]"
                        prefs.edit().putString("retry_queue", v).apply()
                        result.success(null)
                    }
                    "getPayloadTemplate" -> {
                        val def = (
                            """
                            {
                              "message_body": "{{body}}",
                              "message_from": "{{from}}",
                              "message_date": "{{date}}"
                            }
                            """
                        ).trimIndent()
                        result.success(prefs.getString("payload_template", def))
                    }
                    "setPayloadTemplate" -> {
                        val v = (call.arguments as? String) ?: ""
                        prefs.edit().putString("payload_template", v).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, permChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasNotificationAccess" -> result.success(hasNotificationAccess())
                    "openNotificationAccess" -> { openNotificationAccess(); result.success(null) }
                    "hasPostNotifications" -> result.success(hasPostNotifications())
                    "openNotificationSettings" -> { openAppNotificationSettings(); result.success(null) }
                    "hasReadSms" -> result.success(checkSelfPermission(android.Manifest.permission.READ_SMS) == android.content.pm.PackageManager.PERMISSION_GRANTED)
                    "openAppDetails" -> { openAppDetails(); result.success(null) }
                    "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                    "openBatterySettings" -> { openBatterySettings(); result.success(null) }
                    "getDataSaverStatus" -> {
                        val cm = getSystemService(ConnectivityManager::class.java)
                        result.success(cm.restrictBackgroundStatus)
                    }
                    "openDataSaverSettings" -> {
                        val intent = Intent(android.provider.Settings.ACTION_IGNORE_BACKGROUND_DATA_RESTRICTIONS_SETTINGS,
                            Uri.parse("package:$packageName"))
                        startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, logsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "append" -> { LogStore.append(this, (call.arguments as? String) ?: ""); result.success(null) }
                    "read" -> result.success(LogStore.read(this))
                    "clear" -> { LogStore.clear(this); result.success(null) }
                    else -> result.notImplemented()
                }
            }

        // Attach notification channel to the UI engine so notifications are handled even if
        // the background engine hasn't started yet. Also cache this engine for the receiver.
        val msgChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "msg_mirror")
        MsgNotificationListener.setChannelAndFlush(msgChannel)
        try { io.flutter.embedding.engine.FlutterEngineCache.getInstance().put("ui_engine", flutterEngine) } catch (_: Exception) {}

        // Apps listing channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "list" -> {
                        // Load on a background thread to avoid blocking the main thread.
                        thread(name = "apps-list-loader") {
                            try {
                                val pm = packageManager
                                val apps = pm.getInstalledApplications(0)
                                    .map { appInfo ->
                                        val label = try { pm.getApplicationLabel(appInfo).toString() } catch (_: Exception) { appInfo.packageName }
                                        mapOf("package" to appInfo.packageName, "label" to label)
                                    }
                                    .sortedBy { it["label"]?.toString()?.lowercase() }
                                runOnUiThread { result.success(apps) }
                            } catch (e: Exception) {
                                runOnUiThread { result.success(emptyList<Map<String, String>>()) }
                            }
                        }
                    }
                    "icon" -> {
                        val pkg = (call.arguments as? String) ?: ""
                        // Serve from cache if present
                        iconCache.get(pkg)?.let { bytes ->
                            result.success(bytes)
                            return@setMethodCallHandler
                        }
                        // Heavy work off main thread
                        thread(name = "icon-loader-$pkg") {
                            try {
                                val pm = packageManager
                                val drawable = pm.getApplicationIcon(pkg)
                                val bmp = drawableToBitmap(drawable)
                                val stream = ByteArrayOutputStream()
                                // Use moderate compression level and let PNG be lossless
                                bmp.compress(Bitmap.CompressFormat.PNG, 100, stream)
                                val bytes = stream.toByteArray()
                                iconCache.put(pkg, bytes)
                                runOnUiThread { result.success(bytes) }
                            } catch (e: Exception) {
                                runOnUiThread { result.success(null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable) {
            if (drawable.bitmap != null) return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bmp
    }

    private fun hasNotificationAccess(): Boolean {
        val cn = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        return cn.contains(packageName)
    }

    private fun openNotificationAccess() {
        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }

    private fun hasPostNotifications(): Boolean {
        return if (Build.VERSION.SDK_INT >= 33) {
            checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            val nm = getSystemService(NotificationManager::class.java)
            nm.areNotificationsEnabled()
        }
    }

    private fun openAppNotificationSettings() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        }
        startActivity(intent)
    }

    private fun openAppDetails() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName"))
        startActivity(intent)
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openBatterySettings() {
        startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    }
}
