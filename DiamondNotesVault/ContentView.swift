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
                },
                onDone: { title, content in
                    finalizeNote(title: title, content: content)
                }
            )
            .id(appState.currentNoteURL?.path ?? "new-note")  // Force recreation when note changes
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
        print("DEBUG: loadLastNote called")

        guard let noteURL = appState.lastEditedNoteURL else {
            print("DEBUG: No lastEditedNoteURL, starting with blank note")
            return
        }

        print("DEBUG: Loading note from: \(noteURL.path)")

        do {
            let (title, content) = try fileManager.loadNote(from: noteURL)
            noteTitle = title
            noteContent = content
            appState.currentNoteURL = noteURL
            print("DEBUG: Note loaded successfully - title: '\(title)', content length: \(content.length)")
        } catch {
            print("DEBUG: Failed to load note: \(error)")
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

    private func finalizeNote(title: String, content: NSAttributedString) {
        print("DEBUG: finalizeNote called in ContentView")
        print("DEBUG: Title to save = '\(title)'")
        print("DEBUG: Content length = \(content.length)")

        // Save the current note one final time
        saveNote(title: title, content: content)
        print("DEBUG: saveNote completed")

        // Clear current note URL to signal we're starting a new note
        // Keep lastEditedNoteURL pointing to the saved note for history
        print("DEBUG: Clearing currentNoteURL but keeping lastEditedNoteURL")
        let finalizedNoteURL = appState.currentNoteURL
        appState.currentNoteURL = nil
        // Don't clear lastEditedNoteURL - it points to the finalized note

        // Reset editor to new note with auto-populated date
        print("DEBUG: Resetting noteTitle and noteContent")
        noteTitle = ""
        noteContent = NSAttributedString()

        print("DEBUG: Note finalized (saved at \(finalizedNoteURL?.path ?? "unknown")), editor reset for new note")
    }
}

#Preview {
    ContentView()
}
