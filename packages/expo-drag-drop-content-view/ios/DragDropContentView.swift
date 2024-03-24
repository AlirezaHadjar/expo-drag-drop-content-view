import UIKit
import ImageIO
import ExpoModulesCore
import MobileCoreServices

class DragDropContentView: UIView, UIDropInteractionDelegate, UIDragInteractionDelegate {

    var onDropEvent: EventDispatcher? = nil
    var onDropStartEvent: EventDispatcher? = nil
    var onDropEndEvent: EventDispatcher? = nil
    lazy var includeBase64 = false
    lazy var draggableMediaSources: [String] = []
    var fileSystem: EXFileSystemInterface?

    func setIncludeBase64(_ includeBase64: Bool) {
        self.includeBase64 = includeBase64
    }

    func setdraggableImageSources(_ draggableImageSources: [String]) {
        self.draggableMediaSources = draggableImageSources
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

        for source in draggableMediaSources {
            var finalImage: UIImage?
            var itemProvider: NSItemProvider?

            if let image = loadImage(fromImagePath: source) {
                finalImage = image
                if let finalImage = finalImage {
                    itemProvider = NSItemProvider(object: finalImage)
                }
            } else if let videoURL = loadVideoURL(fromVideoPath: source) {
                finalImage = generateThumbnail(fromVideoURL: videoURL)
                if let provider = NSItemProvider(contentsOf: videoURL) {
                    itemProvider = provider
                } else {
                    print("Failed to create item provider for video at \(videoURL)")
                }
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
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        // Notify when an item is being dragged over the view
        self.onDropEndEvent?()
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        var typeIdentifiers: [String] = []
        
        if #available(iOS 14.0, *) {
            typeIdentifiers = [
                UTType.image.identifier,
                UTType.video.identifier,
                UTType.movie.identifier
            ]
        } else {
            typeIdentifiers = [
                kUTTypeImage as String,
                kUTTypeMovie as String,
                kUTTypeVideo as String
            ]
        }
        
        return session.hasItemsConforming(toTypeIdentifiers: typeIdentifiers)
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func getSessionItemType(itemProvider: NSItemProvider) -> SessionItemType {
        if #available(iOS 14.0, *) {
            switch true {
            case itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) || itemProvider.hasItemConformingToTypeIdentifier(UTType.video.identifier):
                return .video
            case itemProvider.hasItemConformingToTypeIdentifier(UTType.item.identifier):
                return .file
            case itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier):
                return .image
            case itemProvider.hasItemConformingToTypeIdentifier(UTType.text.identifier):
                return .text
            default:
                return .unknown
            }
        } else {
            if let suggestedName = itemProvider.suggestedName {
                let components = suggestedName.components(separatedBy: ".")
                if let fileExtension = components.last {
                    switch fileExtension.lowercased() {
                    case "mov", "mp4":
                        return .video
                    case "jpg", "jpeg", "png", "gif":
                        return .image
                    case "txt":
                        return .text
                    default:
                        return .file
                    }
                }
            }
            
            // If file extension is not available or cannot be determined, return "unknown"
            return .unknown
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        var assets: [NSMutableDictionary] = []
        let dispatchGroup = DispatchGroup()
        
        self.onDropEndEvent?()

        for (index, dragItem) in session.items.enumerated() {
            dispatchGroup.enter()
            if #available(iOS 14.0, *) {
                let hasVideo = dragItem.itemProvider.canLoadObject(ofClass: UIImage.self)
                
                print("index: \(index), has image: \(hasVideo)")
            } else {
            }
            
            let itemType = getSessionItemType(itemProvider: dragItem.itemProvider)
            
            if #available(iOS 15.0, *) {
                if itemType == SessionItemType.image {
                    loadImageObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave() // Leave the group inside the completion handler
                    }
                } else if itemType == SessionItemType.video {
                    loadFileObject(dragItem: dragItem, isVideo: true) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave() // Leave the group inside the completion handler
                    }
                } else if itemType == SessionItemType.file {
                    loadFileObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave() // Leave the group inside the completion handler
                    }
                } else if itemType == SessionItemType.text {
                    // loadTextObjects(session: session, dispatch: dispatchGroup)
                }
            } else {
                if itemType == SessionItemType.image {
                    loadImageObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave() // Leave the group inside the completion handler
                    }
                } else if itemType == SessionItemType.video {
                    loadFileObject(dragItem: dragItem, isVideo: true) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave() // Leave the group inside the completion handler
                    }
                } else if itemType == SessionItemType.file {
                    loadFileObject(dragItem: dragItem) { asset in
                        if let asset = asset {
                            assets.append(asset)
                        }
                        dispatchGroup.leave() // Leave the group inside the completion handler
                    }
                } else if itemType == SessionItemType.text {
                    // loadTextObjects(session: session, dispatch: dispatchGroup)
                }
            }
        }

        // Notify when all asynchronous tasks are completed
        dispatchGroup.notify(queue: DispatchQueue.main) {
            print("Assets: \(assets)")
            if !assets.isEmpty {
                self.onDropEvent?([
                    "assets": assets
                ])
            }
        }
    }

    private func loadImageObject(dragItem: UIDragItem, completion: @escaping (NSMutableDictionary?) -> Void) {
        dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (image, err) in
            if let image = image as? UIImage {
                DispatchQueue.main.async {
                    let asset = generateImageAsset(image: image, includeBase64: self.includeBase64)
                    completion(asset)
                }
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
            
            DispatchQueue.main.async {
               if let fileSystem = self.fileSystem {
                   if let asset = generateVideoAsset(from: url, includeBase64: self.includeBase64, fileSystem: fileSystem) {
//                       print("Video asset: \(asset)")
                       completion(asset)
                   }
               } else {
                   completion(nil)
               }
           }
        }
    }

}
