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

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
       // The event type is incomplete. The number 9 indicates a drag event.
       // If the drag event has been received, we can direct it to the drag-drop content view.
       if event?.type.rawValue == 9 {
         return dragDropContentView.hitTest(point, with: event)
       }

       // We know that we're not dealing with a drag event.
       // Other events we want to pass to child views, omitting the `dragDropContentView`.
       // We don't need to use `reactZIndexSortedSubviews` on Fabric, but it seems to be necessary on Paper.
       for subview in reactZIndexSortedSubviews() where subview != dragDropContentView {
         let hit = subview.hitTest(point, with: event)
         if hit != nil {
           return hit
         }
       }

       // It doesn't seem to be needed, but I'm not 100% sure.
       return super.hitTest(point, with: event)
     }

    override func addSubview(_ view: UIView) {
        super.addSubview(view)

        handleSubviewAdded(view)
    }

    override func insertSubview(_ view: UIView, at index: Int) {
        super.insertSubview(view, at: index)

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
