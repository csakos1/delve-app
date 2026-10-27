package hu.csakos.delve

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

/**
 * "Share to Delve": photos, files and text from other apps.
 *
 * The share intent is kept until Dart asks for it ("take"), so a share that
 * arrives before the Flutter side listens is not lost. A share while the app
 * runs comes through onNewIntent (singleTask) and is announced with
 * "changed"; Dart then takes it. The shared items are copied into the app's
 * cache (cacheDir/shared/<uuid>/<name>) on a background thread, at most
 * MAX_FILES of them; Dart reads the copies like picked files.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pending: Intent? = null
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "take" -> take(result)
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) {
            // copies of earlier shares; the executor runs this before any take
            io.execute { File(cacheDir, SHARED_DIR).deleteRecursively() }
            keep(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (keep(intent)) channel?.invokeMethod("changed", null)
    }

    override fun onDestroy() {
        channel?.setMethodCallHandler(null)
        io.shutdown()
        super.onDestroy()
    }

    /** A share intent, not one replayed from the recents screen. */
    private fun keep(intent: Intent?): Boolean {
        if (intent == null) return false
        if ((intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) != 0) return false
        if (intent.action != Intent.ACTION_SEND && intent.action != Intent.ACTION_SEND_MULTIPLE) {
            return false
        }
        pending = intent
        return true
    }

    private fun take(result: MethodChannel.Result) {
        val intent = pending
        pending = null
        if (intent == null) {
            result.success(null)
            return
        }
        io.execute {
            val payload: Map<String, Any?> = try {
                read(intent)
            } catch (e: Exception) {
                mapOf("files" to emptyList<Any>(), "text" to null, "skipped" to 0, "failed" to 1)
            }
            main.post { result.success(payload) }
        }
    }

    private fun read(intent: Intent): Map<String, Any?> {
        // content:// only: a file:// path could point into this app's own data
        val uris = streams(intent).filter { it.scheme == "content" }.distinct()
        val files = mutableListOf<Map<String, Any?>>()
        var failed = 0
        for (uri in uris.take(MAX_FILES)) {
            try {
                files.add(copy(uri, intent.type))
            } catch (e: Exception) {
                failed++
            }
        }
        return mapOf(
            "files" to files,
            "text" to text(intent),
            "skipped" to (uris.size - MAX_FILES).coerceAtLeast(0),
            "failed" to failed,
        )
    }

    private fun streams(intent: Intent): List<Uri> {
        val out = mutableListOf<Uri>()
        if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            val list: List<Uri>? = if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
            }
            if (list != null) out.addAll(list)
        } else {
            val one: Uri? = if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            if (one != null) out.add(one)
        }
        // some apps only fill the clip data
        if (out.isEmpty()) {
            val clip = intent.clipData
            if (clip != null) {
                for (i in 0 until clip.itemCount) {
                    val u = clip.getItemAt(i).uri
                    if (u != null) out.add(u)
                }
            }
        }
        return out
    }

    /** Subject and text; a link shared from a browser comes with its title. */
    private fun text(intent: Intent): String? {
        val body = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()?.trim().orEmpty()
        val subject = intent.getStringExtra(Intent.EXTRA_SUBJECT)?.trim().orEmpty()
        val joined = when {
            body.isEmpty() -> subject
            subject.isEmpty() || body.contains(subject) -> body
            else -> "$subject\n$body"
        }
        return joined.ifEmpty { null }
    }

    /** Copies one shared item; over the size cap only its name and size. */
    private fun copy(uri: Uri, intentType: String?): Map<String, Any?> {
        val resolver = contentResolver
        var displayName: String? = null
        var declared: Long? = null
        resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)
            ?.use { c ->
                if (c.moveToFirst()) {
                    val n = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    val s = c.getColumnIndex(OpenableColumns.SIZE)
                    if (n >= 0 && !c.isNull(n)) displayName = c.getString(n)
                    if (s >= 0 && !c.isNull(s)) declared = c.getLong(s)
                }
            }
        val mime = resolver.getType(uri) ?: intentType?.takeIf { !it.contains('*') }
        val name = safeName(displayName ?: uri.lastPathSegment, mime)
        val cap = if (mime?.startsWith("image/") == true) MAX_IMAGE_COPY else MAX_FILE_COPY
        val known = declared ?: 0L
        if (known > cap) {
            return mapOf("name" to name, "mime" to mime, "size" to known, "path" to null)
        }
        val dir = File(File(cacheDir, SHARED_DIR), UUID.randomUUID().toString())
        if (!dir.mkdirs()) throw IllegalStateException("no cache dir")
        val out = File(dir, name)
        var copied = 0L
        val input = resolver.openInputStream(uri) ?: throw IllegalStateException("unreadable")
        input.use { src ->
            out.outputStream().use { dst ->
                val buf = ByteArray(64 * 1024)
                while (true) {
                    val n = src.read(buf)
                    if (n < 0) break
                    copied += n
                    if (copied > cap) break
                    dst.write(buf, 0, n)
                }
            }
        }
        if (copied > cap) {
            dir.deleteRecursively()
            return mapOf("name" to name, "mime" to mime, "size" to copied, "path" to null)
        }
        return mapOf("name" to name, "mime" to mime, "size" to copied, "path" to out.absolutePath)
    }

    /** The last path part, without control characters or leading dots; an extension from the type when it has none. */
    private fun safeName(raw: String?, mime: String?): String {
        var n = (raw ?: "").substringAfterLast('/')
            .filter { it >= ' ' && it != '\u007f' }
            .trim()
            .trimStart('.')
        if (n.length > 120) n = n.takeLast(120)
        if (n.isEmpty()) n = "shared"
        if (!n.contains('.') && mime != null) {
            val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mime)
            if (ext != null) n = "$n.$ext"
        }
        return n
    }

    companion object {
        private const val CHANNEL = "hu.csakos.delve/share"
        private const val SHARED_DIR = "shared"

        /** Attachments per message (decision 336). */
        private const val MAX_FILES = 4

        /** Files over this are not copied (the server takes 20 MiB). */
        private const val MAX_FILE_COPY = 20L * 1024 * 1024

        /** Photos are resized on the phone, so a larger original is fine. */
        private const val MAX_IMAGE_COPY = 64L * 1024 * 1024
    }
}
