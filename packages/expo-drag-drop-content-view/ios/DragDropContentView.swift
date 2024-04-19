import UIKit
import UniformTypeIdentifiers
import ImageIO
import ExpoModulesCore
import MobileCoreServices

class DragDropContentView: UIView, UIDropInteractionDelegate, UIDragInteractionDelegate {

    var onDrop: EventDispatcher? = nil
    var onDragStart: EventDispatcher? = nil
    var onDragEnd: EventDispatcher? = nil
    var onEnter: EventDispatcher? = nil
    var onExit: EventDispatcher? = nil
    lazy var includeBase64 = false
    lazy var draggableSources: [DraggableSource] = []
    var fileSystem: EXFileSystemInterface?

    func setIncludeBase64(_ includeBase64: Bool) {
        self.includeBase64 = includeBase64
    }

    func setDraggableSources(_ draggableSources: [DraggableSource]) {
        self.draggableSources = draggableSources
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
        self.onDrop = eventDispatcher
    }

    func setDragStartEventDispatcher(_ eventDispatcher: EventDispatcher) {
        self.onDragStart = eventDispatcher
    }

    func setDragEndEventDispatcher(_ eventDispatcher: EventDispatcher) {
        self.onDragEnd = eventDispatcher
    }
    
    func setEnterEventDispatcher(_ eventDispatcher: EventDispatcher) {
        self.onEnter = eventDispatcher
    }
    
    func setExitEventDispatcher(_ eventDispatcher: EventDispatcher) {
        self.onExit = eventDispatcher
    }

    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        var dragItems: [UIDragItem] = []

        for source in draggableSources {
            var finalImage: UIImage?
            var itemProvider: NSItemProvider?

            let sourceType = getSessionItemType(from: source.type)

            if (sourceType == .image) {
                if let image = loadImage(fromImagePath: source.value) {
                    finalImage = image
                    if let finalImage = finalImage {
                        itemProvider = NSItemProvider(object: finalImage)
                    }
                }
            } else if (sourceType == .video) {
                if let videoURL = loadVideoURL(fromVideoPath: source.value) {
                    finalImage = generateThumbnail(fromVideoURL: videoURL)
                    if let provider = NSItemProvider(contentsOf: videoURL) {
                        itemProvider = provider
                    } else {
                        print("Failed to create item provider for video at \(videoURL)")
                    }
                }
            } else if (sourceType == .text) {
                itemProvider = NSItemProvider(object: source.value as NSItemProviderWriting)

                let label = UILabel()
                label.text = source.value
                label.sizeToFit() // Adjust label size to fit its content

                // Convert the UILabel to an image for drag visualization
                UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
                label.layer.render(in: UIGraphicsGetCurrentContext()!)
                finalImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }

            if let itemProvider = itemProvider {
                let dragItem = UIDragItem(itemProvider: itemProvider)
                // Check if finalImage is not nil
                if let finalImage = finalImage {
                    let imageView = resizeImageAndConvertToImageView(image: finalImage, session: session, view: self)
                    dragItem.localObject = imageView
                }
                dragItems.append(dragItem)
            } else {
                print("Skipping \(source) due to missing image or video.")
            }
        }
        
        if (dragItems.count > 0) {
            self.onDragStart?()
        }
        return dragItems
    }

    func dragInteraction(_ interaction: UIDragInteraction, item: UIDragItem, willAnimateCancelWith animator: UIDragAnimating) {
        if item.localObject != nil {
            self.addSubview(item.localObject as! UIView)
        }
    }

    func dragInteraction(_ interaction: UIDragInteraction, willAnimateLiftWith animator: UIDragAnimating, session: UIDragSession) {
        session.items.forEach { dragItem in
            if let touchedImageView = dragItem.localObject as? UIView {
                touchedImageView.removeFromSuperview()
            }
        }
    }

    func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: UIDragSession) -> UITargetedDragPreview? {

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
        self.onEnter?()
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
        // Notify when the drop session ends (successfully or not)
        self.onDragEnd?()
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        // Notify when an item is being dragged over the view
        let location = session.location(in: self)
        // When the there are subview this method gets called even if the finger is within the view and entered subview.
        // Now should check if the finger is out of the boundaries
        let isWithinBoundaries = self.bounds.contains(location)
        if !isWithinBoundaries {
            self.onExit?()
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        var typeIdentifiers: [String] = []

        if #available(iOS 14.0, *) {
            typeIdentifiers = [
                UTType.image.identifier,
                UTType.video.identifier,
                UTType.movie.identifier,
                UTType.text.identifier
            ]
        } else {
            typeIdentifiers = [
                kUTTypeImage as String,
                kUTTypeMovie as String,
                kUTTypeVideo as String,
                kUTTypeText as String
            ]
        }

        return session.hasItemsConforming(toTypeIdentifiers: typeIdentifiers)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        var assets: [NSMutableDictionary] = []
        let dispatchGroup = DispatchGroup()

        for dragItem in session.items {
            dispatchGroup.enter()

            let itemType = getSessionItemType(itemProvider: dragItem.itemProvider)

            if #available(iOS 15.0, *) {
                if itemType == SessionItemType.image {
                    loadImageObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave()
                    }
                } else if itemType == SessionItemType.video {
                    loadFileObject(dragItem: dragItem, isVideo: true) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave()
                    }
                } else if itemType == SessionItemType.file {
                    loadFileObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave()
                    }
                } else if itemType == SessionItemType.text {
                    loadTextObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave()
                    }
                }
            } else {
                if itemType == SessionItemType.image {
                    loadImageObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave()
                    }
                } else if itemType == SessionItemType.video {
                    loadFileObject(dragItem: dragItem, isVideo: true) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave()
                    }
                } else if itemType == SessionItemType.file {
                    loadFileObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave()
                    }
                } else if itemType == SessionItemType.text {
                    loadTextObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }

        // Notify when all asynchronous tasks are completed
        dispatchGroup.notify(queue: DispatchQueue.main) {
            // print("Assets: \(assets)")
            if !assets.isEmpty {
                self.onDrop?([
                    "assets": assets
                ])
            }
        }
    }

    private func loadTextObject(dragItem: UIDragItem, completion: @escaping (NSMutableDictionary?) -> Void) {
        _ = dragItem.itemProvider.loadObject(ofClass: String.self) { (text, _) in
                if let text = text {
                    completion(["type": "text", "text": text])
                } else {
                    completion(nil)
                }
        }
    }

    private func loadImageObject(dragItem: UIDragItem, completion: @escaping (NSMutableDictionary?) -> Void) {
        dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (image, err) in
            if let image = image as? UIImage {
                    let asset = generateImageAsset(image: image, includeBase64: self.includeBase64)
                    completion(asset)
            } else {
                completion(nil)
            }
        }
    }

    private func loadFileObject(dragItem: UIDragItem, isVideo: Bool = false, completion: @escaping (NSMutableDictionary?) -> Void) {
        dragItem.itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: kUTTypeItem as String) { (url, bool, error) in
            guard let url = url else {
                if let error = error {
                    print("error loading file \(error)")
                }
                completion(nil)
                return
            }

               if let fileSystem = self.fileSystem {
                   if let asset = generateVideoAsset(from: url, includeBase64: self.includeBase64, fileSystem: fileSystem) {
                       completion(asset)
                   }
               } else {
                   completion(nil)
               }
           }
    }

}
