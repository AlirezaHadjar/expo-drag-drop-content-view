import UIKit
import ImageIO
import ExpoModulesCore
import MobileCoreServices

class DragDropContentView: UIView, UIDropInteractionDelegate, UIDragInteractionDelegate {

    var onDropEvent: EventDispatcher? = nil
    var onDropStartEvent: EventDispatcher? = nil
    var onDropEndEvent: EventDispatcher? = nil
    lazy var includeBase64 = false
    lazy var draggableImageSources: [String] = []

    func setIncludeBase64(_ includeBase64: Bool) {
        self.includeBase64 = includeBase64
    }

    func setdraggableImageSources(_ draggableImageSources: [String]) {
        self.draggableImageSources = draggableImageSources
    }

    private func setupDropInteraction() {
        let dropInteraction = UIDropInteraction(delegate: self)
        let dragInteraction = UIDragInteraction(delegate: self)
        self.addInteraction(dropInteraction)
        self.addInteraction(dragInteraction)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        setupDropInteraction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDropEventDispatcher(_ eventDispatcher: EventDispatcher) {
      self.onDropEvent = eventDispatcher
    }

    func setDropStartEventDispatcher(_ eventDispatcher: EventDispatcher) {
      self.onDropStartEvent = eventDispatcher
    }

    func setDropEndEventDispatcher(_ eventDispatcher: EventDispatcher) {
      self.onDropEndEvent = eventDispatcher
    }

    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        var dragItems: [UIDragItem] = []

        for source in draggableImageSources {
            guard let image = loadImage(fromImagePath: source) else { return [] }

            let itemProvider = NSItemProvider(object: image)
            let dragItem = UIDragItem(itemProvider: itemProvider)

            // Calculate the new dimensions based on the view's size
            let viewWidth = 200.0
            let viewHeight = self.frame.height

            let aspectRatio = image.size.width / image.size.height

            var imageViewWidth = viewWidth
            var imageViewHeight = viewWidth / aspectRatio

            // Check if the height exceeds the view's height
            if imageViewHeight > viewHeight {
                imageViewHeight = viewHeight
                imageViewWidth = viewHeight * aspectRatio
            }
            let touchedPoint = session.location(in: self)
            let convertedPoint = convertPoint(touchedPoint, fromView: self)
            if let rootView = self.window?.rootViewController?.view {
                let absolutePoint = self.convert(touchedPoint, to: rootView)

                let imageView = convertImageToImageView(image: image)
                imageView.frame = CGRect(x: absolutePoint.x - imageViewWidth / 2, y: absolutePoint.y - imageViewHeight / 2, width: imageViewWidth, height: imageViewHeight)
                dragItem.localObject = imageView

                dragItems.append(dragItem)
            }
        }
        return dragItems
    }

    func dragInteraction(_ interaction: UIDragInteraction, item: UIDragItem, willAnimateCancelWith animator: UIDragAnimating) {
        self.addSubview(item.localObject as! UIView)
    }

    func dragInteraction(_ interaction: UIDragInteraction, willAnimateLiftWith animator: UIDragAnimating, session: UIDragSession) {
        session.items.forEach { dragItem in
            if let touchedImageView = dragItem.localObject as? UIView {
                touchedImageView.removeFromSuperview()
            }
        }
    }

    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {
//        return UITargetedDragPreview(view: item.localObject as! UIView)
        if let view = item.localObject as? UIView {
                if view.window == nil {
                    // The view is not in a window, add it to the main window
                    UIApplication.shared.windows.first?.addSubview(view)
                }
                return UITargetedDragPreview(view: view)
            }
            return nil
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
        // Notify when an item is being dragged over the view
        self.onDropStartEvent?()
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        // Notify when the drop session ends (successfully or not)
        self.onDropEndEvent?()
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        // Notify when an item is being dragged over the view
        self.onDropEndEvent?()
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: UIImage.self)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        var assets: [NSMutableDictionary] = []

        let dispatchGroup = DispatchGroup()

        for dragItem in session.items {
            dispatchGroup.enter()

            dragItem.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (obj, err) in
                defer {
                    dispatchGroup.leave()
                }

                if let err = err {
                    print("Failed to load our dragged item:", err)
                } else {
                    if let draggedImage = obj as? UIImage {
                        DispatchQueue.main.async {
                            if let asset = generateAsset(image: draggedImage, includeBase64: self.includeBase64) {
                                assets.append(asset)
                            }
                        }
                    }
                }
            })
        }

        // Notify when all asynchronous tasks are completed
        dispatchGroup.notify(queue: DispatchQueue.main) {
            if !assets.isEmpty {
                self.onDropEvent?([
                    "assets": assets
                ])
            }
        }
    }
}
