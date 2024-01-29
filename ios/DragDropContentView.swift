import UIKit
import ImageIO
import ExpoModulesCore
import MobileCoreServices

class DragDropContentView: UIView, UIDropInteractionDelegate {
    var onDropEvent: EventDispatcher? = nil
    var onDropStartEvent: EventDispatcher? = nil
    var onDropEndEvent: EventDispatcher? = nil
    lazy var includeBase64 = false

    func setIncludeBase64(_ includeBase64: Bool) {
        self.includeBase64 = includeBase64
    }

    private func setupDropInteraction() {
        let dropInteraction = UIDropInteraction(delegate: self)
        self.addInteraction(dropInteraction)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
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
