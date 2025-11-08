//
//  NotebookPickerView.swift
//  DiamondNotesVault
//
//  Notebook binder picker sheet for switching between notebook binders after onboarding
//

import SwiftUI

struct NotebookPickerView: View {
    @State var appState: AppState
    @State private var libraryIndex: LibraryIndex?
    @State private var indexManager = IndexManager.shared
    @State private var selectedNotebook: NotebookMetadata?
    @State private var showMetadataEditor = false
    @State private var notebookToEdit: NotebookMetadata?
    @State private var showCreateBinderSheet = false
    @State private var newBinderName = ""
    @State private var groupByTags = false  // Toggle for section view
    @State private var showCreateSectionSheet = false
    @State private var newSectionName = ""
    @State private var editMode: EditMode = .inactive
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section View Toggle
                if let index = libraryIndex, !index.notebooks.isEmpty {
                    HStack {
                        Toggle(isOn: $groupByTags) {
                            Label("Show Sections", systemImage: "books.vertical")
                                .font(.subheadline)
                        }
                        .toggleStyle(.switch)
                        .tint(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.1))
                }

                if let index = libraryIndex, !index.notebooks.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Create New Binder Button
                            Button {
                                showCreateBinderSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.system(size: 32))

                                    VStack(alignment: .leading) {
                                        Text("Create New Notebook Binder")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("Add a new folder to organize your notes")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)

                            // Show grouped or flat view
                            if groupByTags {
                                groupedBindersView()
                            } else {
                                flatBindersView()
                            }
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)

                        Text("No Notebook Binders Found")
                            .font(.headline)

                        Text("Unable to find notebook binders in this library.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Try:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("• Tap the refresh button (↻) above")
                            Text("• Or add folders in Files app")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)

                        Button {
                            showCreateBinderSheet = true
                        } label: {
                            Label("Create New Notebook Binder", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Notebook Binder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .environment(\.editMode, $editMode)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        rebuildIndex()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .onAppear {
                loadIndex()
            }
            .sheet(isPresented: $showMetadataEditor) {
                if let notebook = notebookToEdit,
                   let index = libraryIndex,
                   let notebookIndex = index.notebooks.firstIndex(where: { $0.id == notebook.id }) {
                    NotebookMetadataEditor(notebook: Binding(
                        get: { index.notebooks[notebookIndex] },
                        set: { updatedNotebook in
                            saveNotebookMetadata(updatedNotebook)
                        }
                    ))
                }
            }
            .sheet(isPresented: $showCreateBinderSheet) {
                NavigationStack {
                    Form {
                        Section("Notebook Binder Name") {
                            TextField("Enter name", text: $newBinderName)
                                .autocapitalization(.words)
                        }

                        Section {
                            Text("Examples: Work, Personal, Projects, Archive")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("New Notebook Binder")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                newBinderName = ""
                                showCreateBinderSheet = false
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                createNewBinder()
                            }
                            .disabled(newBinderName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateSectionSheet) {
                NavigationStack {
                    Form {
                        Section("Section Name") {
                            TextField("Enter section name", text: $newSectionName)
                                .autocapitalization(.words)
                        }

                        Section {
                            Text("Examples: Fiction, Non-Fiction, Work, Personal, Reference")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Sections are like library shelves that organize your binders")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("New Section")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                newSectionName = ""
                                showCreateSectionSheet = false
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("Create") {
                                createNewSection()
                            }
                            .disabled(newSectionName.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
            }
        }
    }

    private func isCurrentNotebook(_ notebook: NotebookMetadata) -> Bool {
        guard let libraryURL = appState.libraryURL else { return false }
        return libraryURL.lastPathComponent == notebook.id
    }

    @MainActor
    private func loadIndex() {
        guard let parentURL = getParentLibraryURL() else {
            print("No library URL configured")
            return
        }

        do {
            libraryIndex = try indexManager.loadLibraryIndex(libraryURL: parentURL)
            print("Loaded library index with \(libraryIndex?.notebooks.count ?? 0) notebook binders")
        } catch {
            print("Failed to load library index: \(error)")
        }
    }

    @MainActor
    private func rebuildIndex() {
        guard let parentURL = getParentLibraryURL() else { return }

        do {
            try indexManager.rebuildLibraryIndex(libraryURL: parentURL)
            libraryIndex = try indexManager.loadLibraryIndex(libraryURL: parentURL)
            print("Rebuilt library index with notebook binders")
        } catch {
            print("Failed to rebuild index: \(error)")
        }
    }

    private func getParentLibraryURL() -> URL? {
        // First try to use the stored parent library URL
        if let parentURL = appState.parentLibraryURL {
            print("DEBUG: Using stored parent library URL: \(parentURL.path)")
            return parentURL
        }

        // Fallback: derive from current binder URL
        guard let libraryURL = appState.libraryURL else { return nil }
        let derivedParent = libraryURL.deletingLastPathComponent()
        print("DEBUG: Derived parent library URL: \(derivedParent.path)")
        return derivedParent
    }

    private func switchToNotebook(_ notebook: NotebookMetadata) {
        guard let parentURL = getParentLibraryURL() else { return }
        let notebookURL = parentURL.appendingPathComponent(notebook.id)

        // Update app state with new notebook binder
        appState.saveLibraryConfiguration(name: notebook.displayName, url: notebookURL)

        print("Switched to notebook binder: \(notebook.displayName)")

        // Dismiss the picker
        dismiss()
    }

    @MainActor
    private func saveNotebookMetadata(_ notebook: NotebookMetadata) {
        guard let parentURL = getParentLibraryURL() else { return }

        do {
            try indexManager.updateNotebookMetadata(
                libraryURL: parentURL,
                notebookID: notebook.id,
                displayName: notebook.displayName,
                description: notebook.description,
                tags: notebook.tags,
                icon: notebook.icon,
                color: notebook.color
            )

            // Reload index to reflect changes
            libraryIndex = try indexManager.loadLibraryIndex(libraryURL: parentURL)
            print("Saved notebook binder metadata for: \(notebook.displayName)")
        } catch {
            print("Failed to save notebook binder metadata: \(error)")
        }
    }

    // MARK: - View Helpers

    @ViewBuilder
    private func flatBindersView() -> some View {
        if let index = libraryIndex {
            ForEach(index.notebooks) { notebook in
            NotebookCard(
                notebook: notebook,
                isSelected: isCurrentNotebook(notebook),
                onTap: {
                    switchToNotebook(notebook)
                },
                onEdit: {
                    notebookToEdit = notebook
                    showMetadataEditor = true
                }
            )
        }
            .onDelete { indexSet in
                deleteNotebooks(at: indexSet)
            }
            .onMove { from, to in
                moveNotebooks(from: from, to: to)
            }
        }
    }

    @ViewBuilder
    private func groupedBindersView() -> some View {
        if let index = libraryIndex {
            let grouped = Dictionary(grouping: index.notebooks) { notebook -> String in
                // Group by first tag (Section), or "General Section" if no tags
                notebook.tags.first ?? "General Section"
            }

            VStack(spacing: 12) {
                // Create Section button
                Button {
            showCreateSectionSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 32))

                VStack(alignment: .leading) {
                    Text("Create New Section")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Add a new section to organize binders")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)

        ForEach(grouped.keys.sorted(), id: \.self) { sectionName in
            VStack(alignment: .leading, spacing: 8) {
                // Section Header (like library shelf label)
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .foregroundStyle(.brown)
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(sectionName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("\(grouped[sectionName]?.count ?? 0) binders")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.brown.opacity(0.2), Color.brown.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)

                // Binders in this section (books on the shelf)
                ForEach(grouped[sectionName] ?? []) { notebook in
                    HStack(spacing: 12) {
                        // Indent to show hierarchy
                        Rectangle()
                            .fill(Color.brown.opacity(0.3))
                            .frame(width: 3)

                        NotebookCard(
                            notebook: notebook,
                            isSelected: isCurrentNotebook(notebook),
                            onTap: {
                                switchToNotebook(notebook)
                            },
                            onEdit: {
                                notebookToEdit = notebook
                                showMetadataEditor = true
                            }
                        )
                    }
                }
            }
        }
            }
        }
    }

    private func createNewBinder() {
        guard let parentURL = getParentLibraryURL() else {
            print("No parent library URL")
            return
        }

        let trimmedName = newBinderName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let newBinderURL = parentURL.appendingPathComponent(trimmedName)

        do {
            // Create the directory
            try FileManager.default.createDirectory(at: newBinderURL, withIntermediateDirectories: true)
            print("Created new notebook binder: \(newBinderURL.path)")

            // Create media folder inside it
            let mediaURL = newBinderURL.appendingPathComponent("media")
            try FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: true)
            print("Created media folder: \(mediaURL.path)")

            // Rebuild index to include new binder
            rebuildIndex()

            // Switch to the new binder
            appState.saveLibraryConfiguration(name: trimmedName, url: newBinderURL, parentURL: parentURL)

            // Close sheet and picker
            newBinderName = ""
            showCreateBinderSheet = false
            dismiss()
        } catch {
            print("Failed to create notebook binder: \(error)")
        }
    }

    @MainActor
    private func createNewSection() {
        guard let parentURL = getParentLibraryURL() else {
            print("No parent library URL")
            return
        }

        let trimmedName = newSectionName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        // Create a new binder in this section
        // The binder name will be "[Section] Binder 1"
        let binderName = "\(trimmedName) Binder 1"
        let newBinderURL = parentURL.appendingPathComponent(binderName)

        do {
            // Create the directory
            try FileManager.default.createDirectory(at: newBinderURL, withIntermediateDirectories: true)
            print("Created new notebook binder: \(newBinderURL.path)")

            // Create media folder inside it
            let mediaURL = newBinderURL.appendingPathComponent("media")
            try FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: true)
            print("Created media folder: \(mediaURL.path)")

            // Rebuild index to include new binder
            rebuildIndex()

            // Find the newly created binder in the index and set its section tag
            if let index = libraryIndex,
               let newNotebook = index.notebooks.first(where: { $0.id == binderName }) {
                do {
                    try indexManager.updateNotebookMetadata(
                        libraryURL: parentURL,
                        notebookID: newNotebook.id,
                        displayName: newNotebook.displayName,
                        description: newNotebook.description,
                        tags: [trimmedName], // Set section as first tag
                        icon: newNotebook.icon,
                        color: newNotebook.color
                    )

                    // Reload index to reflect changes
                    libraryIndex = try indexManager.loadLibraryIndex(libraryURL: parentURL)
                    print("Created new section '\(trimmedName)' with first binder")
                } catch {
                    print("Failed to set section tag: \(error)")
                }
            }

            // Close sheet (but keep picker open to show new section)
            newSectionName = ""
            showCreateSectionSheet = false

            // Enable grouped view to show the new section
            groupByTags = true
        } catch {
            print("Failed to create section: \(error)")
        }
    }

    // MARK: - Edit Mode Actions

    @MainActor
    private func deleteNotebooks(at offsets: IndexSet) {
        guard let parentURL = getParentLibraryURL(),
              let index = libraryIndex else { return }

        // Get notebooks to delete
        let notebooksToDelete = offsets.map { index.notebooks[$0] }

        do {
            // Delete each notebook folder
            for notebook in notebooksToDelete {
                let notebookURL = parentURL.appendingPathComponent(notebook.id)
                try FileManager.default.removeItem(at: notebookURL)
                print("Deleted notebook: \(notebook.displayName)")
            }

            // Rebuild index after deletion
            try indexManager.rebuildLibraryIndex(libraryURL: parentURL)
            libraryIndex = try indexManager.loadLibraryIndex(libraryURL: parentURL)
        } catch {
            print("Failed to delete notebooks: \(error)")
        }
    }

    @MainActor
    private func moveNotebooks(from source: IndexSet, to destination: Int) {
        guard let parentURL = getParentLibraryURL(),
              let index = libraryIndex else { return }

        // Create mutable copy of notebooks array
        var updatedNotebooks = index.notebooks

        // Perform the move
        updatedNotebooks.move(fromOffsets: source, toOffset: destination)

        // Update the library index with new order
        var updatedIndex = index
        updatedIndex.notebooks = updatedNotebooks
        updatedIndex.lastModified = Date()

        do {
            // Save the reordered index
            try indexManager.saveLibraryIndex(updatedIndex, to: parentURL)
            libraryIndex = updatedIndex
            print("Reordered notebooks")
        } catch {
            print("Failed to reorder notebooks: \(error)")
        }
    }
}

// MARK: - Notebook Card

struct NotebookCard: View {
    let notebook: NotebookMetadata
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Icon
                    Text(notebook.icon ?? "📓")
                        .font(.system(size: 32))

                    VStack(alignment: .leading, spacing: 2) {
                        // Display name
                        Text(notebook.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        // Note count
                        Text("\(notebook.noteCount) notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Edit button
                    Button(action: onEdit) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)

                    // Checkmark if selected
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }

                // Description
                if !notebook.description.isEmpty {
                    Text(notebook.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Tags
                if !notebook.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(notebook.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(colorForName(notebook.color ?? "blue").opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(
                isSelected
                    ? colorForName(notebook.color ?? "blue").opacity(0.1)
                    : Color.secondary.opacity(0.1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .blue
        }
    }
}

#Preview {
    NotebookPickerView(appState: AppState.shared)
}
