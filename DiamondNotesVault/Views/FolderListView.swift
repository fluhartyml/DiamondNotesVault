//
//  FolderListView.swift
//  DiamondNotesVault
//
//  Created by Claude on 11/6/25 at 10:39.
//

import SwiftUI
import SwiftData

@MainActor
struct FolderListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFolders: [Folder]

    @State private var isEditing = false
    @State private var searchText = ""

    var parentID: UUID?

    // Filter folders by parent
    var folders: [Folder] {
        allFolders
            .filter { $0.parentID == parentID }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(folders) { folder in
                    NavigationLink(value: folder) {
                        FolderRow(folder: folder)
                    }
                }
                .onDelete(perform: deleteFolders)
                .onMove(perform: moveFolders)
            }
            .navigationTitle(parentID == nil ? "Blogs & Folders" : "Folders")
            .navigationDestination(for: Folder.self) { folder in
                FolderDetailView(folder: folder)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Done") {
                            isEditing = false
                        }
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addFolder) {
                        Label("Add Folder", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search all blogs & folders")
            .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
        }
    }

    private func addFolder() {
        let newFolder = Folder(
            name: "New Folder",
            parentID: parentID,
            displayOrder: folders.count
        )
        modelContext.insert(newFolder)
    }

    private func deleteFolders(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(folders[index])
        }
    }

    private func moveFolders(from source: IndexSet, to destination: Int) {
        var reorderedFolders = folders
        reorderedFolders.move(fromOffsets: source, toOffset: destination)

        // Update display order
        for (index, folder) in reorderedFolders.enumerated() {
            folder.displayOrder = index
        }
    }
}

struct FolderRow: View {
    let folder: Folder

    var body: some View {
        HStack {
            Image(systemName: "folder.fill")
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.headline)

                Text(folder.dateModified, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FolderListView(parentID: nil)
        .modelContainer(for: [Folder.self, Post.self], inMemory: true)
}
