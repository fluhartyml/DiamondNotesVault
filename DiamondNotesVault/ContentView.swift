//
//  ContentView.swift
//  DiamondNotesVault
//
//  Created by Michael Fluharty on 11/6/25.
//
//  NOTE: This file exists for Xcode template compatibility.
//  The actual app starts with FolderListView in DiamondNotesVaultApp.swift
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        FolderListView(parentID: nil)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Folder.self, Post.self], inMemory: true)
}
