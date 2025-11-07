//
//  TableOfContents.swift
//  DiamondNotesVault
//
//  .toc.json structure for notebook indexing
//

import Foundation

struct TableOfContents: Codable {
    var notebookName: String
    var lastUpdated: Date
    var notes: [NoteEntry]

    struct NoteEntry: Codable {
        var filename: String
        var title: String
        var created: Date
        var modified: Date
        var order: Int
    }
}

extension FileSystemManager {
    /// Update or create .toc.json AND Index.md in notebook directory
    func updateTableOfContents(notebookURL: URL) throws {
        let tocURL = notebookURL.appendingPathComponent(".toc.json")
        let indexURL = notebookURL.appendingPathComponent("Index.md")
        let notebookName = notebookURL.lastPathComponent

        // Scan directory for .md files
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(
            at: notebookURL,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )

        let mdFiles = contents.filter {
            $0.pathExtension == "md" && $0.lastPathComponent != "Index.md"
        }
        var noteEntries: [TableOfContents.NoteEntry] = []

        for (index, fileURL) in mdFiles.enumerated() {
            let attributes = try fileURL.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let created = attributes.creationDate ?? Date()
            let modified = attributes.contentModificationDate ?? Date()

            // Extract title from file
            let (title, _) = try loadNote(from: fileURL)

            let entry = TableOfContents.NoteEntry(
                filename: fileURL.lastPathComponent,
                title: title,
                created: created,
                modified: modified,
                order: index
            )
            noteEntries.append(entry)
        }

        // Sort by modification date, newest first
        noteEntries.sort { $0.modified > $1.modified }

        // Create TOC
        let toc = TableOfContents(
            notebookName: notebookName,
            lastUpdated: Date(),
            notes: noteEntries
        )

        // Save .toc.json (for app use)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(toc)
        try data.write(to: tocURL)

        // Generate Index.md (for human readability)
        let indexMarkdown = generateIndexMarkdown(toc: toc)
        try indexMarkdown.write(to: indexURL, atomically: true, encoding: .utf8)
    }

    /// Generate human-readable Index.md from TOC
    private func generateIndexMarkdown(toc: TableOfContents) -> String {
        var markdown = "# \(toc.notebookName)\n\n"
        markdown += "*Last updated: \(formatDate(toc.lastUpdated))*\n\n"
        markdown += "---\n\n"

        if toc.notes.isEmpty {
            markdown += "*No notes yet*\n"
        } else {
            markdown += "## Notes (\(toc.notes.count))\n\n"

            for note in toc.notes {
                markdown += "### [\(note.title)](\(note.filename))\n"
                markdown += "- **Created:** \(formatDate(note.created))\n"
                markdown += "- **Modified:** \(formatDate(note.modified))\n\n"
            }
        }

        return markdown
    }

    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Scan entire library and rebuild all notebook indexes
    func scanLibrary(libraryURL: URL) throws {
        let fileManager = FileManager.default

        // Get all subdirectories (notebooks)
        let contents = try fileManager.contentsOfDirectory(
            at: libraryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for item in contents {
            let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues.isDirectory == true {
                // This is a notebook - update its TOC
                try updateTableOfContents(notebookURL: item)
            }
        }
    }

    /// Read .toc.json file from notebook directory
    func readTableOfContents(notebookURL: URL) throws -> TableOfContents {
        let tocURL = notebookURL.appendingPathComponent(".toc.json")
        let data = try Data(contentsOf: tocURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TableOfContents.self, from: data)
    }
}
