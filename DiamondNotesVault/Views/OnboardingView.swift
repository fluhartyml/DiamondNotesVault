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
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                if mode == .choice {
                    choiceView
                } else if mode == .newLibrary {
                    newLibraryView
                } else {
                    existingFolderView
                }
            }
            .padding()
            .navigationTitle("Welcome to Diamond Notes Vault")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showLocationPicker) {
            DocumentPicker(selectedURL: $selectedLocation)
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
            Text("Use Existing Folder")
                .font(.title2)

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
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Use This Folder") {
                    useExistingFolder()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedLocation == nil)
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

    private func useExistingFolder() {
        guard let libraryURL = selectedLocation else { return }

        // Use the folder name as library name
        let libraryName = libraryURL.lastPathComponent

        // Save to app state (folder already exists, no need to create)
        appState.saveLibraryConfiguration(name: libraryName, url: libraryURL)

        // Dismiss onboarding
        dismiss()
    }
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
            parent.selectedURL = urls.first
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
