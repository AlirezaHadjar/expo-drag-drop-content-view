package expo.modules.dragdropcontentview

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.MediaStore
import android.util.Base64
import android.util.Log
import android.widget.Toast
import java.io.ByteArrayOutputStream
import java.io.FileInputStream
import java.io.IOException

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

    @SuppressLint("Recycle")
    private fun getVideoDimensions(contentResolver: ContentResolver, contentUri: Uri): Pair<Int, Int> {
        val retriever = MediaMetadataRetriever()

        // Use a try-catch block to handle potential issues
        try {
            // Get ParcelFileDescriptor from the content URI
            val parcelFileDescriptor: ParcelFileDescriptor? = contentResolver.openFileDescriptor(contentUri, "r")

            if (parcelFileDescriptor != null) {
                // Get FileDescriptor from ParcelFileDescriptor
                val fileDescriptor = parcelFileDescriptor.fileDescriptor

                // Set data source using FileDescriptor
                retriever.setDataSource(fileDescriptor)

                val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 0
                val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 0

                return Pair(width, height)
            } else {
                Log.e("VideoDimensions", "ParcelFileDescriptor is null")
            }
        } catch (e: IOException) {
            Log.e("VideoDimensions", "Failed to open ParcelFileDescriptor", e)
        } catch (e: IllegalArgumentException) {
            Log.e("VideoDimensions", "Failed to set data source", e)
        } finally {
            retriever.release()
        }

        return Pair(0, 0) // Return default dimensions if something goes wrong
    }

    private fun getVideoDuration(contentResolver: ContentResolver, contentUri: Uri): Long {
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

    private fun getDimension(type: String, contentResolver: ContentResolver, contentUri: Uri): Pair<Int, Int> {
        if (type.startsWith("image/")) return getImageDimensions(contentResolver, contentUri)
        return getVideoDimensions(contentResolver, contentUri)
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
                val isVideo = type.startsWith("video/")
                val isImage = type.startsWith("image/")
                val isMedia = isImage || isVideo
                val fileName = cursorInstance.getString(cursorInstance.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME))
                val dimensions = if (isMedia) getDimension(type, contentResolver, contentUri) else null
                val duration = if (isVideo) getVideoDuration(contentResolver, contentUri) else null
                val base64 = if (includeBase64) getBase64Data(contentResolver, contentUri) else null
                val path = contentUri.path?.substringAfter("content://")


                val fileInfoMap = mutableMapOf<String, Any>(
                    "type" to type,
                    "fileName" to fileName,
                    "uri" to contentUri.toString()
                )
                path?.let { fileInfoMap["path"] = "content://$path" }
                dimensions?.let { (width, height) ->
                    fileInfoMap["width"] = width
                    fileInfoMap["height"] = height
                }
                base64?.let { fileInfoMap["base64"] = it }
                if (isVideo && duration != null) fileInfoMap["duration"] = duration

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
}