package lol.arian.notifmirror

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.Manifest
import android.content.pm.PackageManager
import android.provider.Telephony
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class AlwaysOnService : Service() {

    private var engine: FlutterEngine? = null
    private var smsObserver: SmsObserver? = null

    override fun onCreate() {
        super.onCreate()
        LogStore.append(this, "AlwaysOnService onCreate")
        startAsForeground()
        initFlutterEngine()
        try {
            val prefs = getSharedPreferences("msg_mirror", MODE_PRIVATE)
            prefs.edit().putBoolean("service_running", true).apply()
        } catch (_: Exception) {}
    }

    private fun startAsForeground() {
        val channelId = "message_mirror"
        val mgr = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= 26) {
            val chan = NotificationChannel(channelId, "Message Mirror", NotificationManager.IMPORTANCE_MIN)
            mgr.createNotificationChannel(chan)
        }
        val notif: Notification = NotificationCompat.Builder(this, channelId)
            .setOngoing(true)
            .setContentTitle("Message Mirror running")
            .setSmallIcon(android.R.drawable.stat_notify_sync)
            .build()
        startForeground(1, notif)
        LogStore.append(this, "AlwaysOnService startForeground")
    }

    private fun initFlutterEngine() {
        val loader = FlutterInjector.instance().flutterLoader()
        try {
            loader.startInitialization(this)
            loader.ensureInitializationComplete(this, null)
        } catch (_: Exception) {}
        val appBundlePath = loader.findAppBundlePath()
        val dartEntrypoint = DartExecutor.DartEntrypoint(appBundlePath, "backgroundMain")
        engine = FlutterEngine(this)

        // Set up channels BEFORE running Dart, so early Dart logs/reads work
        val messenger = engine!!.dartExecutor.binaryMessenger

        // Logs channel for background engine
        MethodChannel(messenger, "msg_mirror_logs").setMethodCallHandler { call, result ->
            when (call.method) {
                "append" -> { LogStore.append(this, (call.arguments as? String) ?: ""); result.success(null) }
                "read" -> result.success(LogStore.read(this))
                "clear" -> { LogStore.clear(this); result.success(null) }
                else -> result.notImplemented()
            }
        }

        // Prefs channel
        val prefs = getSharedPreferences("msg_mirror", MODE_PRIVATE)
        MethodChannel(messenger, "msg_mirror_prefs").setMethodCallHandler { call, result ->
            when (call.method) {
                "getReception" -> result.success(prefs.getString("reception", ""))
                "setReception" -> {
                    val v = call.arguments as? String ?: ""
                    prefs.edit().putString("reception", v).apply()
                    result.success(null)
                }
                "getEndpoint" -> result.success(prefs.getString("endpoint", ""))
                "setEndpoint" -> {
                    val v = call.arguments as? String ?: ""
                    prefs.edit().putString("endpoint", v).apply()
                    result.success(null)
                }
                "getSmsEnabled" -> result.success(prefs.getBoolean("sms_enabled", true))
                "setSmsEnabled" -> {
                    val v = (call.arguments as? Boolean) ?: true
                    prefs.edit().putBoolean("sms_enabled", v).apply()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Message channel
        val channel = MethodChannel(messenger, "msg_mirror")
        MsgNotificationListener.setChannelAndFlush(channel)

        // Now run Dart entrypoint
        engine!!.dartExecutor.executeDartEntrypoint(dartEntrypoint)
        FlutterEngineCache.getInstance().put("always_on_engine", engine)

        // Optional: register SMS observer if permission granted
        // reuse prefs declared above
        val smsEnabled = prefs.getBoolean("sms_enabled", true)
        if (smsEnabled && checkSelfPermission(Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED) {
            smsObserver = SmsObserver(this, channel)
            contentResolver.registerContentObserver(
                Telephony.Sms.Inbox.CONTENT_URI,
                true,
                smsObserver as SmsObserver
            )
            LogStore.append(this, "SmsObserver registered")
        } else {
            LogStore.append(this, "SmsObserver not registered (enabled=$smsEnabled, hasPerm=${checkSelfPermission(Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED})")
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        LogStore.append(this, "AlwaysOnService onStartCommand")
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        LogStore.append(this, "AlwaysOnService onDestroy")
        try {
            val prefs = getSharedPreferences("msg_mirror", MODE_PRIVATE)
            prefs.edit().putBoolean("service_running", false).apply()
        } catch (_: Exception) {}
        smsObserver?.let {
            try { contentResolver.unregisterContentObserver(it) } catch (_: Exception) {}
        }
        smsObserver = null
        MsgNotificationListener.channel = null
        engine?.destroy()
        engine = null
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
