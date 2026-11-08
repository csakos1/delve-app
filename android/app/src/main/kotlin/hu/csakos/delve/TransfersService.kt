package hu.csakos.delve

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/**
 * The Files tab's transfers in the background (F3b, 23g2): a `dataSync`
 * foreground service with a partial wake lock, so a download, upload or
 * copy goes on with the app away and the screen off. It runs only while a
 * transfer is queued or running; Dart (TransferNotice) starts it, updates
 * its notification and stops it.
 *
 * The notification is on the "Transfers" channel (IMPORTANCE_LOW: no sound,
 * no peek): the running transfer's name, its progress (determinate when the
 * size is known) and "1 of 3"; actions Cancel all (back to Dart through
 * [listener]) and Open (the app's Transfers sheet). When the queue empties
 * with the app away, Dart posts one ordinary notification on the same
 * channel ("Saved to Downloads/Delve" · Open, see [finished]).
 *
 * Android 15 limits `dataSync` services to 6 hours a day: [onTimeout] stops
 * the service; the transfers go on as long as Android lets the app run.
 */
class TransfersService : Service() {
    private var lock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_CANCEL_ALL -> {
                // a tap on Cancel all; Dart cancels and then stops the service
                val l = listener
                if (l == null) stopSelf() else l(EVENT_CANCEL_ALL)
                return START_NOT_STICKY
            }
        }
        starting = false
        val notification = progress(this, Progress.from(intent))
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            // not allowed now (started from the background, or the day's
            // dataSync time is used up): the transfers go on without it
            running = false
            stopSelf()
            return START_NOT_STICKY
        }
        running = true
        if (lock == null) {
            val power = getSystemService(Context.POWER_SERVICE) as PowerManager
            lock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG).apply {
                setReferenceCounted(false)
                acquire(WAKE_LOCK_MAX_MS)
            }
        }
        // killed by the system: Dart starts it again with the next transfer
        return START_NOT_STICKY
    }

    /** Android 15: the day's 6 hours of `dataSync` are used up. */
    override fun onTimeout(startId: Int, fgsType: Int) {
        running = false
        stopSelf()
    }

    override fun onDestroy() {
        running = false
        lock?.let { if (it.isHeld) it.release() }
        lock = null
        super.onDestroy()
    }

    /** What the ongoing notification shows (from Dart). */
    data class Progress(
        val title: String,
        val text: String,
        val sub: String,
        /** 0…[PROGRESS_MAX]; negative: indeterminate. */
        val progress: Int,
        val cancelLabel: String,
        val openLabel: String,
    ) {
        fun into(intent: Intent): Intent = intent
            .putExtra(EXTRA_TITLE, title)
            .putExtra(EXTRA_TEXT, text)
            .putExtra(EXTRA_SUB, sub)
            .putExtra(EXTRA_PROGRESS, progress)
            .putExtra(EXTRA_CANCEL, cancelLabel)
            .putExtra(EXTRA_OPEN, openLabel)

        companion object {
            fun from(intent: Intent?) = Progress(
                title = intent?.getStringExtra(EXTRA_TITLE) ?: "Transfers",
                text = intent?.getStringExtra(EXTRA_TEXT) ?: "",
                sub = intent?.getStringExtra(EXTRA_SUB) ?: "",
                progress = intent?.getIntExtra(EXTRA_PROGRESS, -1) ?: -1,
                cancelLabel = intent?.getStringExtra(EXTRA_CANCEL) ?: "Cancel all",
                openLabel = intent?.getStringExtra(EXTRA_OPEN) ?: "Open",
            )

            fun from(args: Map<*, *>) = Progress(
                title = args["title"] as? String ?: "Transfers",
                text = args["text"] as? String ?: "",
                sub = args["sub"] as? String ?: "",
                progress = (args["progress"] as? Number)?.toInt() ?: -1,
                cancelLabel = args["cancel"] as? String ?: "Cancel all",
                openLabel = args["open"] as? String ?: "Open",
            )
        }
    }

    companion object {
        const val ACTION_START = "hu.csakos.delve.transfers.START"
        const val ACTION_STOP = "hu.csakos.delve.transfers.STOP"
        const val ACTION_CANCEL_ALL = "hu.csakos.delve.transfers.CANCEL_ALL"

        /** MainActivity's intent from the notifications: show the Transfers sheet. */
        const val ACTION_OPEN = "hu.csakos.delve.transfers.OPEN"

        const val EVENT_CANCEL_ALL = "cancelAll"
        const val PROGRESS_MAX = 1000

        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"
        private const val EXTRA_SUB = "sub"
        private const val EXTRA_PROGRESS = "progress"
        private const val EXTRA_CANCEL = "cancel"
        private const val EXTRA_OPEN = "open"
        private const val CHANNEL_ID = "transfers"
        private const val NOTIFICATION_ID = 7302
        private const val FINISHED_ID = 7303
        private const val WAKE_LOCK_TAG = "delve:transfers"

        /** A safety net: the lock is released when the service stops. */
        private const val WAKE_LOCK_MAX_MS = 6L * 60 * 60 * 1000

        /** Running in the foreground now (set on the main thread). */
        @Volatile
        var running = false
            private set

        /** A start was asked for and has not reached onStartCommand yet. */
        @Volatile
        private var starting = false

        /** MainActivity's hook back to Dart (Cancel all); null without the app. */
        var listener: ((String) -> Unit)? = null

        /** Starts the service, or updates its notification; false: not allowed now. */
        fun show(context: Context, p: Progress): Boolean {
            if (running) {
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                manager.notify(NOTIFICATION_ID, progress(context, p))
                return true
            }
            val intent = p.into(Intent(context, TransfersService::class.java).setAction(ACTION_START))
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                starting = true
                true
            } catch (e: Exception) {
                false
            }
        }

        /**
         * Stops the service. Through an intent, so a start still on its way
         * comes first: a service started with startForegroundService and
         * stopped before it called startForeground would crash the app.
         */
        fun stop(context: Context) {
            if (!running && !starting) return
            running = false
            starting = false
            val intent = Intent(context, TransfersService::class.java).setAction(ACTION_STOP)
            try {
                context.startService(intent)
            } catch (e: Exception) {
                context.stopService(Intent(context, TransfersService::class.java))
            }
        }

        /**
         * The queue emptied with the app away: one ordinary notification
         * (it replaces the previous one). [uri]: a single downloaded file –
         * a tap and Open open it in another app; otherwise they open the
         * app's Transfers sheet.
         */
        fun finished(
            context: Context,
            title: String,
            text: String,
            uri: String?,
            mime: String?,
            openLabel: String,
        ) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            channel(context, manager)
            val open = if (uri != null) {
                PendingIntent.getActivity(
                    context,
                    REQUEST_VIEW,
                    Intent(Intent.ACTION_VIEW)
                        .setDataAndType(Uri.parse(uri), mime ?: "*/*")
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            } else {
                openApp(context)
            }
            val n = builder(context)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(open)
                .setAutoCancel(true)
                .setShowWhen(true)
                .setWhen(System.currentTimeMillis())
                .setCategory(Notification.CATEGORY_STATUS)
                .addAction(action(context, openLabel, open))
                .build()
            manager.notify(FINISHED_ID, n)
        }

        private const val REQUEST_OPEN = 1
        private const val REQUEST_CANCEL = 2
        private const val REQUEST_VIEW = 3

        private fun progress(context: Context, p: Progress): Notification {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            channel(context, manager)
            val open = openApp(context)
            val cancel = PendingIntent.getService(
                context,
                REQUEST_CANCEL,
                Intent(context, TransfersService::class.java).setAction(ACTION_CANCEL_ALL),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val b = builder(context)
                .setContentTitle(p.title)
                .setContentIntent(open)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setShowWhen(false)
                .setCategory(Notification.CATEGORY_PROGRESS)
                .setProgress(PROGRESS_MAX, p.progress.coerceIn(0, PROGRESS_MAX), p.progress < 0)
                .addAction(action(context, p.cancelLabel, cancel))
                .addAction(action(context, p.openLabel, open))
            if (p.text.isNotEmpty()) b.setContentText(p.text)
            if (p.sub.isNotEmpty()) b.setSubText(p.sub)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                b.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
            }
            return b.build()
        }

        private fun openApp(context: Context): PendingIntent = PendingIntent.getActivity(
            context,
            REQUEST_OPEN,
            Intent(context, MainActivity::class.java)
                .setAction(ACTION_OPEN)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        private fun action(context: Context, label: String, intent: PendingIntent) =
            Notification.Action.Builder(
                Icon.createWithResource(context, R.drawable.ic_stat_delve),
                label,
                intent,
            ).build()

        private fun builder(context: Context): Notification.Builder {
            val b = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
            }
            return b.setSmallIcon(R.drawable.ic_stat_delve)
        }

        private fun channel(context: Context, manager: NotificationManager) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            if (manager.getNotificationChannel(CHANNEL_ID) != null) return
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Transfers",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Downloads, uploads and copies while they run, and finished downloads"
                    setShowBadge(false)
                    setSound(null, null)
                    enableVibration(false)
                },
            )
        }
    }
}
