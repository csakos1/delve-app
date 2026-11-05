package hu.csakos.delve

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.Environment
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.provider.Settings
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterFragmentActivity
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
 *
 * A FlutterFragmentActivity: local_auth's BiometricPrompt (the terminal's
 * lock) needs a FragmentActivity.
 *
 * A second channel (TERMINAL_CHANNEL) starts and stops TerminalKeepService
 * (the terminal stays connected in the background, T4) and asks for the
 * battery-optimization exemption it needs.
 *
 * A third one (FILES_CHANNEL) serves the Files tab (F1): a scratch folder
 * in the cache, moving a finished download into Downloads/Delve through
 * MediaStore (no storage permission), opening it in another app, and the
 * PDF preview's pages (PdfPages).
 */
class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null
    private var terminal: MethodChannel? = null
    private var files: MethodChannel? = null
    private var pending: Intent? = null
    private val io = Executors.newSingleThreadExecutor()
    private val pdfs = PdfPages()
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
        terminal = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TERMINAL_CHANNEL,
        ).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> result.success(startKeep(call.argument<String>("text") ?: ""))
                    "stop" -> {
                        stopService(Intent(this, TerminalKeepService::class.java))
                        result.success(null)
                    }
                    "batteryExempt" -> result.success(batteryExempt())
                    "requestBatteryExempt" -> result.success(requestBatteryExempt())
                    else -> result.notImplemented()
                }
            }
        }
        files = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILES_CHANNEL,
        ).also {
            it.setMethodCallHandler { call, result ->
                when (call.method) {
                    "scratchDir" -> {
                        val dir = File(cacheDir, FILES_DIR)
                        dir.mkdirs()
                        result.success(dir.absolutePath)
                    }
                    "publish" -> {
                        val path = call.argument<String>("path")
                        val name = call.argument<String>("name")
                        val mime = call.argument<String>("mime")
                        if (path == null || name == null) {
                            result.error("args", "path and name", null)
                        } else {
                            io.execute {
                                try {
                                    val uri = publish(File(path), name, mime)
                                    main.post { result.success(uri) }
                                } catch (e: Exception) {
                                    main.post { result.error("publish", e.message ?: "$e", null) }
                                }
                            }
                        }
                    }
                    "open" -> result.success(
                        openUri(call.argument<String>("uri"), call.argument<String>("mime")),
                    )
                    "pdfOpen" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("args", "path", null)
                        } else {
                            pdfCall(result) { pdfs.open(path) }
                        }
                    }
                    "pdfRender" -> {
                        val id = call.argument<Int>("id")
                        val page = call.argument<Int>("page")
                        val width = call.argument<Int>("width")
                        if (id == null || page == null || width == null) {
                            result.error("args", "id, page and width", null)
                        } else {
                            pdfCall(result) { pdfs.render(id, page, width) }
                        }
                    }
                    "pdfClose" -> {
                        val id = call.argument<Int>("id")
                        if (id == null) {
                            result.error("args", "id", null)
                        } else {
                            pdfCall(result) { pdfs.close(id) }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /** Runs a PDF call on the PDF thread, answers on the main thread. */
    private fun pdfCall(result: MethodChannel.Result, block: () -> Any?) {
        pdfs.run(block) { outcome ->
            main.post {
                outcome.fold(
                    { result.success(if (it is Unit) null else it) },
                    { e -> result.error(PdfPages.code(e), e.message ?: "$e", null) },
                )
            }
        }
    }

    /**
     * Moves [src] into Downloads/Delve as [name] (MediaStore renames it when
     * the name is taken) and returns the entry's content URI. Pending until
     * the copy is complete, so no half file shows up in other apps.
     */
    @android.annotation.TargetApi(Build.VERSION_CODES.Q)
    private fun publish(src: File, name: String, mime: String?): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw IllegalStateException("Android 10 or newer is needed")
        }
        val resolver = contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name)
            if (mime != null) put(MediaStore.Downloads.MIME_TYPE, mime)
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Delve")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("MediaStore refused the entry")
        try {
            val out = resolver.openOutputStream(uri) ?: throw IllegalStateException("not writable")
            out.use { dst -> src.inputStream().use { it.copyTo(dst, 256 * 1024) } }
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        } finally {
            src.delete()
        }
        return uri.toString()
    }

    private fun openUri(uri: String?, mime: String?): Boolean {
        if (uri == null) return false
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(Uri.parse(uri), mime ?: "*/*")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /** Starts (or updates the text of) the keep-alive service; false: not allowed now. */
    private fun startKeep(text: String): Boolean {
        val intent = Intent(this, TerminalKeepService::class.java)
            .setAction(TerminalKeepService.ACTION_START)
            .putExtra(TerminalKeepService.EXTRA_TEXT, text)
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun batteryExempt(): Boolean {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        return power.isIgnoringBatteryOptimizations(packageName)
    }

    /** The system dialog that exempts Delve; false: it could not be shown. */
    @android.annotation.SuppressLint("BatteryLife")
    private fun requestBatteryExempt(): Boolean {
        if (batteryExempt()) return true
        return try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    .setData(Uri.parse("package:$packageName")),
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) {
            // copies of earlier shares and leftovers of downloads; the
            // executor runs this before any take
            io.execute {
                File(cacheDir, SHARED_DIR).deleteRecursively()
                File(cacheDir, FILES_DIR).deleteRecursively()
            }
            keep(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (keep(intent)) channel?.invokeMethod("changed", null)
    }

    override fun onDestroy() {
        channel?.setMethodCallHandler(null)
        terminal?.setMethodCallHandler(null)
        files?.setMethodCallHandler(null)
        io.shutdown()
        pdfs.shutdown()
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
        private const val TERMINAL_CHANNEL = "hu.csakos.delve/terminal"
        private const val FILES_CHANNEL = "hu.csakos.delve/files"
        private const val FILES_DIR = "files"
        private const val SHARED_DIR = "shared"

        /** Attachments per message (decision 336). */
        private const val MAX_FILES = 4

        /** Files over this are not copied (the server takes 20 MiB). */
        private const val MAX_FILE_COPY = 20L * 1024 * 1024

        /** Photos are resized on the phone, so a larger original is fine. */
        private const val MAX_IMAGE_COPY = 64L * 1024 * 1024
    }
}
