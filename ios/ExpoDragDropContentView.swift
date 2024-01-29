import ExpoModulesCore

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).
class ExpoDragDropContentView: ExpoView {
    let onDropEvent = EventDispatcher()
    let onDropStartEvent = EventDispatcher()
    let onDropEndEvent = EventDispatcher()
    let dragDropContentView = DragDropContentView()

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        clipsToBounds = true
        addSubview(dragDropContentView)
        
        dragDropContentView.setDropEventDispatcher(onDropEvent)
        dragDropContentView.setDropStartEventDispatcher(onDropStartEvent)
        dragDropContentView.setDropEndEventDispatcher(onDropEndEvent)
    }

    override func layoutSubviews() {
        dragDropContentView.frame = bounds
    }
    
    override func addSubview(_ view: UIView) {
        super.addSubview(view)

        // Call your custom function when a subview is added
        handleSubviewAdded(view)
    }

    func handleSubviewAdded(_ subview: UIView) {
        // Enable drop interaction for each subview
        let dropInteraction = UIDropInteraction(delegate: dragDropContentView)
        subview.addInteraction(dropInteraction)
    }
}
