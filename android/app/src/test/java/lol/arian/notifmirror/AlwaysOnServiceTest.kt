package lol.arian.notifmirror

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [30])
class AlwaysOnServiceTest {
    @Test
    fun smsObserver_toggle_noCrash() {
        AlwaysOnService.testSkipEngine = true
        val controller = Robolectric.buildService(AlwaysOnService::class.java).create()
        val service = controller.get()
        // Exercise toggle helper; permission may not be granted in robolectric, this should not crash
        service.debugToggleSmsObserver(false)
        service.debugToggleSmsObserver(true)
        controller.destroy()
        assert(true)
    }

    @Test
    fun service_running_flag_set_and_cleared() {
        AlwaysOnService.testSkipEngine = true
        val controller = Robolectric.buildService(AlwaysOnService::class.java).create()
        val service = controller.get()
        val prefs = service.getSharedPreferences("msg_mirror", Context.MODE_PRIVATE)
        // onCreate sets true
        assert(prefs.getBoolean("service_running", false))
        controller.destroy()
        // onDestroy sets false
        assert(!prefs.getBoolean("service_running", true))
    }
}


