import ExpoModulesCore

let IOnDropEvent = "onDrop"
let IOnDropStartEvent = "onDropStart"
let IOnDropEndEvent = "onDropEnd"
let IOnExitEvent = "onExit"


public class ExpoDragDropContentViewModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDragDropContentView")


    let fileSystem: EXFileSystemInterface? = self.appContext?.fileSystem

    View(ExpoDragDropContentView.self) {
        Events(IOnDropEvent, IOnDropStartEvent, IOnDropEndEvent, IOnExitEvent)

        Prop("includeBase64") { (view, includeBase64: Bool?) in
            let include = includeBase64 ?? false
            view.dragDropContentView.setIncludeBase64(include)
            view.dragDropContentView.fileSystem = fileSystem
        }
        Prop("draggableSources") { (view, draggableSources: [DraggableSource]?) in
            let sources = draggableSources ?? []
            view.dragDropContentView.setDraggableSources(sources)
        }
    }
  }
}
