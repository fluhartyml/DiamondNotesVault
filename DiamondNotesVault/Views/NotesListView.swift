//
//  NotesListView.swift
//  DiamondNotesVault
//
//  List of all notes in current notebook binder
//

import SwiftUI

struct NotesListView: View {
    @State private var appState = AppState.shared
    @State private var fileManager = FileSystemManager.shared
    @State private var notes: [TableOfContents.NoteEntry] = []
    @State private var showEditor = false
    @State private var selectedNoteURL: URL?
    @State private var isCreatingNewNote = false
    @State private var showNotebookPicker = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(notes, id: \.filename) { note in
                    Button {
                        openNote(note)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title)
                                .font(.headline)

                            Text(formatDate(note.modified))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(appState.libraryName ?? "Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showNotebookPicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "book.closed.fill")
                            Text("Binders")
                                .font(.subheadline)
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewNote()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .onAppear {
                loadNotes()
            }
            .sheet(isPresented: $showNotebookPicker) {
                NotebookPickerView(appState: appState)
            }
            .sheet(isPresented: $showEditor) {
                if let noteURL = selectedNoteURL {
                    NavigationStack {
                        NoteEditorWrapper(
                            noteURL: noteURL,
                            isNewNote: isCreatingNewNote,
                            onDismiss: {
                                showEditor = false
                                loadNotes() // Refresh list when editor closes
                            }
                        )
                    }
                }
            }
        }
    }

    private func loadNotes() {
        guard let libraryURL = appState.getLibraryURL() else {
            print("No library configured")
            return
        }

        do {
            // Update TOC to get latest notes
            try fileManager.updateTableOfContents(notebookURL: libraryURL)

            // Load TOC
            let toc = try fileManager.readTableOfContents(notebookURL: libraryURL)
            notes = toc.notes

            print("Loaded \(notes.count) notes from notebook")
        } catch {
            print("Failed to load notes: \(error)")
            notes = []
        }
    }

    private func openNote(_ note: TableOfContents.NoteEntry) {
        guard let libraryURL = appState.getLibraryURL() else { return }

        let noteURL = libraryURL.appendingPathComponent(note.filename)
        selectedNoteURL = noteURL
        isCreatingNewNote = false
        showEditor = true
    }

    private func createNewNote() {
        guard let libraryURL = appState.getLibraryURL() else {
            print("No library configured")
            return
        }

        // Create temporary new note filename
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy MMM dd"
        let dateString = dateFormatter.string(from: Date())
        let filename = "\(dateString) [New Note].md"
        let noteURL = libraryURL.appendingPathComponent(filename)

        selectedNoteURL = noteURL
        isCreatingNewNote = true
        showEditor = true
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Note Editor Wrapper

struct NoteEditorWrapper: View {
    let noteURL: URL
    let isNewNote: Bool
    let onDismiss: () -> Void

    @State private var title: String = ""
    @State private var content: NSAttributedString = NSAttributedString()
    @State private var fileManager = FileSystemManager.shared
    @State private var appState = AppState.shared

    var body: some View {
        EditorView(
            title: title,
            attributedContent: content,
            onSave: { newTitle, newContent in
                saveNote(title: newTitle, content: newContent)
            },
            onDelete: {
                deleteNote()
            },
            onDone: { newTitle, newContent in
                saveNote(title: newTitle, content: newContent)
                onDismiss()
            }
        )
        .onAppear {
            loadNoteIfExists()
        }
    }

    private func loadNoteIfExists() {
        // For existing notes, load from file
        if !isNewNote && FileManager.default.fileExists(atPath: noteURL.path) {
            do {
                let (loadedTitle, loadedContent) = try fileManager.loadNote(from: noteURL)
                title = loadedTitle
                content = loadedContent
                appState.currentNoteURL = noteURL
            } catch {
                print("Failed to load note: \(error)")
            }
        } else {
            // New note - start with empty content
            appState.currentNoteURL = noteURL
        }
    }

    private func saveNote(title: String, content: NSAttributedString) {
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
        do {
            try fileManager.deleteNote(at: noteURL)
            appState.currentNoteURL = nil
            onDismiss()
        } catch {
            print("Failed to delete note: \(error)")
        }
    }
}

#Preview {
    NotesListView()
}
