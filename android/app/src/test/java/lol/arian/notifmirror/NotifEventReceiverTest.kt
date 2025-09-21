package lol.arian.notifmirror

import android.content.Context
import android.content.Intent
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30])
class NotifEventReceiverTest {
    @Test
    fun onReceive_withoutEngine_doesNotCrash() {
        val ctx: Context = org.robolectric.RuntimeEnvironment.getApplication() as Context
        val intent = Intent(MsgNotificationListener.ACTION).apply {
            putExtra("app", "com.example")
            putExtra("title", "t")
            putExtra("text", "x")
            putExtra("when", 1L)
        }
        val receiver = NotifEventReceiver()
        receiver.onReceive(ctx, intent)
        assert(true)
    }
}


