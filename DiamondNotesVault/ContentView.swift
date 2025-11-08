//
//  ContentView.swift
//  DiamondNotesVault
//
//  Main app view - shows notes list with navigation to editor
//

import SwiftUI

struct ContentView: View {
    @State private var appState = AppState.shared
    @State private var fileManager = FileSystemManager.shared
    @State private var showOnboarding = false

    var body: some View {
        NotesListView()
            .onAppear {
                checkOnboarding()
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
                    .interactiveDismissDisabled()
            }
    }

    private func checkOnboarding() {
        if !appState.hasCompletedOnboarding {
            showOnboarding = true
        } else {
            // Scan library to rebuild indexes on app launch
            if let libraryURL = appState.getLibraryURL() {
                Task {
                    do {
                        try fileManager.scanLibrary(libraryURL: libraryURL)
                        print("Library scanned and indexes updated")
                    } catch {
                        print("Failed to scan library: \(error)")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
