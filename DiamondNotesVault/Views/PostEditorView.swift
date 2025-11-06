//
//  PostEditorView.swift
//  DiamondNotesVault
//
//  Created by Claude on 11/6/25 at 10:39.
//

import SwiftUI
import SwiftData

@MainActor
struct PostEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let post: Post
    let folder: Folder

    @State private var title: String
    @State private var content: String
    @FocusState private var isEditing: Bool

    init(post: Post, folder: Folder) {
        self.post = post
        self.folder = folder
        _title = State(initialValue: post.title)
        _content = State(initialValue: post.content)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title field
            TextField("Title", text: $title)
                .font(.title2.bold())
                .padding()
                .background(Color(.systemBackground))

            Divider()

            // Content editor (basic for now - will enhance to WYSIWYG later)
            TextEditor(text: $content)
                .font(.body)
                .padding()
                .focused($isEditing)
        }
        .navigationTitle("Edit Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Button("Bold") {
                        // TODO: Implement formatting
                    }
                    Button("Italic") {
                        // TODO: Implement formatting
                    }
                    Spacer()
                    Button("Done") {
                        isEditing = false
                    }
                }
            }
        }
        .onChange(of: title) { _, newValue in
            saveChanges(title: newValue, content: content)
        }
        .onChange(of: content) { _, newValue in
            saveChanges(title: title, content: newValue)
        }
        .onDisappear {
            // Auto-delete if empty
            if title.isEmpty && content.isEmpty {
                modelContext.delete(post)
            }
        }
    }

    private func saveChanges(title: String, content: String) {
        post.title = title
        post.content = content
        post.dateModified = Date()

        // Save to disk will be handled by persistence layer
        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Post.self, configurations: config)

    let folder = Folder(name: "Personal")
    let post = Post(title: "Test Post", content: "Sample content", folder: folder)

    container.mainContext.insert(folder)
    container.mainContext.insert(post)

    return NavigationStack {
        PostEditorView(post: post, folder: folder)
            .modelContainer(container)
    }
}
