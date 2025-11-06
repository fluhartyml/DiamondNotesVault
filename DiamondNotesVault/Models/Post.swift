//
//  Post.swift
//  DiamondNotesVault
//
//  Created by Claude on 11/6/25 at 10:39.
//

import Foundation
import SwiftData

@Model
final class Post: Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var dateCreated: Date = Date()
    var dateModified: Date = Date()

    // Relationship
    var folder: Folder?

    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        folder: Folder? = nil,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.folder = folder
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    /// Generates filename using convention: YYYY MMM DD [Title][Breadcrumb].md
    func generateFilename(breadcrumb: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM dd"
        let dateString = formatter.string(from: dateCreated).uppercased()

        let sanitizedTitle = title.isEmpty ? "Untitled" : title
        return "\(dateString) \(sanitizedTitle) [\(breadcrumb)].md"
    }

    /// Returns display date string
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: dateCreated)
    }
}
