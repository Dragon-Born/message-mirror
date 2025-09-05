package lol.arian.notifmirror

import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.provider.Telephony
import io.flutter.plugin.common.MethodChannel

class SmsObserver(
    private val ctx: Context,
    private val channel: MethodChannel
) : ContentObserver(Handler(ctx.mainLooper)) {

    override fun onChange(selfChange: Boolean, uri: Uri?) {
        try { LogStore.append(ctx, "SmsObserver onChange uri=${uri?.toString()}") } catch (_: Exception) {}
        val cursor = ctx.contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE),
            null, null, Telephony.Sms.DEFAULT_SORT_ORDER
        ) ?: return

        cursor.use {
            if (it.moveToFirst()) {
                val from = it.getString(0)
                val body = it.getString(1)
                val date = it.getLong(2)
                channel.invokeMethod("onSms", mapOf("from" to from, "body" to body, "date" to date))
            }
        }
    }
}
