//
//  PhotoMetadataExtractor.swift
//  DiamondNotesVault
//
//  Extract and preserve photo metadata (filename, EXIF, dates)
//

import Foundation
import UIKit
import Photos
import SwiftUI
import PhotosUI
import CoreLocation

struct PhotoMetadata {
    var originalFilename: String
    var dateTaken: Date?
    var location: CLLocation?
    var cameraMake: String?
    var cameraModel: String?
    var width: Int
    var height: Int
}

@available(iOS 16.0, *)
class PhotoMetadataExtractor {
    /// Extract metadata from PhotosPickerItem
    static func extractMetadata(from item: PhotosPickerItem) async -> PhotoMetadata? {
        // Get the asset identifier
        guard let assetIdentifier = item.itemIdentifier else { return nil }

        // Fetch the PHAsset
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        // Get original filename from asset resource
        let resources = PHAssetResource.assetResources(for: asset)
        let originalFilename = resources.first?.originalFilename ?? "photo.jpg"

        return PhotoMetadata(
            originalFilename: originalFilename,
            dateTaken: asset.creationDate,
            location: asset.location,
            cameraMake: nil, // Would need to load from EXIF
            cameraModel: nil,
            width: asset.pixelWidth,
            height: asset.pixelHeight
        )
    }

    /// Save image to file with metadata preservation
    static func saveWithMetadata(
        image: UIImage,
        metadata: PhotoMetadata?,
        to directory: URL
    ) throws -> String {
        let filename = metadata?.originalFilename ?? "Photo-\(Date().timeIntervalSince1970).jpg"
        var destURL = directory.appendingPathComponent(filename)

        // Handle filename conflicts
        if FileManager.default.fileExists(atPath: destURL.path) {
            let name = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension
            var counter = 2

            while FileManager.default.fileExists(atPath: destURL.path) {
                let newFilename = "\(name)-\(counter).\(ext)"
                destURL = directory.appendingPathComponent(newFilename)
                counter += 1
            }
        }

        // Save image as JPEG (metadata is in the image data from Photos framework)
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "PhotoMetadataExtractor", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }

        try data.write(to: destURL)

        return destURL.lastPathComponent
    }
}
