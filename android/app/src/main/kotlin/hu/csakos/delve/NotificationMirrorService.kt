package hu.csakos.delve

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.os.SystemClock
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Notification mirroring, phone to desktop (DA2b): the notifications of the
 * apps chosen in More → Mirroring go to the backend, which hands them to the
 * desktop agent (delve-infra `bin/delve-desk`).
 *
 * The system binds this service once the user allows notification access,
 * and keeps it bound without the app's screen – so the filter, the settings
 * (MirrorStore) and the sending (MirrorSender) are all on this side.
 *
 * What goes out: a post per notification key (the same key again replaces it
 * on the desktop) with the app's name, the title, the text and the category;
 * a remove when it leaves the phone's shade, whatever the reason. What never
 * goes out: an app that is not chosen, Delve's own notifications, ongoing
 * ones (players, "running in the background"), group summaries, and the
 * content Android hides from listeners (one-time codes: the desktop only
 * learns that something arrived). Nothing is kept of any of it here beyond
 * "this app posted at this time" for the page's list.
 */
class NotificationMirrorService : NotificationListenerService() {
    override fun onListenerConnected() {
        connected = true
    }

    override fun onListenerDisconnected() {
        connected = false
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        try {
            posted(sbn)
        } catch (e: Exception) {
            // an odd notification must not take the listener down
        }
    }

    // the one-argument form: the system's other two end up here on every Android
    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        try {
            removed(sbn)
        } catch (e: Exception) {
            // as above
        }
    }

    private fun posted(sbn: StatusBarNotification) {
        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return
        val n = sbn.notification ?: return
        if (!MirrorRules.mirrorable(sbn.isClearable, sbn.isOngoing, n.flags)) return
        val label = label(pkg)
        MirrorStore.noteSeen(this, pkg, label, System.currentTimeMillis())
        if (!MirrorStore.wants(this, pkg)) return
        val key = sbn.key ?: return
        if (key.isEmpty() || key.length > MirrorWire.KEY_MAX) return

        val x: Bundle = n.extras ?: Bundle()
        val ownTitle = text(x, Notification.EXTRA_TITLE)
        var body = text(x, Notification.EXTRA_TEXT)
        if (body.isEmpty()) body = text(x, Notification.EXTRA_BIG_TEXT)
        val hidden = MirrorRules.hidden(ownTitle, body, label, extrasLabel(x))
        val title = MirrorWire.line(ownTitle.ifEmpty { text(x, Notification.EXTRA_CONVERSATION_TITLE) })
        if (!hidden && title.isEmpty() && body.isEmpty()) return

        val event = MirrorEvent(
            remove = false,
            key = key,
            app = label,
            title = if (hidden) null else MirrorWire.clip(title, MirrorWire.TITLE_MAX),
            text = if (hidden) null else MirrorWire.clip(body, MirrorWire.TEXT_MAX),
            category = MirrorWire.category(n.category),
            hidden = hidden,
            at = SystemClock.elapsedRealtime(),
        )
        // The same notification posted again as it was (same content, same time, no new
        // message in it) is nothing new for the desktop. "ok" twice in a chat is: the
        // second one has a later time and one more message.
        @Suppress("DEPRECATION")
        val messages = x.getParcelableArray(Notification.EXTRA_MESSAGES)?.size ?: 0
        val stamp = 31 * (31 * event.copy(at = 0).hashCode() + n.`when`.hashCode()) + messages
        if (!sentBefore.fresh(key, stamp)) return
        MirrorSender.offer(this, event)
    }

    private fun removed(sbn: StatusBarNotification) {
        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return
        val n = sbn.notification ?: return
        if (!MirrorRules.mirrorable(sbn.isClearable, sbn.isOngoing, n.flags)) return
        if (!MirrorStore.wants(this, pkg)) return
        val key = sbn.key ?: return
        if (key.isEmpty() || key.length > MirrorWire.KEY_MAX) return
        sentBefore.forget(key)
        MirrorSender.offer(
            this,
            MirrorEvent(remove = true, key = key, at = SystemClock.elapsedRealtime()),
        )
    }

    private fun text(x: Bundle, key: String): String = x.getCharSequence(key)?.toString()?.trim() ?: ""

    /** The app's name as the launcher shows it; its package when the system will not say. */
    private fun label(pkg: String): String {
        val name = try {
            packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
        } catch (e: Exception) {
            pkg
        }
        return MirrorWire.clip(MirrorWire.line(name).ifEmpty { pkg }, MirrorWire.APP_MAX)
    }

    /** The name the notification itself carries ("Android System" on a hidden one). */
    private fun extrasLabel(x: Bundle): String? = try {
        @Suppress("DEPRECATION")
        val info = x.getParcelable<ApplicationInfo>("android.appInfo")
        info?.loadLabel(packageManager)?.toString()
            ?.let { MirrorWire.clip(MirrorWire.line(it), MirrorWire.APP_MAX) }
    } catch (e: Exception) {
        null
    }

    companion object {
        /** The system has this listener bound right now. */
        @Volatile
        var connected = false
            private set

        private val sentBefore = MirrorDedupe()

        fun component(context: Context) =
            ComponentName(context, NotificationMirrorService::class.java)

        /** Turned off or unpaired: the next post of a key is new again. */
        fun forgetSent() = sentBefore.clear()
    }
}
