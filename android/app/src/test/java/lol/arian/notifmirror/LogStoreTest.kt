package lol.arian.notifmirror

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.robolectric.RobolectricTestRunner
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(RobolectricTestRunner::class)
class LogStoreTest {
    @Test
    fun appendAndReadAndClear() {
        val ctx: Context = ApplicationProvider.getApplicationContext()
        LogStore.clear(ctx)
        LogStore.append(ctx, "hello")
        LogStore.append(ctx, "world")
        val txt = LogStore.read(ctx)
        assertTrue(txt.contains("hello"))
        assertTrue(txt.contains("world"))
        LogStore.clear(ctx)
        val empty = LogStore.read(ctx)
        assertTrue(empty.isEmpty())
    }
}


