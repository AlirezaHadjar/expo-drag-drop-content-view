//
//  Utils.swift
//  ExpoDragDropContentView
//
//  Created by Alireza Hadjar on 8/23/23.
//

import Foundation
import MobileCoreServices
import ImageIO
import AVFoundation
import ExpoModulesCore

import Photos
import PhotosUI

extension UIImage {
    var hasAlpha: Bool {
        guard let alphaInfo = cgImage?.alphaInfo else { return false }
        return alphaInfo != .none && alphaInfo != .noneSkipFirst && alphaInfo != .noneSkipLast
    }
}

func extractImageData(image: UIImage) -> Data? {
    let imageData = NSMutableData()
    var destination: CGImageDestination?

    if image.hasAlpha {
        destination = CGImageDestinationCreateWithData(imageData as CFMutableData, kUTTypePNG, 1, nil)
    } else {
        destination = CGImageDestinationCreateWithData(imageData as CFMutableData, kUTTypeJPEG, 1, nil)
    }

    guard let finalDestination = destination else {
        return nil
    }

    // Map UIImage.Orientation to CGImagePropertyOrientation
    let orientation: CGImagePropertyOrientation
    switch image.imageOrientation {
    case .up:
        orientation = .up
    case .down:
        orientation = .down
    case .left:
        orientation = .left
    case .right:
        orientation = .right
    case .upMirrored:
        orientation = .upMirrored
    case .downMirrored:
        orientation = .downMirrored
    case .leftMirrored:
        orientation = .leftMirrored
    case .rightMirrored:
        orientation = .rightMirrored
    @unknown default:
        fatalError("Unhandled image orientation case")
    }

    let orientationKey = kCGImagePropertyOrientation as String
    let orientationNumber = orientation.rawValue as CFNumber
    let orientationDictionary = [orientationKey: orientationNumber]

    let imageProps = orientationDictionary as CFDictionary

    CGImageDestinationAddImage(finalDestination, image.cgImage!, imageProps)

    CGImageDestinationFinalize(finalDestination)

    return imageData as Data
}

func getImageFileName(fileType: String) -> String {
    var fileName = UUID().uuidString
    fileName.append(".")
    return fileName.appending(fileType)
}

func getMimeType(imageData: Data) -> String? {
    if let imageDataProvider = CGDataProvider(data: imageData as CFData) {
        if let imageSource = CGImageSourceCreateWithDataProvider(imageDataProvider, nil) {
            if let imageType = CGImageSourceGetType(imageSource) {
                if let imageUTI = UTTypeCopyPreferredTagWithClass(imageType, kUTTagClassMIMEType) {
                    return imageUTI.takeRetainedValue() as String
                }
            }
        }
    }
    return nil
}

func getMimeType(image: UIImage) -> String? {
    if image.hasAlpha {
        // If the image has an alpha channel, use PNG data
        if let imageData = image.pngData() {
            return getMimeType(imageData: imageData)
        }
    } else {
        // If the image does not have an alpha channel, use JPEG data
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            return getMimeType(imageData: imageData)
        }
    }

    return nil
}

private func getMimeType(from pathExtension: String, mimeTypes: [String: String]) -> String {
    let filenameExtension = String(pathExtension.dropFirst())

    // Check iOS 14+ UTType API
    if #available(iOS 14, *) {
        if let mimeType = UTType(filenameExtension: filenameExtension)?.preferredMIMEType {
            return mimeType
        }
    }

    // Check older iOS versions
    if let uti = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension,
        filenameExtension as NSString, nil
    )?.takeRetainedValue() {
        if let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimeType as String
        }
    }

    // Fallback to dictionary lookup
    return mimeTypes[filenameExtension] ?? "unknown"
}

func determineTranscodeFileType(from originalExtension: String) -> AVFileType {
    switch originalExtension.lowercased() {
    case ".mp4":
        return .mp4
    case ".mov":
        return .mov
    default:
        // Use mp4 as default
        return .mp4
    }
}

func getVideoDimensions(from url: URL) -> (width: Int, height: Int)? {
    guard let track = AVAsset(url: url).tracks(withMediaType: .video).first else {
        return nil
    }

    let size = track.naturalSize.applying(track.preferredTransform)
    let width = Int(abs(size.width))
    let height = Int(abs(size.height))

    return (width, height)
}

func generateFileAsset(from mediaURL: URL, includeBase64: Bool, fileSystem: EXFileSystemInterface, isVideo: Bool, mimeTypes: [String: String]) -> NSMutableDictionary? {
    let asset = NSMutableDictionary()

    do {
        // In case of pass-through, we want the original file extension; otherwise, use mp4
        let originalExtension = ".\(mediaURL.pathExtension)"
        let transcodeFileType = determineTranscodeFileType(from: originalExtension)
        let transcodeFileExtension = originalExtension
        let mimeType = getMimeType(from: originalExtension, mimeTypes: mimeTypes)

        // Attempt to access security-scoped resource if applicable
        let didStartAccessing = mediaURL.startAccessingSecurityScopedResource()

        defer {
            if didStartAccessing {
                mediaURL.stopAccessingSecurityScopedResource()
            }
        }

        // Copy the video to a location controlled by us to ensure it's not removed during conversion
        let assetUrl = try generateUrl(withFileExtension: originalExtension, fileSystem: fileSystem)
        let transcodedUrl = try generateUrl(withFileExtension: transcodeFileExtension, fileSystem: fileSystem)
        try FileManager.default.copyItem(at: mediaURL, to: assetUrl)

        // Transcode the video asynchronously
        VideoUtils.transcodeVideoAsync(sourceAssetUrl: assetUrl,
                                       destinationUrl: transcodedUrl,
                                       outputFileType: transcodeFileType,
                                       exportPreset: VideoUtils.VideoExportPreset.passthrough
        ) { result in
            switch result {
            case .failure(let exception):
                print("Failed to transcode video:", exception.description)
            case .success(let targetUrl):
                let fileName = mediaURL.lastPathComponent
                asset["fileName"] = fileName
                asset["type"] = mimeType
                asset["path"] = targetUrl.absoluteString.replacingOccurrences(of: "file://", with: "")
                asset["uri"] = targetUrl.absoluteString

                if (isVideo) {
                    asset["duration"] = VideoUtils.readDurationFrom(url: mediaURL)
                    // Get video dimensions
                    if let dimensions = getVideoDimensions(from: targetUrl) {
                        asset["width"] = dimensions.width
                        asset["height"] = dimensions.height
                    } else {
                        asset["width"] = 0
                        asset["height"] = 0
                        print("Failed to get video dimensions")
                    }
                }

                if includeBase64 {
                    if let videoData = try? Data(contentsOf: targetUrl) {
                        asset["base64"] = videoData.base64EncodedString()
                    } else {
                        print("Error converting video data to base64")
                    }
                }
            }
        }
    } catch {
        print("Error processing video:", error.localizedDescription)
        return nil
    }

    return asset
}

func generateImageAsset (image: UIImage, includeBase64: Bool) -> NSMutableDictionary? {
    let asset = NSMutableDictionary()

    let _mimeType = getMimeType(image: image)
    guard let mimeType = _mimeType else { return nil }
    let fileType = mimeType.split(separator: "/")[1]

    let data = extractImageData(image: image)
    let fileName = getImageFileName(fileType: String(fileType))

    asset["fileName"] = fileName

    asset["type"] = mimeType

    if let data = data {
        let path = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
        asset["path"] = path
        try? data.write(to: URL(fileURLWithPath: path), options: .atomic)


        if (includeBase64) {
            asset["base64"] = data.base64EncodedString()
        }

        let fileURL = URL(fileURLWithPath: path)
        asset["uri"] = fileURL.absoluteString

        asset["width"] = image.size.width
        asset["height"] = image.size.height

    }

    return asset
}

func loadImage(fromImagePath imagePath: String) -> UIImage? {
    if let url = URL(string: imagePath) {
        let filePath = url.path

        if FileManager.default.fileExists(atPath: filePath) {
            if let image = UIImage(contentsOfFile: filePath) {
                return image
            } else {
                print("Failed to create UIImage from file at path: \(filePath)")
            }
        } else {
            print("Image file does not exist at path: \(filePath)")
        }
    } else {
        print("Invalid URL path: \(imagePath)")
    }

    return nil
}

func generateThumbnail(fromVideoURL videoURL: URL) -> UIImage? {
    let asset = AVURLAsset(url: videoURL)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true

    let time = CMTime(seconds: 1, preferredTimescale: 60) // Capture thumbnail at 1 second into the video

    do {
        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
        return UIImage(cgImage: cgImage)
    } catch {
        print("Error generating thumbnail: \(error)")
        return nil
    }
}

func loadFileURL(fromFilePath filePath: String) -> URL? {
    if let url = URL(string: filePath) {
        return url
    } else {
        print("Invalid URL path: \(filePath)")
        return nil
    }
}

func convertImageToImageView(image: UIImage) -> UIImageView {
    let imageView = UIImageView(image: image)
    imageView.contentMode = .scaleAspectFit

    return imageView
}

func resizeImageAndConvertToImageView(image: UIImage, session: UIDragSession, view: UIView) -> UIImageView {
    // Calculate the new dimensions based on the view's size
    let viewWidth = 200.0
    let viewHeight = view.frame.height

    let aspectRatio = image.size.width / image.size.height

    var imageViewWidth = viewWidth
    var imageViewHeight = viewWidth / aspectRatio

    // Check if the height exceeds the view's height
    if imageViewHeight > viewHeight {
        imageViewHeight = viewHeight
        imageViewWidth = viewHeight * aspectRatio
    }
    let touchedPoint = session.location(in: view)

    if let rootView = view.window?.rootViewController?.view {
        let absolutePoint = view.convert(touchedPoint, to: rootView)

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: absolutePoint.x - imageViewWidth / 2, y: absolutePoint.y - imageViewHeight / 2, width: imageViewWidth, height: imageViewHeight)
        return imageView
    }

    // Return an empty image view if rootView is not accessible
    return UIImageView()
}

func captureScreenshot(of view: UIView) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
    defer { UIGraphicsEndImageContext() }
    view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
    return UIGraphicsGetImageFromCurrentImageContext()
}

func convertPoint(_ point: CGPoint, fromView view: UIView?) -> CGPoint {
    if let parent = view?.superview {
        return view?.convert(point, to: parent) ?? CGPoint.zero
    }
    return point
}

private func generateUrl(withFileExtension: String, fileSystem: EXFileSystemInterface) throws -> URL {
    let directory =  fileSystem.cachesDirectory.appending(
        fileSystem.cachesDirectory.hasSuffix("/") ? "" : "/" + "ImagePicker"
    )
    let path = fileSystem.generatePath(inDirectory: directory, withExtension: withFileExtension)
    let url = URL(fileURLWithPath: path)
    return url
}

private struct VideoUtils {
    static func tryCopyingVideo(at: URL, to: URL) throws {
        do {
            // we copy the file as `moveItem(at:,to:)` throws an error in iOS 13 due to missing permissions
            try FileManager.default.copyItem(at: at, to: to)
        } catch {
            throw Exception()
                .causedBy(error)
        }
    }

    /**
     @returns duration in milliseconds
     */
    static func readDurationFrom(url: URL) -> Double {
        let asset = AVURLAsset(url: url)
        return Double(asset.duration.value) / Double(asset.duration.timescale) * 1_000
    }

    static func readSizeFrom(url: URL) -> CGSize? {
        let asset = AVURLAsset(url: url)
        guard let assetTrack = asset.tracks(withMediaType: .video).first else {
            return nil
        }
        // The video could be rotated and the resulting transform can result in a negative width/height.
        let size = assetTrack.naturalSize.applying(assetTrack.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }

    internal enum VideoExportPreset: Int, Enumerable {
        case passthrough = 0
        case lowQuality = 1
        case mediumQuality = 2
        case highestQuality = 3
        case h264_640x480 = 4
        case h264_960x540 = 5
        case h264_1280x720 = 6
        case h264_1920x1080 = 7
        case h264_3840x2160 = 8
        case hevc_1920x1080 = 9
        case hevc_3840_2160 = 10

        func toAVAssetExportPreset() -> String {
            switch self {
            case .passthrough:
              return AVAssetExportPresetPassthrough
            case .lowQuality:
              return AVAssetExportPresetLowQuality
            case .mediumQuality:
              return AVAssetExportPresetMediumQuality
            case .highestQuality:
              return AVAssetExportPresetHighestQuality
            case .h264_640x480:
              return AVAssetExportPreset640x480
            case .h264_960x540:
              return AVAssetExportPreset960x540
            case .h264_1280x720:
              return AVAssetExportPreset1280x720
            case .h264_1920x1080:
              return AVAssetExportPreset1920x1080
            case .h264_3840x2160:
              return AVAssetExportPreset3840x2160
            case .hevc_1920x1080:
              return AVAssetExportPresetHEVC1920x1080
            case .hevc_3840_2160:
              return AVAssetExportPresetHEVC3840x2160
            }
          }
    }
    /**
     Asynchronously transcodes asset provided as `sourceAssetUrl` according to `exportPreset`.
     Result URL is returned to the `completion` closure.
     Transcoded video is saved at `destinationUrl`, unless `exportPreset` is set to `passthrough`.
     In this case, `sourceAssetUrl` is returned.
     */
    static func transcodeVideoAsync(sourceAssetUrl: URL,
                                    destinationUrl: URL,
                                    outputFileType: AVFileType,
                                    exportPreset: VideoExportPreset,
                                    completion: @escaping (Result<URL, Exception>) -> Void) {
        if case .passthrough = exportPreset {
            return completion(.success((sourceAssetUrl)))
        }

        let asset = AVURLAsset(url: sourceAssetUrl)
        let preset = exportPreset.toAVAssetExportPreset()
        AVAssetExportSession.determineCompatibility(ofExportPreset: preset,
                                                    with: asset,
                                                    outputFileType: outputFileType) { canBeTranscoded in
            guard canBeTranscoded else {
                return completion(.failure(Exception()))
            }
            guard let exportSession = AVAssetExportSession(asset: asset,
                                                           presetName: preset) else {
                return completion(.failure(Exception()))
            }
            exportSession.outputFileType = outputFileType
            exportSession.outputURL = destinationUrl
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .failed:
                    let error = exportSession.error
                    completion(.failure(Exception().causedBy(error)))
                default:
                    completion(.success((destinationUrl)))
                }
            }
        }
    }
}

enum SessionItemType {
    case image
    case video
    case text
    case file
    case unknown

    var stringValue: String {
        switch self {
        case .text: return "text"
        case .image: return "image"
        case .video: return "video"
        case .file: return "file"
        case .unknown: return "unknown"
        }
    }
}

func getSessionItemType(from stringValue: String) -> SessionItemType {
    switch stringValue {
    case SessionItemType.text.stringValue:
        return .text
    case SessionItemType.image.stringValue:
        return .image
    case SessionItemType.video.stringValue:
        return .video
    case SessionItemType.file.stringValue:
        return .file
    default:
        return .unknown
    }
}

func getSessionItemType(itemProvider: NSItemProvider) -> SessionItemType {
    if #available(iOS 14.0, *) {
        switch true {
        case itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) || itemProvider.hasItemConformingToTypeIdentifier(UTType.video.identifier):
            return .video
        case itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier):
            return .image
        case itemProvider.hasItemConformingToTypeIdentifier(UTType.json.identifier),
             itemProvider.hasItemConformingToTypeIdentifier(UTType.zip.identifier),
             itemProvider.hasItemConformingToTypeIdentifier(UTType.spreadsheet.identifier),
             itemProvider.hasItemConformingToTypeIdentifier(UTType.presentation.identifier),
             itemProvider.hasItemConformingToTypeIdentifier(UTType.database.identifier),
             itemProvider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier):
                return .file
        case itemProvider.hasItemConformingToTypeIdentifier(UTType.text.identifier):
            return .text
        case itemProvider.hasItemConformingToTypeIdentifier(UTType.item.identifier):
            return .file
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
                case "json", "zip", "xlsx", "xls", "docx", "doc", "pptx", "ppt", "pdf":
                    return .file
                case "txt":
                    return .text
                default:
                    return .unknown
                }
            }
        }

        // If file extension is not available or cannot be determined, return "unknown"
        return .unknown
    }
}

struct DraggableSource: Record {
  @Field
  var type: String

  @Field
  var value: String
}

// MARK: - MIME Type Filtering Utils

func isMimeTypeAllowed(_ mimeType: String?, allowedMimeTypes: [String]?) -> Bool {
    // If nil, allow all
    guard let allowedMimeTypes = allowedMimeTypes else {
        return true
    }
    // If empty array, allow none
    if allowedMimeTypes.isEmpty {
        return false
    }
    // If mimeType is nil or empty, don't allow it when restrictions are set
    guard let mimeType = mimeType, !mimeType.isEmpty else {
        return false
    }

    return allowedMimeTypes.contains { allowedType in
        if allowedType.hasPrefix("__REGEX__") && allowedType.contains("__FLAGS__") {
            // Handle regex pattern
            let components = allowedType.components(separatedBy: "__FLAGS__")
            guard components.count >= 1 else { return false }

            let pattern = components[0].replacingOccurrences(of: "__REGEX__", with: "")
            let flags = components.count > 1 ? components[1] : ""

            do {
                var options: NSRegularExpression.Options = []
                if flags.contains("i") {
                    options.insert(.caseInsensitive)
                }
                if flags.contains("m") {
                    options.insert(.anchorsMatchLines)
                }
                if flags.contains("s") {
                    options.insert(.dotMatchesLineSeparators)
                }

                let regex = try NSRegularExpression(pattern: pattern, options: options)
                let range = NSRange(location: 0, length: mimeType.utf16.count)
                return regex.firstMatch(in: mimeType, options: [], range: range) != nil
            } catch {
                return false
            }
        } else {
            // Handle exact string match
            return allowedType == mimeType
        }
    }
}

// MARK: - Drop Type Identifiers Utils

func getDefaultDropTypeIdentifiers() -> [String] {
    if #available(iOS 14.0, *) {
        return [
            UTType.image.identifier,
            UTType.video.identifier,
            UTType.movie.identifier,
            UTType.text.identifier,
            UTType.pdf.identifier,
            UTType.json.identifier,
            UTType.zip.identifier,
            UTType.spreadsheet.identifier,
            UTType.presentation.identifier,
            UTType.database.identifier,
            UTType.item.identifier
        ]
    } else {
        return [
            kUTTypeImage as String,
            kUTTypeMovie as String,
            kUTTypeVideo as String,
            kUTTypeText as String,
            kUTTypePDF as String,
            kUTTypeJSON as String,
            kUTTypeZipArchive as String,
            kUTTypeSpreadsheet as String,
            kUTTypePresentation as String,
            kUTTypeDatabase as String,
            kUTTypeItem as String
        ]
    }
}

// MARK: - Drag Session Utils

func shouldAllowDragSession(_ session: UIDropSession, allowedMimeTypes: [String]?) -> Bool {
    // If no restrictions, allow all
    guard let allowedMimeTypes = allowedMimeTypes else {
        return true
    }

    // If empty array, allow none
    if allowedMimeTypes.isEmpty {
        return false
    }

    // Check if we have any regex patterns
    let hasRegexPatterns = allowedMimeTypes.contains { $0.hasPrefix("__REGEX__") }

    if hasRegexPatterns {
        // For regex patterns, do basic pattern matching against UTI types
        for (itemIndex, dragItem) in session.items.enumerated() {
            var itemAllowed = false

            for allowedType in allowedMimeTypes {
                if allowedType.hasPrefix("__REGEX__") {
                    // Extract the pattern
                    let components = allowedType.components(separatedBy: "__FLAGS__")
                    let pattern = components[0].replacingOccurrences(of: "__REGEX__", with: "")

                    // Simple pattern matching for common cases
                    var allowedUTITypes: [String] = []

                    if pattern.contains("image") {
                        if #available(iOS 14.0, *) {
                            allowedUTITypes.append(contentsOf: [UTType.image.identifier, UTType.item.identifier])
                        } else {
                            allowedUTITypes.append(contentsOf: [kUTTypeImage as String, kUTTypeItem as String])
                        }
                    }
                    if pattern.contains("video") {
                        if #available(iOS 14.0, *) {
                            allowedUTITypes.append(contentsOf: [UTType.video.identifier, UTType.movie.identifier, UTType.item.identifier])
                        } else {
                            allowedUTITypes.append(contentsOf: [kUTTypeVideo as String, kUTTypeMovie as String, kUTTypeItem as String])
                        }
                    }
                    if pattern.contains("text") {
                        if #available(iOS 14.0, *) {
                            allowedUTITypes.append(contentsOf: [UTType.text.identifier, UTType.item.identifier])
                        } else {
                            allowedUTITypes.append(contentsOf: [kUTTypeText as String, kUTTypeItem as String])
                        }
                    }

                    // Check for PDF patterns - both "pdf" and "application" should match PDFs
                    let containsPdf = pattern.contains("pdf")
                    let containsApplication = pattern.contains("application")

                    if containsPdf || containsApplication {
                        if #available(iOS 14.0, *) {
                            allowedUTITypes.append(contentsOf: [UTType.pdf.identifier, "com.adobe.pdf", UTType.item.identifier])
                        } else {
                            allowedUTITypes.append(contentsOf: [kUTTypePDF as String, "com.adobe.pdf", kUTTypeItem as String])
                        }
                    }

                    // Check for audio/music patterns
                    let containsAudio = pattern.contains("audio")

                    if containsAudio {
                        if #available(iOS 14.0, *) {
                            allowedUTITypes.append(contentsOf: [UTType.audio.identifier, UTType.mp3.identifier, UTType.mpeg4Audio.identifier, UTType.item.identifier])
                        } else {
                            allowedUTITypes.append(contentsOf: [kUTTypeAudio as String, kUTTypeMP3 as String, kUTTypeMPEG4Audio as String, kUTTypeItem as String])
                        }
                    }

                    // Check if the drag item matches any allowed UTI type
                    for utiType in allowedUTITypes {
                        if dragItem.itemProvider.hasItemConformingToTypeIdentifier(utiType) {
                            itemAllowed = true
                            break
                        }
                    }
                } else {
                    // Handle exact string matching
                    if #available(iOS 14.0, *) {
                        if let utType = UTType(mimeType: allowedType) {
                            if dragItem.itemProvider.hasItemConformingToTypeIdentifier(utType.identifier) {
                                itemAllowed = true
                                break
                            }
                        }
                    } else {
                        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, allowedType as CFString, nil)?.takeRetainedValue() {
                            if dragItem.itemProvider.hasItemConformingToTypeIdentifier(uti as String) {
                                itemAllowed = true
                                break
                            }
                        }
                    }
                }

                if itemAllowed { break }
            }

            if !itemAllowed {
                return false
            }
        }

        return true
        } else {
        // For exact string matching, check if any items have allowed MIME types
        for (itemIndex, dragItem) in session.items.enumerated() {
            // Convert allowed MIME types to UTI identifiers
            var allowedTypeIdentifiers: [String] = []

            for mimeType in allowedMimeTypes {
                if #available(iOS 14.0, *) {
                    if let utType = UTType(mimeType: mimeType) {
                        allowedTypeIdentifiers.append(utType.identifier)
                    }
                } else {
                    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() {
                        allowedTypeIdentifiers.append(uti as String)
                    }
                }
            }

            // Check if this drag item conforms to any allowed type
            let hasAllowedType = allowedTypeIdentifiers.contains { typeIdentifier in
                return dragItem.itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier)
            }

            if !hasAllowedType {
                return false
            }
        }

        return true
    }
}
