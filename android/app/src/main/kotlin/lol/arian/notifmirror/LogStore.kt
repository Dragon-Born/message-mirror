package lol.arian.notifmirror

import android.content.Context
import android.util.Log
import java.io.File

object LogStore {
    private const val LOG_FILE = "msgs.log"
    private const val MAX_BYTES: Long = 256 * 1024
    private const val TAG = "MsgMirror"

    private fun file(ctx: Context): File = File(ctx.filesDir, LOG_FILE)
    private fun fileBackup(ctx: Context): File = File(ctx.filesDir, "$LOG_FILE.1")

    @Synchronized
    fun append(ctx: Context, line: String) {
        try {
            try { Log.d(TAG, line) } catch (_: Exception) {}
            val f = file(ctx)
            if (f.exists() && f.length() > MAX_BYTES) {
                rotate(ctx)
            }
            f.appendText("${timestamp()} $line\n")
        } catch (_: Exception) {}
    }

    @Synchronized
    fun read(ctx: Context): String {
        return try { file(ctx).takeIf { it.exists() }?.readText() ?: "" } catch (_: Exception) { "" }
    }

    @Synchronized
    fun clear(ctx: Context) {
        try { file(ctx).delete() } catch (_: Exception) {}
    }

    private fun rotate(ctx: Context) {
        try {
            val f = file(ctx)
            val b = fileBackup(ctx)
            if (b.exists()) b.delete()
            f.renameTo(b)
        } catch (_: Exception) {}
    }

    private fun timestamp(): String {
        val now = java.time.LocalDateTime.now()
        return now.toString()
    }
}
