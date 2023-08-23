import ExpoModulesCore

let IOnDropEvent = "onDropEvent"

public class ExpoDragDropContentViewModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoDragDropContentView")

    View(ExpoDragDropContentView.self) {
        Events(IOnDropEvent)

        Prop("includeBase64") { (view, includeBase64: Bool) in
            view.dragDropContentView.setIncludeBase64(includeBase64)
        }
    }
  }
}
