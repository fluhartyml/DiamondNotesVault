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
    var libraryURL: URL?  // Current notebook binder URL
    var parentLibraryURL: URL?  // Parent library folder URL (OnionBlog)
    var hasCompletedOnboarding: Bool = false

    private let lastEditedKey = "lastEditedNoteURL"
    private let libraryNameKey = "libraryName"
    private let libraryURLKey = "libraryURL"
    private let libraryBookmarkKey = "libraryBookmark"  // Bookmark for current binder
    private let parentLibraryBookmarkKey = "parentLibraryBookmark"  // Bookmark for parent library
    private let onboardingKey = "hasCompletedOnboarding"

    private init() {
        loadPersistedState()
    }

    // MARK: - Persistence

    func saveLastEditedNote(_ url: URL) {
        lastEditedNoteURL = url
        UserDefaults.standard.set(url.path, forKey: lastEditedKey)
    }

    func saveLibraryConfiguration(name: String, url: URL, parentURL: URL? = nil) {
        libraryName = name
        libraryURL = url
        hasCompletedOnboarding = true

        UserDefaults.standard.set(name, forKey: libraryNameKey)
        UserDefaults.standard.set(url.path, forKey: libraryURLKey)
        UserDefaults.standard.set(true, forKey: onboardingKey)

        // Create security-scoped bookmark for the selected binder
        do {
            let bookmarkData = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmarkData, forKey: libraryBookmarkKey)
            print("Security-scoped bookmark created for binder: \(url.path)")
        } catch {
            print("Failed to create binder bookmark: \(error)")
        }

        // If parent library URL provided, save bookmark for it too
        if let parent = parentURL {
            parentLibraryURL = parent
            do {
                let parentBookmarkData = try parent.bookmarkData(
                    options: .minimalBookmark,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(parentBookmarkData, forKey: parentLibraryBookmarkKey)
                print("Security-scoped bookmark created for parent library: \(parent.path)")
            } catch {
                print("Failed to create parent library bookmark: \(error)")
            }
        } else {
            // Derive parent from binder URL
            let derivedParent = url.deletingLastPathComponent()
            parentLibraryURL = derivedParent
            print("DEBUG: Derived parent library URL: \(derivedParent.path)")
        }
    }

    private func loadPersistedState() {
        // Load onboarding status
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)

        // Load library configuration
        if let name = UserDefaults.standard.string(forKey: libraryNameKey) {
            libraryName = name
        }

        // Try to restore from security-scoped bookmark first
        if let bookmarkData = UserDefaults.standard.data(forKey: libraryBookmarkKey) {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withoutUI,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                // Start accessing the security-scoped resource
                if url.startAccessingSecurityScopedResource() {
                    libraryURL = url
                    print("Restored library URL from bookmark: \(url.path)")

                    if isStale {
                        print("Bookmark is stale, refreshing...")
                        saveLibraryConfiguration(name: libraryName ?? "Library", url: url)
                    }
                } else {
                    print("Failed to access security-scoped resource")
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
                // Fall back to path-based loading
                if let path = UserDefaults.standard.string(forKey: libraryURLKey) {
                    libraryURL = URL(fileURLWithPath: path)
                }
            }
        } else if let path = UserDefaults.standard.string(forKey: libraryURLKey) {
            // Fallback: Try path-based loading
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
