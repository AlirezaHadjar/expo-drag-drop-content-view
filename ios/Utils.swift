//
//  Utils.swift
//  ExpoDragDropContentView
//
//  Created by Alireza Hadjar on 8/23/23.
//

import Foundation
import MobileCoreServices
import ImageIO

func extractImageData(image: UIImage) -> Data? {
    let imageData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(imageData as CFMutableData, kUTTypeJPEG, 1, nil) else {
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

    CGImageDestinationAddImage(destination, image.cgImage!, imageProps)

    CGImageDestinationFinalize(destination)

    return imageData as Data
}

func getImageFileName(fileType: String) -> String {
    var fileName = UUID().uuidString
    fileName.append(".")
    return fileName.appending(fileType)
}

func getFileType(imageData: Data) -> String {
    let firstByteJpg: UInt8 = 0xFF
    let firstBytePng: UInt8 = 0x89
    let firstByteGif: UInt8 = 0x47

    var firstByte: UInt8 = 0
    imageData.copyBytes(to: &firstByte, count: 1)

    switch firstByte {
    case firstByteJpg:
        return "jpg"
    case firstBytePng:
        return "png"
    case firstByteGif:
        return "gif"
    default:
        return "jpg"
    }
}

func getMimeType(image: UIImage) -> String? {
    if let imageData = image.jpegData(compressionQuality: 1.0) {
        if let imageDataProvider = CGDataProvider(data: imageData as CFData) {
            if let imageSource = CGImageSourceCreateWithDataProvider(imageDataProvider, nil) {
                if let imageType = CGImageSourceGetType(imageSource) {
                    if let imageUTI = UTTypeCopyPreferredTagWithClass(imageType, kUTTagClassMIMEType) {
                        return imageUTI.takeRetainedValue() as String
                    }
                }
            }
        }
    }

    return nil
}

func generateAsset (image: UIImage, includeBase64: Bool) -> NSMutableDictionary? {
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
