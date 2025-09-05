package lol.arian.notifmirror

import android.content.Context
import org.json.JSONObject
import java.io.BufferedReader
import java.io.OutputStreamWriter
import java.lang.StringBuilder
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object ApiSender {
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.US)

    fun send(context: Context, from: String, body: String, whenMs: Long) {
        val prefs = context.getSharedPreferences("msg_mirror", Context.MODE_PRIVATE)
        val endpoint = prefs.getString("endpoint", "") ?: ""
        val template = prefs.getString("payload_template", "") ?: ""
        if (endpoint.isEmpty() || body.isEmpty()) {
            try { LogStore.append(context, "ApiSender skip: endpoint/body empty") } catch (_: Exception) {}
            return
        }
        val dateStr = dateFormat.format(Date(if (whenMs > 0) whenMs else System.currentTimeMillis()))
        val payload = try {
            if (template.isNotBlank()) {
                val rendered = template
                    .replace("{{body}}", escape(body))
                    .replace("{{from}}", escape(from))
                    .replace("{{date}}", escape(dateStr))
                    .replace("{{app}}", escape("notification"))
                    .replace("{{type}}", escape("notification"))
                    .replace("{{reception}}", escape(prefs.getString("reception", "") ?: ""))
                JSONObject(rendered)
            } else {
                JSONObject()
                    .put("message_body", body)
                    .put("message_from", from)
                    .put("message_date", dateStr)
                    .put("type", "notification")
            }
        } catch (e: Exception) {
            JSONObject()
                .put("message_body", body)
                .put("message_from", from)
                .put("message_date", dateStr)
                .put("type", "notification")
        }

        Thread {
            try {
                LogStore.append(context, "ApiSender POST → $endpoint from='$from' len=${body.length}")
                val url = URL(endpoint)
                val conn = (url.openConnection() as HttpURLConnection).apply {
                    requestMethod = "POST"
                    connectTimeout = 10000
                    readTimeout = 15000
                    doOutput = true
                    setRequestProperty("Content-Type", "application/json")
                }
                OutputStreamWriter(conn.outputStream).use { it.write(payload.toString()) }
                val code = conn.responseCode
                val resp = try {
                    BufferedReader(conn.inputStream.reader()).use { br ->
                        val sb = StringBuilder()
                        var line: String?
                        while (true) {
                            line = br.readLine(); if (line == null) break; sb.append(line)
                        }
                        sb.toString()
                    }
                } catch (_: Exception) { "" }
                LogStore.append(context, "ApiSender ← status=$code len=${resp.length}")
                conn.disconnect()
            } catch (e: Exception) {
                try { LogStore.append(context, "ApiSender error: ${e.message}") } catch (_: Exception) {}
            }
        }.start()
    }

    private fun escape(v: String): String = v
}


