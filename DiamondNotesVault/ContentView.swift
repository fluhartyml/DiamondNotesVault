//
//  ContentView.swift
//  DiamondNotesVault
//
//  Temporary: Shows editor directly for testing with file persistence
//

import SwiftUI

struct ContentView: View {
    @State private var appState = AppState.shared
    @State private var fileManager = FileSystemManager.shared
    @State private var noteTitle = ""
    @State private var noteContent = NSAttributedString()
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            EditorView(
                title: noteTitle,
                attributedContent: noteContent,
                onSave: { title, content in
                    saveNote(title: title, content: content)
                },
                onDelete: {
                    deleteNote()
                }
            )
            .navigationTitle(appState.libraryName ?? "Note")
        }
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
            // Scan library to rebuild indexes
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
            loadLastNote()
        }
    }

    private func loadLastNote() {
        guard let noteURL = appState.lastEditedNoteURL else {
            return
        }

        do {
            let (title, content) = try fileManager.loadNote(from: noteURL)
            noteTitle = title
            noteContent = content
            appState.currentNoteURL = noteURL
        } catch {
            print("Failed to load note: \(error)")
        }
    }

    private func saveNote(title: String, content: NSAttributedString) {
        // Determine file URL
        let noteURL: URL
        if let existingURL = appState.currentNoteURL {
            noteURL = existingURL
        } else {
            // Create new note in user's chosen library
            guard let libraryURL = appState.getLibraryURL() else {
                print("No library configured")
                return
            }
            let filename = fileManager.generateFilename(from: title)
            noteURL = libraryURL.appendingPathComponent(filename)
        }

        do {
            try fileManager.saveNote(title: title, attributedContent: content, to: noteURL)
            appState.currentNoteURL = noteURL
            appState.saveLastEditedNote(noteURL)
            print("Note saved to: \(noteURL.path)")
        } catch {
            print("Failed to save note: \(error)")
        }
    }

    private func deleteNote() {
        guard let noteURL = appState.currentNoteURL else {
            print("No note to delete")
            return
        }

        do {
            try fileManager.deleteNote(at: noteURL)
            appState.currentNoteURL = nil
            appState.lastEditedNoteURL = nil
            noteTitle = ""
            noteContent = NSAttributedString()
            print("Note deleted from: \(noteURL.path)")
        } catch {
            print("Failed to delete note: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
