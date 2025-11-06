//
//  DiamondNotesVaultApp.swift
//  DiamondNotesVault
//
//  Created by Michael Fluharty on 11/6/25.
//

import SwiftUI
import SwiftData

@main
struct DiamondNotesVaultApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Folder.self,
            Post.self,
        ])
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            FolderListView(parentID: nil)
        }
        .modelContainer(sharedModelContainer)
    }
}
