//
//  LibraryIndex.swift
//  DiamondNotesVault
//
//  Library-level index.json structure
//
//  Terminology:
//  - Library: Parent folder (e.g., OnionBlog) containing all notebooks
//  - Notebook/Binder: Subfolder (e.g., Claude-Sessions) containing pages
//  - Page: Individual markdown file (e.g., 2025-NOV-07-Note.md)
//  - Media: Pocket folder (media/) in each notebook holding images/videos
//

import Foundation

/// Root library index (e.g., OnionBlog/index.json)
/// Tracks all notebooks (binders) within the parent library folder
struct LibraryIndex: Codable {
    var libraryName: String
    var createdDate: Date
    var lastModified: Date
    var notebooks: [NotebookMetadata]

    enum CodingKeys: String, CodingKey {
        case libraryName, createdDate, lastModified, notebooks
    }
}

/// Metadata about a notebook/binder within the library
/// Each notebook is a subfolder containing pages and a media pocket folder
struct NotebookMetadata: Codable, Identifiable {
    var id: String  // Folder name
    var displayName: String  // User-editable display name
    var description: String  // User-editable description
    var tags: [String]  // User-editable tags for categorization
    var icon: String?  // Optional emoji or SF Symbol name
    var color: String?  // Optional color identifier
    var noteCount: Int
    var lastModified: Date
    var createdDate: Date

    enum CodingKeys: String, CodingKey {
        case id, displayName, description, tags, icon, color
        case noteCount, lastModified, createdDate
    }
}

// MARK: - Notebook TOC

/// Individual notebook/binder's table of contents (e.g., Claude-Sessions/toc.json)
/// Tracks all pages (markdown files) within this notebook subfolder
struct NotebookTOC: Codable {
    var notebookName: String
    var displayName: String
    var description: String
    var tags: [String]
    var createdDate: Date
    var lastModified: Date
    var pages: [PageMetadata]

    enum CodingKeys: String, CodingKey {
        case notebookName, displayName, description, tags
        case createdDate, lastModified, pages
    }
}

/// Metadata about a page (note) within a notebook/binder
/// Each page is an individual markdown file
struct PageMetadata: Codable, Identifiable {
    var id: String  // Filename
    var title: String  // First line or filename
    var tags: [String]  // User-editable tags
    var preview: String  // First few lines of content
    var wordCount: Int
    var createdDate: Date
    var lastModified: Date
    var hasFrontmatter: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, tags, preview, wordCount
        case createdDate, lastModified, hasFrontmatter
    }
}

// MARK: - Page Frontmatter

/// YAML-style frontmatter at the top of markdown files
/// Format:
/// ---
/// title: My Note Title
/// tags: [tag1, tag2, tag3]
/// created: 2025-11-07T14:30:00Z
/// modified: 2025-11-07T15:45:00Z
/// ---
struct PageFrontmatter: Codable {
    var title: String?
    var tags: [String]
    var created: Date?
    var modified: Date?
    var customFields: [String: String]  // User-extensible

    enum CodingKeys: String, CodingKey {
        case title, tags, created, modified, customFields
    }

    init(title: String? = nil, tags: [String] = [], created: Date? = nil, modified: Date? = nil, customFields: [String: String] = [:]) {
        self.title = title
        self.tags = tags
        self.created = created
        self.modified = modified
        self.customFields = customFields
    }
}
