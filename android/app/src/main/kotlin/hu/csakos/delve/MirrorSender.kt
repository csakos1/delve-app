package hu.csakos.delve

import android.content.Context
import android.os.PowerManager
import android.os.SystemClock
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * Sends the listener's events to the backend (DA2b), on a thread of its own,
 * with or without the Flutter engine.
 *
 * Events that arrive close together go in one request. A request that fails
 * (no network, the tailnet is down, a 5xx) is tried again after 2, 5, 10 and
 * then every 20 seconds; an event older than a minute is dropped – the
 * backend would not keep it longer for the desktop either, and a mirror shows
 * "now". What the backend refuses (4xx) is not sent again. The events wait in
 * memory only.
 *
 * A partial wake lock is held while there is something to send: the phone
 * may be asleep when a notification arrives.
 */
internal object MirrorSender {
    /** For the page: when a request last went through, what went wrong since. No content. */
    class Status(
        val okAt: Long? = null,
        val failAt: Long? = null,
        val failure: String? = null,
        val desk: Boolean? = null,
    )

    private const val BATCH_MS = 300L
    private const val CONNECT_MS = 8_000
    private const val READ_MS = 10_000
    private const val WAKE_MS = 30_000L

    @Volatile
    var status = Status()
        private set

    private val worker = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "delve-mirror").apply { isDaemon = true }
    }

    // the worker's own
    private val queue = MirrorQueue()
    private var planned: ScheduledFuture<*>? = null
    private var failures = 0

    private val wakeGuard = Any()
    private var wake: PowerManager.WakeLock? = null

    fun offer(context: Context, event: MirrorEvent) {
        val app = context.applicationContext
        hold(app)
        worker.execute {
            queue.add(event)
            if (planned == null) plan(app, BATCH_MS)
        }
    }

    /** Turned off or unpaired: nothing that waits goes out. */
    fun clear() {
        worker.execute {
            queue.clear()
            planned?.cancel(false)
            planned = null
            failures = 0
            release()
        }
        status = Status()
    }

    private fun plan(app: Context, delayMs: Long) {
        planned = worker.schedule(
            {
                planned = null
                try {
                    flush(app)
                } catch (t: Throwable) {
                    // nothing may end the worker; what waits expires on its own
                    release()
                }
            },
            delayMs,
            TimeUnit.MILLISECONDS,
        )
    }

    private fun flush(app: Context) {
        queue.expire(SystemClock.elapsedRealtime())
        val to = MirrorStore.sending(app)
        if (to == null) {
            queue.clear()
        }
        val batch = queue.head()
        if (to == null || batch.isEmpty()) {
            failures = 0
            release()
            return
        }
        hold(app)
        val now = System.currentTimeMillis()
        val before = status
        try {
            val answer = MirrorWire.post(to.server, to.token, MirrorWire.body(batch), CONNECT_MS, READ_MS)
            when {
                answer.status in 200..299 -> {
                    queue.sent(batch)
                    failures = 0
                    status = Status(okAt = now, desk = answer.desk)
                }
                answer.status == 401 -> {
                    // the token is not the server's any more; the app finds out the same way
                    queue.clear()
                    failures = 0
                    status = Status(before.okAt, now, "HTTP 401", null)
                }
                answer.status in 400..499 && answer.status != 408 && answer.status != 429 -> {
                    queue.sent(batch)
                    failures = 0
                    status = Status(before.okAt, now, "HTTP ${answer.status}", before.desk)
                }
                else -> {
                    failures++
                    status = Status(before.okAt, now, "HTTP ${answer.status}", before.desk)
                }
            }
        } catch (e: Exception) {
            failures++
            // the kind of failure only: a message could carry the address
            status = Status(before.okAt, now, e.javaClass.simpleName, before.desk)
        }
        if (queue.size == 0) {
            release()
        } else {
            plan(
                app,
                when (failures) {
                    0 -> 0L
                    1 -> 2_000L
                    2 -> 5_000L
                    3 -> 10_000L
                    else -> 20_000L
                },
            )
        }
    }

    private fun hold(app: Context) {
        synchronized(wakeGuard) {
            try {
                val lock = wake ?: (app.getSystemService(Context.POWER_SERVICE) as PowerManager)
                    .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "delve:mirror")
                    .apply { setReferenceCounted(false) }
                    .also { wake = it }
                lock.acquire(WAKE_MS)
            } catch (e: Exception) {
                // without it the request may wait until the phone wakes
            }
        }
    }

    private fun release() {
        synchronized(wakeGuard) {
            try {
                wake?.let { if (it.isHeld) it.release() }
            } catch (e: Exception) {
                // already released by its timeout
            }
        }
    }
}
