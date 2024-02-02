#if os(iOS)
import UIKit
import ExpoModulesCore

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
#elseif os(macOS)
import AppKit
import ExpoModulesCore

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

    override func layout() {
        dragDropContentView.frame = bounds
    }

    override func addSubview(_ view: NSView) {
        super.addSubview(view)

        // Call your custom function when a subview is added
        handleSubviewAdded(view)
    }

    func handleSubviewAdded(_ subview: NSView) {
        // Enable drop interaction for each subview
        subview.registerForDraggedTypes([.fileURL])
//        subview.addDraggingDestinationDelegate(dragDropContentView)
    }
}
#endif
