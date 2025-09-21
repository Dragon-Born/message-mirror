package lol.arian.notifmirror

import android.content.Context
import android.content.Intent
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30])
class BootReceiverTest {
    @Test
    fun onBootCompleted_doesNotCrash() {
        val context = org.robolectric.RuntimeEnvironment.getApplication() as Context
        val receiver = BootReceiver()
        val intent = Intent(Intent.ACTION_BOOT_COMPLETED)
        receiver.onReceive(context, intent)
        assert(true)
    }
}


