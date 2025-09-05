package lol.arian.notifmirror

import android.os.Bundle
import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

class MsgNotificationListener : NotificationListenerService() {
    companion object {
        const val ACTION = "lol.arian.notifmirror.NOTIF_EVENT"
        @Volatile
        var channel: MethodChannel? = null
        private val pendingEvents: MutableList<Map<String, Any?>> = mutableListOf()

        fun setChannelAndFlush(ch: MethodChannel?) {
            channel = ch
            if (ch == null) return
            synchronized(pendingEvents) {
                try {
                    for (event in pendingEvents) {
                        ch.invokeMethod("onNotification", event)
                    }
                } catch (_: Exception) {}
                pendingEvents.clear()
            }
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try { LogStore.append(this, "onNotificationPosted from ${sbn.packageName}") } catch (_: Exception) {}
        val n = sbn.notification ?: return
        val extras: Bundle = n.extras
        val app = sbn.packageName ?: ""
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""
        val lines = extras.getCharSequenceArray("android.textLines")
            ?.joinToString("\n") { it.toString() } ?: ""

        val textResolved = if (text.isNotEmpty()) text else if (bigText.isNotEmpty()) bigText else lines
        val isOngoing = (n.flags and Notification.FLAG_ONGOING_EVENT) != 0
        if (isOngoing) {
            try { LogStore.append(this, "skip ongoing notification for $app") } catch (_: Exception) {}
            return
        }
        // Filter by allowed packages persisted in prefs
        val prefs = getSharedPreferences("msg_mirror", MODE_PRIVATE)
        val allowed = prefs.getStringSet("allowed_packages", setOf("com.google.android.apps.messaging", "com.google.android.dialer")) ?: setOf()
        if (allowed.isNotEmpty() && !allowed.contains(app)) {
            try { LogStore.append(this, "skip package $app (not allowed)") } catch (_: Exception) {}
            return
        }
        try { LogStore.append(this, "emit onNotification: title='$title' textLen=${textResolved.length}") } catch (_: Exception) {}
        val intent = Intent(ACTION).apply {
            putExtra("app", app)
            putExtra("title", title)
            putExtra("text", textResolved)
            putExtra("when", sbn.postTime)
            putExtra("isGroupSummary", ((n.flags and 0x00000200) != 0))
        }
        sendBroadcast(intent)

        // Also deliver directly via channel if available
        val payload: Map<String, Any?> = mapOf(
            "app" to app,
            "title" to title,
            "text" to textResolved,
            "when" to sbn.postTime,
            "isGroupSummary" to ((n.flags and 0x00000200) != 0)
        )
        val ch = channel
        if (ch != null) {
            ch.invokeMethod("onNotification", payload)
        } else {
            synchronized(pendingEvents) { pendingEvents.add(payload) }
            // As a final fallback, send with native HTTP to avoid losing events
            ApiSender.send(this, title, textResolved, sbn.postTime)
        }
    }

    override fun onCreate() {
        super.onCreate()
        try { LogStore.append(this, "MsgListener onCreate") } catch (_: Exception) {}
    }

    override fun onDestroy() {
        super.onDestroy()
        try { LogStore.append(this, "MsgListener onDestroy") } catch (_: Exception) {}
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        try { LogStore.append(this, "MsgListener onListenerConnected") } catch (_: Exception) {}
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        try { LogStore.append(this, "MsgListener onListenerDisconnected") } catch (_: Exception) {}
    }
}
