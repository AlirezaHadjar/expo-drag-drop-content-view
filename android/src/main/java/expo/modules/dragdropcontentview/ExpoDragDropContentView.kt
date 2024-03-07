package expo.modules.dragdropcontentview

import android.content.ClipData
import android.content.ClipDescription.MIMETYPE_TEXT_PLAIN
import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Base64
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.core.view.DragStartHelper
import androidx.draganddrop.DropHelper
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView
import java.io.ByteArrayOutputStream
import java.io.File

class ExpoDragDropContentView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
    private var includeBase64 = false
    private var draggableImageUris: List<String> = emptyList()
    private var highlightColor = ContextCompat.getColor(context, R.color.highlight_color)
    private var highlightBorderRadius = 0
    private val onDropEvent by EventDispatcher()

    fun setIncludeBase64(value: Boolean?) {
        includeBase64 = value ?: false
    }

    fun setDraggableImageUris(value: List<String>?) {
        draggableImageUris = value ?: emptyList()
    }

    fun setHighlightBorderRadius(value: Int?) {
        if (value != null) {
            highlightBorderRadius = value
            configureDropHelper()
        }
    }

    fun setHighlightColor(value: Int?) {
        if (value != null) {
            highlightColor = value
            configureDropHelper()
        }
    }

    private fun getImageDimensions(contentResolver: ContentResolver, contentUri: Uri): Pair<Int, Int> {
        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true

        try {
            // Use BitmapFactory to obtain image dimensions without loading the entire image into memory
            BitmapFactory.decodeStream(contentResolver.openInputStream(contentUri), null, options)
            return Pair(options.outWidth, options.outHeight)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return Pair(0, 0)
    }
    private fun showToast(message: String) {
        Toast.makeText(this.context, message, Toast.LENGTH_SHORT).show()
    }
    private fun getFileInfo(contentResolver: ContentResolver, contentUri: Uri): Map<String, Any?>? {
        val projection = arrayOf(
            MediaStore.Images.Media.MIME_TYPE,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATA
        )

        val cursor = contentResolver.query(contentUri, projection, null, null, null)

        if (cursor == null) {
            showToast("Not supported")
        }

        cursor?.use { cursorInstance ->
            if (cursorInstance.moveToFirst()) {
                val type = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE))
                val fileName = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME))
                val uri = "file://" + cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(MediaStore.Images.Media.DATA))
                val dimensions = getImageDimensions(contentResolver, contentUri)
                val base64 = if (includeBase64) getBase64Data(contentResolver, contentUri) else null
                val path = contentUri.path?.replace("/-1/1/", "")

                val fileInfoMap = mutableMapOf(
                    "width" to dimensions.first,
                    "height" to dimensions.second,
                    "type" to type,
                    "fileName" to fileName,
                    "uri" to uri,
                    "path" to path
                )

                // Conditionally add base64 to the map if it's not null
                base64?.let { fileInfoMap["base64"] = it }

                return fileInfoMap
            }
        }


        return null
    }

    private fun getBase64Data(contentResolver: ContentResolver, contentUri: Uri): String? {
        try {
            // Use BitmapFactory to decode the image
            val bitmap = BitmapFactory.decodeStream(contentResolver.openInputStream(contentUri))

            // Use a ByteArrayOutputStream to compress the bitmap to a byte array
            val byteArrayOutputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 100, byteArrayOutputStream)
            val byteArray = byteArrayOutputStream.toByteArray()

            // Use Base64 to encode the byte array to a base64 string
            return Base64.encodeToString(byteArray, Base64.DEFAULT)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return null
    }

    private fun getContentUriForFile(context: Context, file: File): Uri? {
        val projection = arrayOf(MediaStore.Images.Media._ID)
        val selection = "${MediaStore.Images.Media.DATA} = ?"
        val selectionArgs = arrayOf(file.absolutePath)
        val sortOrder = null // You can specify sorting order if needed

        val queryUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        Log.d("Query", queryUri.toString())
        Log.d("absolutedd", file.absoluteFile.toString())

        context.contentResolver.query(queryUri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                val imageId = cursor.getLong(columnIndex)
                return ContentUris.withAppendedId(queryUri, imageId)
            }
        }

        return null
    }

    private fun configureDropHelper() {
        // DropHelper is only available on Android N and above
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return

        val activity = appContext.activityProvider?.currentActivity!!
        val contentResolver = context.contentResolver

        DropHelper.configureView(
            activity,
            this,
            arrayOf("image/*"),
            DropHelper.Options.Builder()
                .setHighlightColor(highlightColor)
                .setHighlightCornerRadiusPx(highlightBorderRadius)
                .build()
        ) { _, payload ->
            val clipData = payload.clip
            val infoList = mutableListOf<Map<String, Any?>>()

            for (i in 0 until clipData.itemCount) {
                val contentUri = clipData.getItemAt(i).uri
                Log.d("first item", clipData.getItemAt(i).toString())
                if (contentUri != null) {
                    val info = getFileInfo(contentResolver, contentUri)
                    info?.let { infoList.add(it) }
                }
            }
            if (infoList.isNotEmpty()) onDropEvent(mapOf("assets" to infoList))
            return@configureView payload
        }

        DragStartHelper(this) { view, _ ->
            val data: MutableList<Uri> = mutableListOf()

            for (imageUri in draggableImageUris) {
                val path = Uri.parse(imageUri).path

                if (!path.isNullOrBlank()) {
                    val file = File(path)
                    Log.d("file is here", file.toString())
                    val uri = getContentUriForFile(this.context, file)
                    Log.d("uri is here", uri.toString())
                    uri?.let { data.add(it) }
                }
            }

            // Create a drag shadow builder
            val shadow = DragShadowBuilder(view)

            if (data.isNotEmpty()) {
                val clipData = ClipData.newUri(contentResolver, "Image", data[0])

                for (i in 1 until data.size) {
                    clipData.addItem(ClipData.Item(data[i]))
                }
                // Start the drag and drop operation
                view.startDragAndDrop(clipData, shadow, null, DRAG_FLAG_GLOBAL or DRAG_FLAG_GLOBAL_URI_READ)
            }
           else {
                val clipData2 = ClipData.newUri(contentResolver, "Image", Uri.parse(""))
                view.startDragAndDrop(clipData2, shadow, null, DRAG_FLAG_GLOBAL or DRAG_FLAG_GLOBAL_URI_READ)
            }
        }.attach()
    }

    init {
        configureDropHelper()
    }
}
