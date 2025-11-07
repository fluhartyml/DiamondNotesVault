//
//  PageMetadataEditor.swift
//  DiamondNotesVault
//
//  UX for editing page metadata (tags)
//

import SwiftUI

struct PageMetadataEditor: View {
    @Binding var page: PageMetadata
    @Environment(\.dismiss) private var dismiss

    @State private var tagsText: String

    init(page: Binding<PageMetadata>) {
        self._page = page
        self._tagsText = State(initialValue: page.wrappedValue.tags.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    Text(page.title)
                        .font(.headline)
                }

                Section("Tags") {
                    TextField("Comma-separated tags", text: $tagsText)
                        .autocapitalization(.none)
                    Text("Separate tags with commas: important, work, draft")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Preview") {
                    Text(page.preview)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                Section("Statistics") {
                    LabeledContent("Word Count", value: "\(page.wordCount)")
                    LabeledContent("Created", value: page.createdDate.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Modified", value: page.lastModified.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Has Frontmatter", value: page.hasFrontmatter ? "Yes" : "No")
                }
            }
            .navigationTitle("Edit Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        page.tags = tagsText.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        page.lastModified = Date()
    }
}

#Preview {
    PageMetadataEditor(page: .constant(PageMetadata(
        id: "2025-NOV-07-Test-Note.md",
        title: "2025 NOV 07 Test Note",
        tags: ["test", "development"],
        preview: "This is a test note for the Diamond Notes Vault application...",
        wordCount: 247,
        createdDate: Date(),
        lastModified: Date(),
        hasFrontmatter: true
    )))
}
