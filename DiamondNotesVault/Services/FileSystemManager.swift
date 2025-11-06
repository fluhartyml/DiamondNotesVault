//
//  FileSystemManager.swift
//  DiamondNotesVault
//
//  Created by Claude on 11/6/25 at 10:39.
//

import Foundation

@MainActor
final class FileSystemManager: @unchecked Sendable {
    static let shared = FileSystemManager()

    private init() {}

    /// iCloud Documents directory URL
    var iCloudDocumentsURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent("DiamondNotesVault")
    }

    /// Local fallback directory if iCloud not available
    var localDocumentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DiamondNotesVault")
    }

    /// Active vault directory (iCloud if available, local fallback)
    var vaultURL: URL {
        iCloudDocumentsURL ?? localDocumentsURL
    }

    /// Check if iCloud is available
    var isICloudAvailable: Bool {
        iCloudDocumentsURL != nil
    }

    /// Create vault directory structure if needed
    func setupVaultDirectory() async throws {
        let url = vaultURL

        if !FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )
        }
    }

    /// Create folder directory
    func createFolder(name: String, parentPath: String = "") async throws -> URL {
        let folderURL = vaultURL
            .appendingPathComponent(parentPath)
            .appendingPathComponent(name)

        try FileManager.default.createDirectory(
            at: folderURL,
            withIntermediateDirectories: true
        )

        // Create media subfolder
        let mediaURL = folderURL.appendingPathComponent("media")
        try FileManager.default.createDirectory(
            at: mediaURL,
            withIntermediateDirectories: true
        )

        return folderURL
    }

    /// Save post to markdown file
    func savePost(_ post: Post, folder: Folder, breadcrumb: String) async throws {
        let filename = post.generateFilename(breadcrumb: breadcrumb)
        let fileURL = vaultURL.appendingPathComponent(breadcrumb).appendingPathComponent(filename)

        let markdownContent = """
        # \(post.title)

        \(post.content)
        """

        try markdownContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Delete post file
    func deletePost(filename: String, breadcrumb: String) async throws {
        let fileURL = vaultURL.appendingPathComponent(breadcrumb).appendingPathComponent(filename)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
