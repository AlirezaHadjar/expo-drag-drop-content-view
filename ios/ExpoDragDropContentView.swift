import ExpoModulesCore

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).
class ExpoDragDropContentView: ExpoView {
    let onDropEvent = EventDispatcher()
    let dragDropContentView = DragDropContentView()

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        clipsToBounds = true
        addSubview(dragDropContentView)
        dragDropContentView.setEventDispatcher(onDropEvent)
    }

    override func layoutSubviews() {
        dragDropContentView.frame = bounds
    }
}
