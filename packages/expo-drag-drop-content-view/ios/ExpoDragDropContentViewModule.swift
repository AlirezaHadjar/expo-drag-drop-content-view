import ExpoModulesCore

let IOnDropEvent = "onDropEvent"
let IOnDropStartEvent = "onDropStartEvent"
let IOnDropEndEvent = "onDropEndEvent"

public class ExpoDragDropContentViewModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDragDropContentView")


    let fileSystem: EXFileSystemInterface? = self.appContext?.fileSystem

    View(ExpoDragDropContentView.self) {
        Events(IOnDropEvent, IOnDropStartEvent, IOnDropEndEvent)

        Prop("includeBase64") { (view, includeBase64: Bool?) in
            let include = includeBase64 ?? false
            view.dragDropContentView.setIncludeBase64(include)
            view.dragDropContentView.fileSystem = fileSystem
        }
        Prop("draggableSources") { (view, draggableSources: [String]?) in
            let sources = draggableSources ?? []
            view.dragDropContentView.setDraggableImageSources(sources)
        }
    }
  }
}
