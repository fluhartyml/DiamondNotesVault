//
//  FolderDetailView.swift
//  DiamondNotesVault
//
//  Created by Claude on 11/6/25 at 10:39.
//

import SwiftUI
import SwiftData

@MainActor
struct FolderDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allFolders: [Folder]
    @Query private var allPosts: [Post]

    let folder: Folder

    @State private var searchText = ""

    // Get posts for this folder, sorted by date
    var posts: [Post] {
        allPosts
            .filter { $0.folderID == folder.id }
            .sorted { $0.dateCreated > $1.dateCreated }
    }

    // Get subfolders
    var subfolders: [Folder] {
        allFolders
            .filter { $0.parentID == folder.id }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    var body: some View {
        List {
            // Auto-today entry at top
            AutoTodayEntry(folder: folder)

            // Subfolders section
            if !subfolders.isEmpty {
                Section("Folders") {
                    ForEach(subfolders) { subfolder in
                        NavigationLink(value: subfolder) {
                            FolderRow(folder: subfolder)
                        }
                    }
                }
            }

            // Posts section
            if !posts.isEmpty {
                Section("Posts") {
                    ForEach(posts) { post in
                        NavigationLink(value: post) {
                            PostRow(post: post)
                        }
                    }
                    .onDelete(perform: deletePosts)
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationDestination(for: Folder.self) { subfolder in
            FolderDetailView(folder: subfolder)
        }
        .navigationDestination(for: Post.self) { post in
            PostEditorView(post: post, folder: folder)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: addSubfolder) {
                    Label("Add Folder", systemImage: "folder.badge.plus")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search in \(folder.name)")
    }

    private func addSubfolder() {
        let newFolder = Folder(
            name: "New Folder",
            parentID: folder.id,
            displayOrder: subfolders.count
        )
        modelContext.insert(newFolder)
    }

    private func deletePosts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(posts[index])
        }
    }
}

struct PostRow: View {
    let post: Post

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.title.isEmpty ? "Untitled" : post.title)
                .font(.headline)

            Text(post.displayDate)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AutoTodayEntry: View {
    @Environment(\.modelContext) private var modelContext
    let folder: Folder

    var body: some View {
        Button(action: createTodayPost) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(todayString())
                        .font(.headline)

                    Text("<<no text>>")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy MMM dd"
        return formatter.string(from: Date()).uppercased()
    }

    private func createTodayPost() {
        let newPost = Post(
            title: todayString(),
            content: "",
            folderID: folder.id
        )
        modelContext.insert(newPost)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Folder.self, Post.self, configurations: config)

    let folder = Folder(name: "Personal")
    container.mainContext.insert(folder)

    return NavigationStack {
        FolderDetailView(folder: folder)
            .modelContainer(container)
    }
}
