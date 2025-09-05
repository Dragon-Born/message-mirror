package lol.arian.notifmirror

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class NotifEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != MsgNotificationListener.ACTION) return
        val data = mapOf(
            "app" to (intent.getStringExtra("app") ?: ""),
            "title" to (intent.getStringExtra("title") ?: ""),
            "text" to (intent.getStringExtra("text") ?: ""),
            "when" to intent.getLongExtra("when", 0L),
            "isGroupSummary" to intent.getBooleanExtra("isGroupSummary", false)
        )
        try { LogStore.append(context, "NotifEventReceiver -> ${data["title"]}") } catch (_: Exception) {}

        // Try active UI engine first
        var ch: MethodChannel? = null
        try {
            val uiEngine = FlutterEngineCache.getInstance().get("ui_engine")
            if (uiEngine != null) ch = MethodChannel(uiEngine.dartExecutor.binaryMessenger, "msg_mirror")
        } catch (_: Exception) {}

        // Fallback to our background cache key
        if (ch == null) {
            try {
                val bg = FlutterEngineCache.getInstance().get("always_on_engine")
                if (bg != null) ch = MethodChannel(bg.dartExecutor.binaryMessenger, "msg_mirror")
            } catch (_: Exception) {}
        }

        if (ch != null) {
            LogStore.append(context, "NotifEventReceiver: deliver via ${if (FlutterEngineCache.getInstance().get("ui_engine") != null) "UI" else "BG"} channel")
            ch.invokeMethod("onNotification", data)
        } else {
            LogStore.append(context, "NotifEventReceiver: no channel available")
        }
    }
}
