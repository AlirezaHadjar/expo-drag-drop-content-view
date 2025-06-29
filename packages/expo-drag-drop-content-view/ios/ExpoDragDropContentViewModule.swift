import ExpoModulesCore

let IOnDropEvent = "onDrop"
let IOnDragStartEvent = "onDragStart"
let IOnDragEndEvent = "onDragEnd"
let IOnExitEvent = "onExit"
let IOnEnterEvent = "onEnter"


public class ExpoDragDropContentViewModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDragDropContentView")


    let fileSystem: EXFileSystemInterface? = self.appContext?.fileSystem

    View(ExpoDragDropContentView.self) {
        Events(IOnDropEvent, IOnDragStartEvent, IOnDragEndEvent, IOnEnterEvent, IOnExitEvent)

        Prop("includeBase64") { (view, includeBase64: Bool?) in
            let include = includeBase64 ?? false
            view.dragDropContentView.setIncludeBase64(include)
            view.dragDropContentView.fileSystem = fileSystem
        }
        Prop("draggableSources") { (view, draggableSources: [DraggableSource]?) in
            let sources = draggableSources ?? []
            view.dragDropContentView.setDraggableSources(sources)
        }
        Prop("mimeTypes") { (view, mimeTypes: [String: String]?) in
            let types = mimeTypes ?? [:]
            view.dragDropContentView.setMimeTypes(types)
        }
        Prop("allowedMimeTypes") { (view, allowedMimeTypes: [String]?) in
            view.dragDropContentView.setAllowedMimeTypes(allowedMimeTypes)
        }
    }
  }
}
