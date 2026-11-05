package hu.csakos.delve

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager

/**
 * Keeps the terminal connected while Delve is in the background (T4):
 * a foreground service with a partial wake lock, so the process, its SSH
 * connection and the keep-alive probes go on with the screen off (and the
 * Tailscale tunnel under them stays awake). Started and stopped from Dart
 * (TerminalKeepAlive); runs only while the setting is on and a tab is
 * connected.
 *
 * The notification Android requires is as quiet as it can be: its own
 * channel with the lowest importance (no sound, no status-bar icon, folded
 * in the shade), no badge, and from Android 13 the user can swipe it away
 * (the service keeps running). A tap opens the app.
 */
class TerminalKeepService : Service() {
    private var lock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: "Terminal connected"
        val notification = notification(text)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            // not allowed now (started from the background): nothing to keep
            stopSelf()
            return START_NOT_STICKY
        }
        if (lock == null) {
            val power = getSystemService(Context.POWER_SERVICE) as PowerManager
            lock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG).apply {
                setReferenceCounted(false)
                acquire()
            }
        }
        // killed by the system: Dart starts it again when the app runs
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        lock?.let { if (it.isHeld) it.release() }
        lock = null
        super.onDestroy()
    }

    private fun notification(text: String): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.getNotificationChannel(CHANNEL_ID) == null
        ) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Terminal connection",
                    NotificationManager.IMPORTANCE_MIN,
                ).apply {
                    description = "Shown while the terminal stays connected in the background"
                    setShowBadge(false)
                    setSound(null, null)
                    enableVibration(false)
                },
            )
        }
        val open = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName)
                ?: Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_MIN)
        }
        builder
            .setSmallIcon(R.drawable.ic_stat_delve)
            .setContentTitle(text)
            .setContentIntent(open)
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setCategory(Notification.CATEGORY_SERVICE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_DEFERRED)
        }
        return builder.build()
    }

    companion object {
        const val ACTION_START = "hu.csakos.delve.terminal.KEEP"
        const val ACTION_STOP = "hu.csakos.delve.terminal.STOP"
        const val EXTRA_TEXT = "text"
        private const val CHANNEL_ID = "terminal_keep"
        private const val NOTIFICATION_ID = 7301
        private const val WAKE_LOCK_TAG = "delve:terminal"
    }
}
