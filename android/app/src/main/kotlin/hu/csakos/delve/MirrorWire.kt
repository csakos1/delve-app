package hu.csakos.delve

import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL

/**
 * Notification mirroring (DA2b), the parts without Android in them: what an
 * event is, which notifications count, the waiting events and the request to
 * the backend (`POST /api/v1/mirror/phone`, delve-backend `api/mirror.py`).
 *
 * Nothing of a notification is written to disk or to the log anywhere here.
 */

/** One thing the listener saw, on its way to the backend. */
internal data class MirrorEvent(
    val remove: Boolean,
    val key: String,
    val app: String? = null,
    val title: String? = null,
    val text: String? = null,
    val category: String? = null,
    val hidden: Boolean = false,
    /** SystemClock.elapsedRealtime() when it was seen. */
    val at: Long = 0,
    /** The posting app's icon: a small PNG as base64 (MirrorIcons). */
    val icon: String? = null,
)

internal object MirrorRules {
    /** android.app.Notification.FLAG_FOREGROUND_SERVICE and FLAG_GROUP_SUMMARY. */
    private const val FLAG_FOREGROUND_SERVICE = 0x40
    private const val FLAG_GROUP_SUMMARY = 0x200

    /** What Android 15+ puts in place of a one-time code's text (English phones). */
    private const val REDACTED = "Sensitive notification content hidden"

    /**
     * Not the players, the "doing work in the background" kind or a group's
     * summary (it repeats its children, or is empty): only what the user can
     * swipe away.
     */
    fun mirrorable(clearable: Boolean, ongoing: Boolean, flags: Int): Boolean =
        clearable && !ongoing && (flags and (FLAG_FOREGROUND_SERVICE or FLAG_GROUP_SUMMARY)) == 0

    /**
     * Android hid the content from the listener (a one-time code): the title
     * is empty, and the notification names "Android System" where the app's
     * own name would be ([extrasLabel] against [pmLabel]) or carries the
     * placeholder text.
     */
    fun hidden(title: String, text: String, pmLabel: String, extrasLabel: String?): Boolean =
        title.isEmpty() && ((extrasLabel != null && extrasLabel != pmLabel) || text == REDACTED)
}

/**
 * The last content sent for a key: an app that posts the same notification
 * again (a new timestamp, a progress tick) must not pop it up again on the
 * desktop. In memory, the newest [max] keys.
 */
internal class MirrorDedupe(private val max: Int = 200) {
    private val last = LinkedHashMap<String, Int>()

    /** Whether this content is new for the key (and remembers it). */
    @Synchronized
    fun fresh(key: String, fingerprint: Int): Boolean {
        if (last[key] == fingerprint) return false
        last.remove(key)
        last[key] = fingerprint
        while (last.size > max) last.remove(last.keys.first())
        return true
    }

    @Synchronized
    fun forget(key: String) {
        last.remove(key)
    }

    @Synchronized
    fun clear() = last.clear()
}

/**
 * The events waiting for the backend, oldest first. Not thread safe: the
 * sender's one thread owns it.
 */
internal class MirrorQueue(
    private val ttlMs: Long = TTL_MS,
    private val max: Int = MAX,
) {
    private val events = ArrayList<MirrorEvent>()

    val size: Int get() = events.size

    /**
     * A newer post of a key replaces the one still waiting; a remove makes a
     * waiting post pointless and still goes out (an earlier post of the key
     * may be on the desktop already).
     */
    fun add(event: MirrorEvent) {
        events.removeAll { it.key == event.key && (!it.remove || event.remove) }
        events.add(event)
        while (events.size > max) events.removeAt(0)
    }

    /** Drops what is older than the backend would keep it; how many went. */
    fun expire(now: Long): Int {
        val before = events.size
        events.removeAll { now - it.at >= ttlMs }
        return before - events.size
    }

    /** The next request's events (the backend takes [BATCH] at once). */
    fun head(): List<MirrorEvent> = events.take(BATCH)

    fun sent(batch: List<MirrorEvent>) {
        events.removeAll { e -> batch.any { it === e } }
    }

    fun clear() = events.clear()

    companion object {
        /** The backend holds a command for the desktop this long (QUEUE_TTL_S). */
        const val TTL_MS = 60_000L
        const val MAX = 200

        /** EVENTS_MAX of the backend. */
        const val BATCH = 32
    }
}

internal object MirrorWire {
    const val KEY_MAX = 512
    const val APP_MAX = 64
    const val TITLE_MAX = 256
    const val TEXT_MAX = 2000
    private const val CATEGORY_MAX = 32
    private const val ANSWER_MAX = 64 * 1024

    class Answer(val status: Int, val desk: Boolean?)

    /** At most [max] UTF-16 units (the backend counts code points: never more), no half pair at the end. */
    fun clip(s: String, max: Int): String {
        if (s.length <= max) return s
        val cut = s.substring(0, max)
        return if (cut.last().isHighSurrogate()) cut.dropLast(1) else cut
    }

    /** Control characters to spaces, trimmed: an app's name or a title is one line. */
    fun line(s: String): String =
        buildString(s.length) { for (c in s) append(if (c < ' ' || c == '\u007f') ' ' else c) }.trim()

    /** Android's category when the backend would take it (`^[a-z_]*$`). */
    fun category(raw: String?): String? =
        raw?.takeIf { it.isNotEmpty() && it.length <= CATEGORY_MAX && it.all { c -> c in 'a'..'z' || c == '_' } }

    fun body(events: List<MirrorEvent>): String = buildString {
        append("{\"events\":[")
        events.forEachIndexed { i, e ->
            if (i > 0) append(',')
            append("{\"op\":").append(if (e.remove) "\"remove\"" else "\"post\"")
            append(",\"key\":").append(quote(e.key))
            if (!e.remove) {
                append(",\"app\":").append(quote(e.app ?: ""))
                if (e.hidden) {
                    append(",\"hidden\":true")
                } else {
                    if (!e.title.isNullOrEmpty()) append(",\"title\":").append(quote(e.title))
                    if (!e.text.isNullOrEmpty()) append(",\"text\":").append(quote(e.text))
                }
                if (e.category != null) append(",\"category\":").append(quote(e.category))
                if (!e.icon.isNullOrEmpty()) append(",\"icon\":").append(quote(e.icon))
            }
            append('}')
        }
        append("]}")
    }

    fun quote(s: String): String = buildString(s.length + 2) {
        append('"')
        for (c in s) {
            when {
                c == '"' -> append("\\\"")
                c == '\\' -> append("\\\\")
                c == '\n' -> append("\\n")
                c == '\r' -> append("\\r")
                c == '\t' -> append("\\t")
                c < ' ' || c == ' ' || c == ' ' ->
                    append("\\u").append(c.code.toString(16).padStart(4, '0'))
                else -> append(c)
            }
        }
        append('"')
    }

    /** `desk.connected` of the backend's answer; null when it says nothing. */
    fun deskConnected(answer: String): Boolean? =
        Regex("\"connected\"\\s*:\\s*(true|false)").find(answer)?.groupValues?.get(1)?.let { it == "true" }

    /**
     * One request. [server] is the origin (`https://host`), without a slash
     * at the end. Throws what the connection throws (no network, no answer).
     */
    fun post(server: String, token: String, body: String, connectMs: Int, readMs: Int): Answer {
        val conn = URL("$server/api/v1/mirror/phone").openConnection() as HttpURLConnection
        try {
            val bytes = body.toByteArray(Charsets.UTF_8)
            conn.requestMethod = "POST"
            conn.connectTimeout = connectMs
            conn.readTimeout = readMs
            conn.instanceFollowRedirects = false
            conn.useCaches = false
            conn.doOutput = true
            conn.setRequestProperty("Authorization", "Bearer $token")
            conn.setRequestProperty("Content-Type", "application/json; charset=utf-8")
            conn.setRequestProperty("Accept", "application/json")
            conn.setFixedLengthStreamingMode(bytes.size)
            conn.outputStream.use { it.write(bytes) }
            val status = conn.responseCode
            if (status !in 200..299) {
                // read nothing of an error page; closing the stream frees the connection
                conn.errorStream?.close()
                return Answer(status, null)
            }
            val out = ByteArrayOutputStream()
            conn.inputStream.use { input ->
                val buf = ByteArray(4096)
                while (out.size() < ANSWER_MAX) {
                    val n = input.read(buf)
                    if (n < 0) break
                    out.write(buf, 0, n)
                }
            }
            return Answer(status, deskConnected(out.toString("UTF-8")))
        } finally {
            conn.disconnect()
        }
    }
}
