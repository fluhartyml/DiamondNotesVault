//
//  Folder.swift
//  DiamondNotesVault
//
//  Created by Claude on 11/6/25 at 10:39.
//

import Foundation
import SwiftData

@Model
final class Folder: Identifiable {
    var id: UUID
    var name: String
    var parentID: UUID?
    var displayOrder: Int
    var dateCreated: Date
    var dateModified: Date

    // Relationships
    @Relationship(deleteRule: .cascade)
    var posts: [Post]?

    init(
        id: UUID = UUID(),
        name: String,
        parentID: UUID? = nil,
        displayOrder: Int = 0,
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.parentID = parentID
        self.displayOrder = displayOrder
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    /// Returns the breadcrumb path for file naming
    func breadcrumbPath(in folders: [Folder]) -> String {
        var path: [String] = [name]
        var currentParentID = parentID

        while let parentID = currentParentID {
            if let parent = folders.first(where: { $0.id == parentID }) {
                path.insert(parent.name, at: 0)
                currentParentID = parent.parentID
            } else {
                break
            }
        }

        return path.joined(separator: "/")
    }
}
