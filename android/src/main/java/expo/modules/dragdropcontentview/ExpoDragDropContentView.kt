package expo.modules.dragdropcontentview

import android.app.Activity
import android.content.ContentResolver
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.MediaStore
import android.util.Log
import androidx.draganddrop.DropHelper
import expo.modules.kotlin.AppContext
import android.view.View
import androidx.core.content.ContextCompat
import androidx.core.view.ContentInfoCompat
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView

class ExpoDragDropContentView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
    private val onDropEvent by EventDispatcher()

    private fun getFilePath(contentResolver: ContentResolver, contentUri: Uri): String? {
        val projection = arrayOf(MediaStore.Images.Media.DATA)
        var cursor: Cursor? = null

        try {
            cursor = contentResolver.query(contentUri, projection, null, null, null)
            cursor?.let {
                val columnIndex = it.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                if (it.moveToFirst()) {
                    return it.getString(columnIndex)
                }
            }
        } finally {
            cursor?.close()
        }

        return null
    }
    init {
        var activity = appContext.activityProvider?.currentActivity
        val contentResolver = context.contentResolver

        DropHelper.configureView(
                activity!!,
                this,
                arrayOf ("image/*"),
                DropHelper.Options.Builder()
                        .setHighlightColor(ContextCompat.getColor(context, R.color.highlight_color))
                        .build()) {view, payload ->
            val contentUri = payload.clip.getItemAt(0).uri
            val filePath = getFilePath(contentResolver, contentUri)
            onDropEvent(mapOf("assets" to filePath!!))
            return@configureView payload

        }

    }
}
