package lol.arian.notifmirror

import android.content.Context
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30])
class ApiSenderTest {
    @Test
    fun doesNotCrashWithEmptyEndpoint() {
        val ctx = org.robolectric.RuntimeEnvironment.getApplication() as Context
        ApiSender.send(ctx, from = "t", body = "b", whenMs = 0L)
        // No assertion, ensure path executes without exceptions
        assert(true)
    }
}


