//
//  OnboardingView.swift
//  DiamondNotesVault
//
//  First-launch onboarding: library name, location picker, notebook creation
//

import SwiftUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    @State private var appState = AppState.shared
    @State private var mode: OnboardingMode = .choice
    @State private var libraryName = "Diamond Library"
    @State private var showLocationPicker = false
    @State private var selectedLocation: URL?

    @Environment(\.dismiss) private var dismiss

    enum OnboardingMode {
        case choice
        case newLibrary
        case existingFolder
        case selectNotebookBinder  // New step: select notebook binder within library
    }

    @State private var availableNotebooks: [URL] = []
    @State private var selectedNotebook: URL?
    @State private var showCreateBinderSheet = false
    @State private var newBinderName = ""
    @State private var accessingURLs: [URL] = []  // Track URLs we're accessing for cleanup

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if mode == .choice {
                    choiceView
                } else if mode == .newLibrary {
                    newLibraryView
                } else if mode == .existingFolder {
                    existingFolderView
                } else if mode == .selectNotebookBinder {
                    selectNotebookBinderView
                }
            }
            .padding()
            .navigationTitle("Welcome to Diamond Notes Vault")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showLocationPicker) {
            DocumentPicker(selectedURL: $selectedLocation)
        }
        .onChange(of: selectedLocation) { _, newLocation in
            if mode == .existingFolder, let location = newLocation {
                // Security-scoped resource access is already started in DocumentPicker
                // Track this URL so we can stop accessing later
                if !accessingURLs.contains(location) {
                    accessingURLs.append(location)
                }

                // When folder selected, scan for notebook binders
                scanForNotebookBinders(in: location)
                mode = .selectNotebookBinder
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
                            createNewBinderDuringOnboarding()
                        }
                        .disabled(newBinderName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
        .onDisappear {
            // Clean up security-scoped resource access
            for url in accessingURLs {
                url.stopAccessingSecurityScopedResource()
            }
            accessingURLs.removeAll()
        }
    }

    // MARK: - Choice View

    private var choiceView: some View {
        VStack(spacing: 40) {
            Text("Get Started")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 20) {
                Button(action: {
                    mode = .newLibrary
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 50))
                        Text("Create New Library")
                            .font(.headline)
                        Text("Start fresh with a new notes library")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)

                Button(action: {
                    mode = .existingFolder
                    showLocationPicker = true
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "folder")
                            .font(.system(size: 50))
                        Text("Use Existing Folder")
                            .font(.headline)
                        Text("Point to your current notes folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - New Library View

    private var newLibraryView: some View {
        VStack(spacing: 30) {
            Text("Create New Library")
                .font(.title2)

            TextField("Library Name", text: $libraryName)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .multilineTextAlignment(.center)

            Text("Suggestion: Diamond Library")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let location = selectedLocation {
                VStack(spacing: 10) {
                    Text("Location:")
                        .font(.headline)
                    Text(location.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
            }

            Button("Choose Location") {
                showLocationPicker = true
            }
            .buttonStyle(.bordered)

            Spacer()

            HStack {
                Button("Back") {
                    mode = .choice
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Create") {
                    createNewLibrary()
                }
                .buttonStyle(.borderedProminent)
                .disabled(libraryName.isEmpty || selectedLocation == nil)
            }
        }
    }

    // MARK: - Existing Folder View

    private var existingFolderView: some View {
        VStack(spacing: 30) {
            Text("Select Library Folder")
                .font(.title2)

            Text("Choose the parent folder containing your notebook binders")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let location = selectedLocation {
                VStack(spacing: 10) {
                    Text("Selected:")
                        .font(.headline)
                    Text(location.lastPathComponent)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(location.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text("Next: Choose a notebook binder inside this folder")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .padding(.top, 8)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
            } else {
                Text("No folder selected")
                    .foregroundStyle(.secondary)
            }

            Button("Choose Folder") {
                showLocationPicker = true
            }
            .buttonStyle(.bordered)

            Spacer()

            HStack {
                Button("Back") {
                    mode = .choice
                    selectedLocation = nil
                }
                .buttonStyle(.bordered)
            }
        }
    }


    // MARK: - Actions

    private func createNewLibrary() {
        guard let baseLocation = selectedLocation else { return }

        let libraryURL = baseLocation.appendingPathComponent(libraryName)

        do {
            // Create library directory
            try FileManager.default.createDirectory(at: libraryURL, withIntermediateDirectories: true)

            // Save to app state
            appState.saveLibraryConfiguration(name: libraryName, url: libraryURL)

            // Dismiss onboarding
            dismiss()
        } catch {
            print("Failed to create library: \(error)")
        }
    }

    // MARK: - Select Notebook Binder View

    private var selectNotebookBinderView: some View {
        VStack(spacing: 30) {
            Text("Select Notebook Binder")
                .font(.title2)

            if availableNotebooks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)

                    Text("No Notebook Binders Found")
                        .font(.headline)

                    Text("This library folder doesn't contain any subfolders to use as notebook binders.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create your first binder:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("• Tap 'Create New Binder' below")
                        Text("• Or tap 'Back' to choose a different library")
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
            } else {
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
                                    Text("Add a new binder to organize your notes")
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

                        ForEach(availableNotebooks, id: \.self) { notebook in
                            Button {
                                selectedNotebook = notebook
                            } label: {
                                HStack {
                                    Image(systemName: "book.closed.fill")
                                        .foregroundStyle(.blue)
                                    Text(notebook.lastPathComponent)
                                        .font(.body)
                                    Spacer()
                                    if selectedNotebook == notebook {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding()
                                .background(selectedNotebook == notebook ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Spacer()

            HStack {
                Button("Back") {
                    mode = .existingFolder
                    selectedNotebook = nil
                    availableNotebooks = []
                }
                .buttonStyle(.bordered)

                Spacer()

                // Only show the Use button if a binder is selected
                if selectedNotebook != nil {
                    Button("Use This Notebook Binder") {
                        useSelectedNotebookBinder()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Actions

    private func scanForNotebookBinders(in libraryURL: URL) {
        print("DEBUG: Scanning for notebook binders in: \(libraryURL.path)")
        print("DEBUG: libraryURL is security-scoped: \(libraryURL.startAccessingSecurityScopedResource())")
        // If we just started accessing, we need to balance with a stop later
        // But actually it was already started in DocumentPicker, so this returns false

        // Check if we can read the directory
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: libraryURL.path, isDirectory: &isDir)
        print("DEBUG: Path exists: \(exists), isDirectory: \(isDir.boolValue)")

        guard exists && isDir.boolValue else {
            print("DEBUG: ERROR - Path doesn't exist or is not a directory!")
            availableNotebooks = []
            return
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: libraryURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            print("DEBUG: Found \(contents.count) total items in folder")

            availableNotebooks = contents.filter { url in
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
                let isDir = isDirectory.boolValue
                let notMedia = url.lastPathComponent != "media"
                print("DEBUG: \(url.lastPathComponent) - isDirectory: \(isDir), notMedia: \(notMedia)")
                return isDir && notMedia
            }

            print("DEBUG: Found \(availableNotebooks.count) notebook binders in \(libraryURL.lastPathComponent)")
            for notebook in availableNotebooks {
                print("DEBUG:   - \(notebook.lastPathComponent)")
            }
        } catch {
            print("DEBUG: Failed to scan for notebook binders: \(error)")
            print("DEBUG: Error details: \(error.localizedDescription)")
            availableNotebooks = []
        }
    }

    private func useSelectedNotebookBinder() {
        guard let notebookURL = selectedNotebook else { return }

        // Use the notebook binder name as library name
        let notebookName = notebookURL.lastPathComponent

        // Get parent library URL
        let parentURL = selectedLocation

        // Save to app state with parent library URL
        appState.saveLibraryConfiguration(name: notebookName, url: notebookURL, parentURL: parentURL)

        // Dismiss onboarding
        dismiss()
    }

    private func createNewBinderDuringOnboarding() {
        guard let parentURL = selectedLocation else {
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

            // Save to app state and complete onboarding
            appState.saveLibraryConfiguration(name: trimmedName, url: newBinderURL, parentURL: parentURL)

            // Close sheet and dismiss onboarding
            newBinderName = ""
            showCreateBinderSheet = false
            dismiss()
        } catch {
            print("Failed to create notebook binder: \(error)")
        }
    }

    // REMOVED: useExistingFolder() - Users must now select a notebook within the library
    // The onChange(of: selectedLocation) handler automatically proceeds to notebook selection
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var selectedURL: URL?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("ERROR: Failed to access security-scoped resource: \(url.path)")
                parent.dismiss()
                return
            }

            print("DEBUG: Successfully started accessing security-scoped resource: \(url.path)")
            parent.selectedURL = url
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    OnboardingView()
}
