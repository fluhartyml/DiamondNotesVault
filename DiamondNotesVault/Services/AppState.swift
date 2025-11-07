//
//  AppState.swift
//  DiamondNotesVault
//
//  App-wide state management
//

import Foundation
import SwiftUI

@Observable
class AppState {
    static let shared = AppState()

    var currentNoteURL: URL?
    var lastEditedNoteURL: URL?
    var libraryName: String?
    var libraryURL: URL?
    var hasCompletedOnboarding: Bool = false

    private let lastEditedKey = "lastEditedNoteURL"
    private let libraryNameKey = "libraryName"
    private let libraryURLKey = "libraryURL"
    private let onboardingKey = "hasCompletedOnboarding"

    private init() {
        loadPersistedState()
    }

    // MARK: - Persistence

    func saveLastEditedNote(_ url: URL) {
        lastEditedNoteURL = url
        UserDefaults.standard.set(url.path, forKey: lastEditedKey)
    }

    func saveLibraryConfiguration(name: String, url: URL) {
        libraryName = name
        libraryURL = url
        hasCompletedOnboarding = true

        UserDefaults.standard.set(name, forKey: libraryNameKey)
        UserDefaults.standard.set(url.path, forKey: libraryURLKey)
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    private func loadPersistedState() {
        // Load onboarding status
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)

        // Load library configuration
        if let name = UserDefaults.standard.string(forKey: libraryNameKey) {
            libraryName = name
        }
        if let path = UserDefaults.standard.string(forKey: libraryURLKey) {
            libraryURL = URL(fileURLWithPath: path)
        }

        // Load last edited note
        if let path = UserDefaults.standard.string(forKey: lastEditedKey) {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                lastEditedNoteURL = url
            }
        }
    }

    // MARK: - Library Paths

    /// Get the root library directory URL
    func getLibraryURL() -> URL? {
        return libraryURL
    }

    /// Get a specific notebook directory URL
    func getNotebookURL(named notebookName: String) -> URL? {
        guard let libraryURL = libraryURL else { return nil }
        return libraryURL.appendingPathComponent(notebookName)
    }
}
