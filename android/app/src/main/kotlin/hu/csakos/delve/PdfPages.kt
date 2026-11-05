package hu.csakos.delve

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

/**
 * PDFs for the Files preview with Android's own PdfRenderer (no library).
 * Everything runs on one thread of its own: a PdfRenderer is not
 * thread-safe and has one page open at a time. Pages come back as JPEG
 * (several times faster to encode than PNG; at 1.5× the screen's pixels the
 * text stays sharp).
 */
class PdfPages {
    private val worker = Executors.newSingleThreadExecutor()

    /** Open documents by id; touched only on [worker]. */
    private val docs = HashMap<Int, PdfRenderer>()
    private var next = 1

    /** Runs [block] on the PDF thread and hands its outcome to [done]. */
    fun run(block: () -> Any?, done: (Result<Any?>) -> Unit) {
        worker.execute { done(runCatching(block)) }
    }

    /** Opens [path]: `{id, pages: [[width, height] in points, …]}`. */
    fun open(path: String): Map<String, Any> {
        val fd = ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY)
        val renderer = try {
            PdfRenderer(fd) // owns the descriptor from here
        } catch (e: Exception) {
            fd.close()
            throw e
        }
        val sizes = ArrayList<List<Int>>(renderer.pageCount)
        for (i in 0 until renderer.pageCount) {
            val page = renderer.openPage(i)
            try {
                sizes.add(listOf(page.width, page.height))
            } finally {
                page.close()
            }
        }
        val id = next++
        docs[id] = renderer
        return mapOf("id" to id, "pages" to sizes)
    }

    /** Page [index] of document [id], [width] pixels wide, as JPEG. */
    fun render(id: Int, index: Int, width: Int): ByteArray {
        val renderer = docs[id] ?: throw IllegalStateException("closed")
        val page = renderer.openPage(index)
        try {
            var w = width.coerceIn(1, MAX_SIDE)
            var h = (w.toDouble() * page.height / page.width).toInt()
            if (h > MAX_SIDE) {
                h = MAX_SIDE
                w = (h.toDouble() * page.width / page.height).toInt()
            }
            val bitmap = Bitmap.createBitmap(w.coerceAtLeast(1), h.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
            try {
                // the page draws only its content: paper is white
                bitmap.eraseColor(Color.WHITE)
                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                val out = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, out)
                return out.toByteArray()
            } finally {
                bitmap.recycle()
            }
        } finally {
            page.close()
        }
    }

    fun close(id: Int) {
        docs.remove(id)?.close()
    }

    /** Closes every document and the thread (the activity ends). */
    fun shutdown() {
        worker.execute {
            docs.values.forEach { it.close() }
            docs.clear()
        }
        worker.shutdown()
    }

    companion object {
        /** No page bitmap larger than this on either side (memory). */
        private const val MAX_SIDE = 4096

        private const val JPEG_QUALITY = 90

        /** The error code Dart sees: password, damaged, anything else. */
        fun code(e: Throwable): String = when (e) {
            is SecurityException -> "pdfLocked"
            is IOException -> "pdfBroken"
            else -> "pdfFailed"
        }
    }
}
