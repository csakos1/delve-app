package hu.csakos.delve

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.Base64
import java.io.ByteArrayOutputStream

/**
 * The posting app's launcher icon for a mirrored notification (DA2b): a small
 * PNG as base64, the way `POST /api/v1/mirror/phone` takes it (`icon`, at most
 * 32 KiB of PNG). Drawn once per app while this process lives; an app whose
 * icon cannot be had (or will not fit) simply goes without.
 */
internal object MirrorIcons {
    private const val SIDE = 96
    private const val SMALLER = 48
    private const val PNG_MAX = 32 * 1024
    private const val KEPT = 80

    /** Package to base64; "" for an app that has none to send. */
    private val made = LinkedHashMap<String, String>()

    fun of(context: Context, pkg: String): String? = synchronized(made) {
        val known = made[pkg]
        if (known != null) return@synchronized known.ifEmpty { null }
        val icon = try {
            render(context, pkg, SIDE) ?: render(context, pkg, SMALLER)
        } catch (e: Exception) {
            null
        } catch (e: OutOfMemoryError) {
            null
        }
        made[pkg] = icon ?: ""
        while (made.size > KEPT) made.remove(made.keys.first())
        icon
    }

    /** null: the PNG came out larger than the backend takes. */
    private fun render(context: Context, pkg: String, side: Int): String? {
        val drawable = context.packageManager.getApplicationIcon(pkg)
        val bitmap = Bitmap.createBitmap(side, side, Bitmap.Config.ARGB_8888)
        try {
            drawable.setBounds(0, 0, side, side)
            drawable.draw(Canvas(bitmap))
            val out = ByteArrayOutputStream()
            if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)) return null
            if (out.size() > PNG_MAX) return null
            return Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
        } finally {
            bitmap.recycle()
        }
    }
}
