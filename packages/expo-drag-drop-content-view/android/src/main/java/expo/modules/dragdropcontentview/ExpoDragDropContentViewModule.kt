package expo.modules.dragdropcontentview

import expo.modules.dragdropcontentview.records.DraggableItem
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ExpoDragDropContentViewModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ExpoDragDropContentView")

    // Enables the module to be used as a native view. Definition components that are accepted as part of
    // the view definition: Prop, Events.
    View(ExpoDragDropContentView::class) {
      Prop("includeBase64") {view: ExpoDragDropContentView, value: Boolean? ->
        view.setIncludeBase64(value)
      }
      Prop("draggableSources") {view: ExpoDragDropContentView, value: List<DraggableItem>? ->
         view.setDraggableSources(value)
      }
      Prop("allowedMimeTypes") {view: ExpoDragDropContentView, value: List<String>? ->
         view.setAllowedMimeTypes(value)
      }
      Events("onDrop", "onDropListeningStart", "onDragStart", "onDragEnd", "onEnter", "onExit")
    }
  }
}
