package expo.modules.dragdropcontentview

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import android.widget.Toast
import java.io.ByteArrayOutputStream
import android.util.Base64
import java.io.File
import java.io.FileInputStream

class Utils {
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
    private fun showToast(message: String, context: Context) {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }
    private fun getFilePathFromContentUri(contentResolver: ContentResolver, contentUri: Uri): String? {
        val projection = arrayOf(MediaStore.MediaColumns.DATA)
        val cursor = contentResolver.query(contentUri, projection, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val columnIndex = it.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
                return it.getString(columnIndex)
            }
        }
        return null
    }
    private fun getVideoDimensions(contentResolver: ContentResolver, contentUri: Uri): Pair<Int, Int> {
        val retriever = MediaMetadataRetriever()
        val filePath = getFilePathFromContentUri(contentResolver, contentUri)
        retriever.setDataSource(filePath)
        val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
        val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 0
        return Pair(width, height)
    }

    fun getVideoDuration(contentResolver: ContentResolver, contentUri: Uri): Long {
        var duration: Long = 0
        try {
            val inputStream = contentResolver.openInputStream(contentUri)
            inputStream?.use { stream ->
                val fileDescriptor = (stream as? FileInputStream)?.fd
                if (fileDescriptor != null) {
                    val retriever = MediaMetadataRetriever()
                    retriever.setDataSource(fileDescriptor)
                    duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLong() ?: 0
                    retriever.release()
                }
            }
        } catch (e: Exception) {
            // Handle exceptions
            e.printStackTrace()
        }
        return duration
    }


    fun getFileInfo(contentResolver: ContentResolver, contentUri: Uri, includeBase64: Boolean, context: Context): Map<String, Any?>? {
        val projection = arrayOf(
            MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATA,
            MediaStore.Video.Media.DURATION
        )

        val cursor = contentResolver.query(contentUri, projection, null, null, null)

        if (cursor == null) {
            showToast("Not supported", context)
        }

        cursor?.use { cursorInstance ->
            if (cursorInstance.moveToFirst()) {
                val type = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE))
                val fileName = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME))
                val uri = "file://" + cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA))
                val dimensions = if (type.startsWith("image/")) getImageDimensions(contentResolver, contentUri) else getVideoDimensions(contentResolver, contentUri)
                val duration = if (type.startsWith("video/")) getVideoDuration(contentResolver, contentUri) else 0
                val base64 = if (includeBase64) getBase64Data(contentResolver, contentUri) else null
                val path =  "content://" + contentUri.path?.substringAfter("content://")


                val fileInfoMap = mutableMapOf(
                    "width" to dimensions.first,
                    "height" to dimensions.second,
                    "type" to type,
                    "fileName" to fileName,
                    "uri" to uri,
                    "path" to path,
                )

                // Conditionally add base64 to the map if it's not null
                base64?.let { fileInfoMap["base64"] = it }
                if (type.startsWith("video/")) fileInfoMap["duration"] = duration

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

    fun getContentUriForFile(context: Context, file: File): Uri? {
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection = "${MediaStore.MediaColumns.DATA} = ?"
        val selectionArgs = arrayOf(file.absolutePath)
        val sortOrder: String? = null // You can specify sorting order if needed

        val queryUri = MediaStore.Files.getContentUri("external")

        context.contentResolver.query(queryUri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val mediaId = cursor.getLong(columnIndex)
                return ContentUris.withAppendedId(queryUri, mediaId)
            }
        }

        return null
    }
}