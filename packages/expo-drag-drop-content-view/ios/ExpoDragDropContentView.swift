import ExpoModulesCore

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).
class ExpoDragDropContentView: ExpoView {
    let onDrop = EventDispatcher()
    let onDragStart = EventDispatcher()
    let onDragEnd = EventDispatcher()
    let onEnter = EventDispatcher()
    let onExit = EventDispatcher()
    let dragDropContentView = DragDropContentView()

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        clipsToBounds = true
        addSubview(dragDropContentView)

        dragDropContentView.setDropEventDispatcher(onDrop)
        dragDropContentView.setDragStartEventDispatcher(onDragStart)
        dragDropContentView.setDragEndEventDispatcher(onDragEnd)
        dragDropContentView.setEnterEventDispatcher(onEnter)
        dragDropContentView.setExitEventDispatcher(onExit)
    }

    override func layoutSubviews() {
        dragDropContentView.frame = bounds
    }

    override func addSubview(_ view: UIView) {
        super.addSubview(view)

        handleSubviewAdded(view)
    }

    func handleSubviewAdded(_ subview: UIView) {
        // Enable drop/drop interaction for each subview

        let dropInteraction = UIDropInteraction(delegate: dragDropContentView)
        let dragInteraction = UIDragInteraction(delegate: dragDropContentView)
        subview.addInteraction(dropInteraction)
        subview.addInteraction(dragInteraction)
    }
}
