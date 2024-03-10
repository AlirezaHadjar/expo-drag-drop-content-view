import ExpoModulesCore

let IOnDropEvent = "onDropEvent"
let IOnDropStartEvent = "onDropStartEvent"
let IOnDropEndEvent = "onDropEndEvent"

public class ExpoDragDropContentViewModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDragDropContentView")

    View(ExpoDragDropContentView.self) {
        Events(IOnDropEvent, IOnDropStartEvent, IOnDropEndEvent)

        Prop("includeBase64") { (view, includeBase64: Bool?) in
            let include = includeBase64 ?? false
            view.dragDropContentView.setIncludeBase64(include)
        }
        Prop("draggableImageSources") { (view, draggableImageSources: [String]?) in
            let sources = draggableImageSources ?? []
            view.dragDropContentView.setdraggableImageSources(sources)
        }
    }
  }
}
