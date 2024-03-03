import ExpoModulesCore

let IOnDropEvent = "onDropEvent"
let IOnDropStartEvent = "onDropStartEvent"
let IOnDropEndEvent = "onDropEndEvent"

public class ExpoDragDropContentViewModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDragDropContentView")

    View(ExpoDragDropContentView.self) {
        Events(IOnDropEvent, IOnDropStartEvent, IOnDropEndEvent)

        Prop("includeBase64") { (view, includeBase64: Bool) in
            view.dragDropContentView.setIncludeBase64(includeBase64)
        }
        Prop("draggableImageUris") { (view, draggableImageUris: [String]) in
            view.dragDropContentView.setDraggableImageUris(draggableImageUris)
        }
    }
  }
}
