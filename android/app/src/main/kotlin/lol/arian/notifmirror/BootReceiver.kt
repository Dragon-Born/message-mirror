package lol.arian.notifmirror

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED == intent.action) {
            LogStore.append(context, "BootReceiver ACTION_BOOT_COMPLETED")
            val svc = Intent(context, AlwaysOnService::class.java)
            context.startForegroundService(svc)
        }
    }
}
