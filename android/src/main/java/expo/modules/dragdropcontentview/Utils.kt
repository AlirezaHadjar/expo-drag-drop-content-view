package expo.modules.dragdropcontentview

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.MediaStore
import android.widget.Toast
import java.io.ByteArrayOutputStream
import android.util.Base64
import java.io.File

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
    fun getFileInfo(contentResolver: ContentResolver, contentUri: Uri, includeBase64: Boolean, context: Context): Map<String, Any?>? {
        val projection = arrayOf(
            MediaStore.Images.Media.MIME_TYPE,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.DATA
        )

        val cursor = contentResolver.query(contentUri, projection, null, null, null)

        if (cursor == null) {
            showToast("Not supported", context)
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

    fun getContentUriForFile(context: Context, file: File): Uri? {
        val projection = arrayOf(MediaStore.Images.Media._ID)
        val selection = "${MediaStore.Images.Media.DATA} = ?"
        val selectionArgs = arrayOf(file.absolutePath)
        val sortOrder = null // You can specify sorting order if needed

        val queryUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI

        context.contentResolver.query(queryUri, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                val imageId = cursor.getLong(columnIndex)
                return ContentUris.withAppendedId(queryUri, imageId)
            }
        }

        return null
    }
}