package expo.modules.dragdropcontentview

import android.annotation.SuppressLint
import android.content.ClipData
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.DragEvent
import android.view.MotionEvent
import androidx.core.view.DragStartHelper
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView
import android.view.View
import android.view.ViewGroup
import expo.modules.dragdropcontentview.records.DraggableItem
import expo.modules.dragdropcontentview.records.DraggableType
import java.io.File

@SuppressLint("ViewConstructor")
class ExpoDragDropContentView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
    private var includeBase64 = false
    private var draggableSources: List<DraggableItem> = emptyList()
    private var allowedMimeTypes: List<String>? = null
    private val onDrop by EventDispatcher()
    private val onEnter by EventDispatcher<Unit>()
    private val onExit by EventDispatcher<Unit>()
    private val onDropListeningStart by EventDispatcher<Unit>()
    private val onDragStart by EventDispatcher<Unit>()
    private val onDragEnd by EventDispatcher<Unit>()

    private val utils = Utils()

    fun setIncludeBase64(value: Boolean?) {
        includeBase64 = value ?: false
    }

    fun setDraggableSources(value: List<DraggableItem>?) {
        draggableSources = value ?: emptyList()
    }

    fun setAllowedMimeTypes(value: List<String>?) {
        allowedMimeTypes = value
    }



    private fun configureDropHelper(frame: View) {
        // DropHelper is only available on Android N and above
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return

        val activity = appContext.activityProvider?.currentActivity!!
        val contentResolver = context.contentResolver

        frame.setOnDragListener { _, event ->
            when (event.action) {
                DragEvent.ACTION_DRAG_STARTED -> {
                    onDropListeningStart.invoke(Unit)
                    true
                }
                DragEvent.ACTION_DRAG_ENDED -> {
                    onDragEnd.invoke(Unit)
                    true
                }
                DragEvent.ACTION_DRAG_ENTERED -> {
                    onEnter.invoke(Unit)
                    true
                }
                DragEvent.ACTION_DRAG_EXITED -> {
                    onExit.invoke(Unit)
                    true
                }
                DragEvent.ACTION_DROP -> {
                    val clipData = event.clipData
                    val infoList = mutableListOf<Map<String, Any?>>()


                    for (i in 0 until clipData.itemCount) {
                        val permissions = activity.requestDragAndDropPermissions(event)
                        val text = clipData.getItemAt(i).text // Get text data
                        if (text != null) {
                            if (text.isNotEmpty()) {
                                // Handle text data
                                if (text.trim().isNotEmpty()) {
                                    // Check if text/plain MIME type is allowed
                                    if (utils.isMimeTypeAllowed("text/plain", allowedMimeTypes)) {
                                        val textInfo = mapOf(
                                            "type" to DraggableType.TEXT,
                                            "text" to text
                                        )
                                        infoList.add(textInfo)
                                    }
                                }
                            }
                        } else if (permissions != null) {
                            val contentUri = clipData.getItemAt(i).uri

                            if (contentUri != null) {
                                val info = utils.getFileInfo(
                                    contentResolver,
                                    contentUri,
                                    includeBase64,
                                    frame.context
                                )
                                info?.let { fileInfo ->
                                    // Check if the file's MIME type is allowed
                                    val mimeType = fileInfo["type"] as? String
                                    if (utils.isMimeTypeAllowed(mimeType, allowedMimeTypes)) {
                                        infoList.add(fileInfo)
                                    }
                                }
                            }
                        }
                    }
                    if (infoList.isNotEmpty()) onDrop(mapOf("assets" to infoList))
                    true
                }
                else -> false
            }
        }
    }

    private fun dragSources(view: View, context: Context) {
        // DropHelper is only available on Android N and above
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return

        val data: MutableList<Uri> = mutableListOf()
        val textData: MutableList<String> = mutableListOf()

        for (source in draggableSources) {
            when (source.type) {
                DraggableType.IMAGE, DraggableType.VIDEO, DraggableType.FILE -> {
                    val uri = Uri.parse(source.value)

                    uri?.let { data.add(it) }
                }
                DraggableType.TEXT -> {
                    // For text sources, add the text value directly to the textData list
                    textData.add(source.value)
                }
            }
        }

        val shadow = DragShadowBuilder(view)

        // Create ClipData with both URI data and text data
        val clipData = ClipData.newPlainText("Text", textData.joinToString("\n"))

        if (data.isNotEmpty()) {
            clipData.addItem(ClipData.Item(data[0]))
            for (i in 1 until data.size) {
                clipData.addItem(ClipData.Item(data[i]))
            }
        }

        if (clipData.itemCount > 0) {
            onDragStart.invoke(Unit)
        }
        view.startDragAndDrop(clipData, shadow, null, DRAG_FLAG_GLOBAL or DRAG_FLAG_GLOBAL_URI_READ)
    }

    private fun configureDragHelper(frame: View) {
        DragStartHelper(frame) { view, _ ->
            dragSources(view, frame.context)
            return@DragStartHelper false
        }.attach()
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun addDragToChild(view: View) {
        if (view is ViewGroup && view.childCount > 0) {
            // If the current view is a ViewGroup and has children, recursively check its children
            var deepestChild: View = view.getChildAt(0)
            for (i in 0 until view.childCount) {
                val child = view.getChildAt(i)
                if (child.height > deepestChild.height) {
                    deepestChild = child
                }
            }
            addDragToChild(deepestChild)
        } else {
            // Configure DragHelper for the deepest child
            val longPressDuration = 500L
            view.setOnTouchListener{ _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        Handler(Looper.getMainLooper()).postDelayed({
                                dragSources(view, view.context)
                        }, longPressDuration)
                    }
                }
                true
            }
        }
    }

    override fun addView(child: View?, index: Int) {
        super.addView(child, index)
        if (child != null) addDragToChild(child)
    }

    init {
        configureDropHelper(this)
        configureDragHelper(this)
        // Allow children to overflow the bounds to match iOS behavior
        clipChildren = false
        clipToPadding = false
    }
}
