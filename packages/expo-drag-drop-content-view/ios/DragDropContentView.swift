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
                // If the source is an image
                finalImage = image
                if let finalImage = finalImage {
                    itemProvider = NSItemProvider(object: finalImage)
                }
            } else if let videoURL = loadVideoURL(fromVideoPath: source) {
                // If the source is a video, generate a thumbnail
                
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
        self.onDropEndEvent?()
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
        // Notify when an item is being dragged over the view
        self.onDropEndEvent?()
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        if #available(iOS 14.0, *) {
            return session.canLoadObjects(ofClass: UIImage.self) || session.hasItemsConforming(toTypeIdentifiers: [UTType.movie.identifier])
        } else {
            return session.canLoadObjects(ofClass: UIImage.self)
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
       var assets: [NSMutableDictionary] = []

       let dispatchGroup = DispatchGroup()

       for dragItem in session.items {
           dispatchGroup.enter()

           // Load objects asynchronously and handle both images and videos
           dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (obj, err) in
               if let image = obj as? UIImage {
                   DispatchQueue.main.async {
                       if let asset = generateImageAsset(image: image, includeBase64: self.includeBase64) {
                           assets.append(asset)
                       }
                       dispatchGroup.leave()
                   }
               } else {
                   if #available(iOS 14.0, *) {
                       dragItem.itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { (url, bool, err) in
                           if let videoURL = url {
                               DispatchQueue.main.async {
                                   if let fileSystem = self.fileSystem {
                                       if let asset = generateVideoAsset(from: videoURL, includeBase64: self.includeBase64, fileSystem: fileSystem) {
                                           assets.append(asset)
                                       }
                                   }
                                   dispatchGroup.leave()
                               }
                           } else {
                               dispatchGroup.leave()
                           }
                       }
                   } else {
                       dispatchGroup.leave()
                   }
               }
           }
       }

       // Notify when all asynchronous tasks are completed
       dispatchGroup.notify(queue: DispatchQueue.main) {
           print("wqerqwer", assets)
           if !assets.isEmpty {
               self.onDropEvent?([
                   "assets": assets
               ])
           }
       }
    }
}
