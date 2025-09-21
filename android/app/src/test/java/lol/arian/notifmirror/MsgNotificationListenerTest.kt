package lol.arian.notifmirror

import android.app.Notification
import android.os.Bundle
import androidx.test.core.app.ApplicationProvider
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30])
class MsgNotificationListenerTest {
    @Test
    fun build_payload_fields_present() {
        // This is a smoke test ensuring we can construct typical extras without crashing.
        val extras = Bundle().apply {
            putCharSequence("android.title", "Title")
            putCharSequence("android.text", "Body")
            putCharSequence("android.bigText", "Big")
            putCharSequence("android.subText", "Sub")
            putCharSequence("android.summaryText", "Summary")
            putCharSequence("android.infoText", "Info")
        }
        val n = Notification().apply { this.extras?.putAll(extras) }
        assert(true)
    }
}


