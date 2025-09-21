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
        val lines = extras.getCharSequenceArray("android.textLines")?.joinToString("\n") { it.toString() } ?: ""
        val subText = extras.getCharSequence("android.subText")?.toString() ?: ""
        val summaryText = extras.getCharSequence("android.summaryText")?.toString() ?: ""
        val infoText = extras.getCharSequence("android.infoText")?.toString() ?: ""
        val people: String = try {
            val arr = extras.get("android.people.list") as? ArrayList<*> ?: arrayListOf<Any?>()
            if (arr.isEmpty()) "" else arr.joinToString(",") { it?.toString() ?: "" }
        } catch (_: Exception) { "" }
        val category = n.category ?: ""
        val priority = n.priority
        val channelId = try { if (android.os.Build.VERSION.SDK_INT >= 26) n.channelId ?: "" else "" } catch (_: Exception) { "" }
        val visibility = n.visibility
        val color = try { if (n.color != 0) String.format("#%08X", n.color) else "" } catch (_: Exception) { "" }
        val groupKey = try { extras.getString("android.support.groupKey") ?: "" } catch (_: Exception) { "" }
        val badgeIconType = try { if (android.os.Build.VERSION.SDK_INT >= 26) n.badgeIconType else -1 } catch (_: Exception) { -1 }
        val actionTitles: String = try { n.actions?.mapNotNull { it?.title?.toString() }?.joinToString("|") ?: "" } catch (_: Exception) { "" }
        // Large icon and big picture (best-effort, may be absent)
        val largeIconB64: String = try {
            val bmp = (extras.get("android.largeIcon") as? android.graphics.Bitmap)
                ?: run {
                    if (android.os.Build.VERSION.SDK_INT >= 23) {
                        val ic = n.getLargeIcon()
                        if (ic != null) {
                        val dr = ic.loadDrawable(this)
                        if (dr != null) drawableToBitmap(dr) else null
                        } else null
                    } else null
                }
            if (bmp != null) android.util.Base64.encodeToString(toPngBytes(bmp), android.util.Base64.NO_WRAP) else ""
        } catch (_: Exception) { "" }
        val pictureB64: String = try {
            val bmp = extras.get("android.picture") as? android.graphics.Bitmap
            if (bmp != null) android.util.Base64.encodeToString(toPngBytes(bmp), android.util.Base64.NO_WRAP) else ""
        } catch (_: Exception) { "" }

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
            putExtra("subText", subText)
            putExtra("summaryText", summaryText)
            putExtra("bigText", bigText)
            putExtra("infoText", infoText)
            putExtra("people", people)
            putExtra("category", category)
            putExtra("priority", priority)
            putExtra("channelId", channelId)
            putExtra("groupKey", groupKey)
            putExtra("visibility", visibility)
            putExtra("color", color)
            putExtra("badgeIconType", badgeIconType)
            putExtra("actions", actionTitles)
            putExtra("largeIcon", largeIconB64)
            putExtra("picture", pictureB64)
        }
        sendBroadcast(intent)

        // Also deliver directly via channel if available
        val payload: Map<String, Any?> = mapOf(
            "app" to app,
            "title" to title,
            "text" to textResolved,
            "when" to sbn.postTime,
            "isGroupSummary" to ((n.flags and 0x00000200) != 0),
            "subText" to subText,
            "summaryText" to summaryText,
            "bigText" to bigText,
            "infoText" to infoText,
            "people" to people,
            "category" to category,
            "priority" to priority,
            "channelId" to channelId,
            "groupKey" to groupKey,
            "visibility" to visibility,
            "color" to color,
            "badgeIconType" to badgeIconType,
            "actions" to actionTitles,
            "largeIcon" to largeIconB64,
            "picture" to pictureB64
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

private fun toPngBytes(bmp: android.graphics.Bitmap): ByteArray {
    val stream = java.io.ByteArrayOutputStream()
    bmp.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
    return stream.toByteArray()
}

private fun drawableToBitmap(drawable: android.graphics.drawable.Drawable): android.graphics.Bitmap {
    if (drawable is android.graphics.drawable.BitmapDrawable) {
        drawable.bitmap?.let { return it }
    }
    val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
    val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
    val bmp = android.graphics.Bitmap.createBitmap(width, height, android.graphics.Bitmap.Config.ARGB_8888)
    val canvas = android.graphics.Canvas(bmp)
    drawable.setBounds(0, 0, canvas.width, canvas.height)
    drawable.draw(canvas)
    return bmp
}
