package hu.csakos.delve

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.net.URI
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * What notification mirroring keeps on the phone (DA2b), on the native side
 * because NotificationMirrorService runs without the Flutter engine too:
 *
 *  - the main switch and the chosen apps;
 *  - the apps that have posted a notification the mirror could send (package,
 *    name, when last) – the page's list; never a notification's content;
 *  - a copy of the server's address and the device token, while mirroring is
 *    on: sealed with a key of the Android Keystore that never leaves it
 *    (AES-GCM), in this app's private preferences (the app allows no backup).
 *    The Dart side hands it over and takes it back (MIRROR_CHANNEL); unpairing
 *    wipes everything here.
 */
internal object MirrorStore {
    class Credentials(val server: String, val token: String)

    class SeenApp(val pkg: String, val label: String, val last: Long, val selected: Boolean)

    private class Seen(val label: String, var last: Long, var written: Long)

    private const val PREFS = "delve.mirror"
    private const val K_ENABLED = "enabled"
    private const val K_SELECTED = "selected"
    private const val K_SEEN = "seen"
    private const val K_CREDENTIALS = "credentials"
    private const val KEY_ALIAS = "delve.mirror.v1"
    private const val KEYSTORE = "AndroidKeyStore"
    private const val SEEN_MAX = 80

    /** A chat app posts all the time: its "last" time goes to disk this often. */
    private const val SEEN_WRITE_MS = 60_000L
    private const val TOKEN_MAX = 512

    private val lock = Any()
    private var loaded = false
    private var enabled = false
    private var selected: Set<String> = emptySet()
    private val seen = HashMap<String, Seen>()
    private var credentials: Credentials? = null

    private fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun load(context: Context) {
        if (loaded) return
        val p = prefs(context)
        enabled = p.getBoolean(K_ENABLED, false)
        selected = HashSet(p.getStringSet(K_SELECTED, null) ?: emptySet())
        seen.clear()
        for (line in p.getStringSet(K_SEEN, null) ?: emptySet()) {
            val parts = line.split('\t', limit = 3)
            val last = parts.getOrNull(0)?.toLongOrNull()
            if (parts.size == 3 && last != null && parts[1].isNotEmpty()) {
                seen[parts[1]] = Seen(parts[2], last, last)
            }
        }
        credentials = p.getString(K_CREDENTIALS, null)?.let { open(it) }?.let { plain ->
            val cut = plain.indexOf('\n')
            if (cut <= 0) null else Credentials(plain.substring(0, cut), plain.substring(cut + 1))
        }
        loaded = true
    }

    fun enabled(context: Context): Boolean = synchronized(lock) {
        load(context)
        enabled
    }

    fun setEnabled(context: Context, on: Boolean) = synchronized(lock) {
        load(context)
        enabled = on
        prefs(context).edit().putBoolean(K_ENABLED, on).apply()
    }

    fun setSelected(context: Context, pkg: String, on: Boolean) = synchronized(lock) {
        load(context)
        selected = if (on) selected + pkg else selected - pkg
        prefs(context).edit().putStringSet(K_SELECTED, HashSet(selected)).apply()
    }

    /** The app's notifications go out now: on, chosen, and there is a server to send to. */
    fun wants(context: Context, pkg: String): Boolean = synchronized(lock) {
        load(context)
        enabled && credentials != null && pkg in selected
    }

    /** The server and the token, while mirroring is on. */
    fun sending(context: Context): Credentials? = synchronized(lock) {
        load(context)
        if (enabled) credentials else null
    }

    fun hasCredentials(context: Context): Boolean = synchronized(lock) {
        load(context)
        credentials != null
    }

    /** [pkg] posted something the mirror could send. */
    fun noteSeen(context: Context, pkg: String, label: String, now: Long) = synchronized(lock) {
        load(context)
        val known = seen[pkg]
        if (known != null && known.label == label) {
            known.last = now
            if (now - known.written < SEEN_WRITE_MS) return@synchronized
            known.written = now
        } else {
            seen[pkg] = Seen(label, now, now)
            while (seen.size > SEEN_MAX) {
                // the one silent for the longest goes, unless it is chosen
                val oldest = seen.entries.filter { it.key !in selected }.minByOrNull { it.value.last }
                    ?: break
                seen.remove(oldest.key)
            }
        }
        prefs(context).edit()
            .putStringSet(K_SEEN, seen.mapTo(HashSet()) { (p, s) -> "${s.last}\t$p\t${s.label}" })
            .apply()
    }

    /** The page's list: by name. A chosen app stays listed. */
    fun apps(context: Context): List<SeenApp> = synchronized(lock) {
        load(context)
        val out = seen.map { (p, s) -> SeenApp(p, s.label, s.last, p in selected) }.toMutableList()
        for (p in selected) if (p !in seen) out.add(SeenApp(p, p, 0, true))
        out.sortedWith(compareBy({ it.label.lowercase() }, { it.pkg }))
    }

    /**
     * Keeps the server's origin and the token. false: not an https origin, no
     * usable token, or the Keystore refused.
     */
    fun setCredentials(context: Context, server: String, token: String): Boolean = synchronized(lock) {
        load(context)
        val origin = origin(server) ?: return@synchronized false
        if (token.isEmpty() || token.length > TOKEN_MAX || token.any { it <= ' ' || it > '~' }) {
            return@synchronized false
        }
        val known = credentials
        if (known != null && known.server == origin && known.token == token) return@synchronized true
        val sealed = seal("$origin\n$token") ?: return@synchronized false
        credentials = Credentials(origin, token)
        prefs(context).edit().putString(K_CREDENTIALS, sealed).apply()
        true
    }

    fun clearCredentials(context: Context) = synchronized(lock) {
        load(context)
        credentials = null
        prefs(context).edit().remove(K_CREDENTIALS).apply()
    }

    /** Unpaired: nothing of the mirror stays, the Keystore key goes too. */
    fun wipe(context: Context) = synchronized(lock) {
        enabled = false
        selected = emptySet()
        seen.clear()
        credentials = null
        loaded = true
        prefs(context).edit().clear().apply()
        try {
            KeyStore.getInstance(KEYSTORE).apply { load(null) }.deleteEntry(KEY_ALIAS)
        } catch (e: Exception) {
            // no key, nothing to delete
        }
    }

    /** `https://host[:port]`, or null for anything else. */
    private fun origin(server: String): String? = try {
        val uri = URI(server.trim())
        val host = uri.host
        when {
            !"https".equals(uri.scheme, ignoreCase = true) -> null
            host.isNullOrEmpty() || uri.rawUserInfo != null -> null
            !uri.rawPath.isNullOrEmpty() && uri.rawPath != "/" -> null
            uri.rawQuery != null || uri.rawFragment != null -> null
            else -> "https://$host" + (if (uri.port >= 0) ":${uri.port}" else "")
        }
    } catch (e: Exception) {
        null
    }

    private fun key(): SecretKey {
        val store = KeyStore.getInstance(KEYSTORE).apply { load(null) }
        (store.getKey(KEY_ALIAS, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, KEYSTORE)
        generator.init(
            KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    /** base64(iv length, iv, ciphertext + tag); null: the Keystore refused. */
    private fun seal(plain: String): String? = try {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val iv = cipher.iv
        val sealed = cipher.doFinal(plain.toByteArray(Charsets.UTF_8))
        Base64.encodeToString(byteArrayOf(iv.size.toByte()) + iv + sealed, Base64.NO_WRAP)
    } catch (e: Exception) {
        null
    }

    /** null: not readable any more (the key is gone) – the app hands it over again. */
    private fun open(sealed: String): String? = try {
        val all = Base64.decode(sealed, Base64.NO_WRAP)
        val n = all[0].toInt()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, all, 1, n))
        String(cipher.doFinal(all, 1 + n, all.size - 1 - n), Charsets.UTF_8)
    } catch (e: Exception) {
        null
    }
}
