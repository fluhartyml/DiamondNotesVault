//
//  DiamondNotesVault_DeveloperNotes.swift
//  DiamondNotesVault
//
//  Created by Michael Fluharty on 11/6/25.
//

/*

 # Diamond Notes Vault — Developer Notes

 **Filename:** `DiamondNotesVault_DeveloperNotes.swift`
 **Location:** `/Users/michaelfluharty/Developer/NightGard/DiamondNotesVault/DiamondNotesVault/`
 **Purpose:** Persistent memory & knowledge base for Diamond Notes Vault project (NightGard Ecosystem)

 ---

 ## Project Description

 **Diamond Notes Vault** - iOS blogging application combining Obsidian's structure with Apple Notes' UX.
 Part of the NightGard ecosystem of tools.

 **Primary Purpose:** CLI Claude CMS interface for blogging with WYSIWYG editing that Obsidian lacks.

 ---

 ## Purpose

 - Project-specific knowledge base for Diamond Notes Vault
 - Captures decisions, TODOs, and workflow rules
 - Serves as **PERSISTENT MEMORY** for AI assistants (Claude, ChatGPT) across chat sessions
 - Lives within the Xcode project for immediate AI continuity
 - References main NightGard developer notes in CLI Claude apartment

 ---

 ## Developer Information

 **Developer:** Michael Fluharty
 - **Contact Email:** michael@fluharty.com
 - **Website:** www.fluharty.me
 - **Apple Developer ID:** michael.fluharty@mac.com
 - **GitHub:** fluhartyml
 - **Bundle ID:** com.NightGuard.DiamondNotesVault

 ---

 ## How to Use This File

 - Add entries with timestamp: `[YYYY MMM DD HHMM] (author) Description`
 - Keep newest entries at the TOP of Project Status section for quick scanning
 - Use author tags: `(MF)` for Claude writing on behalf of user, `(MLF)` for user, `(Claude)` for Claude entries
 - For multi-line notes, use simple `-` bullets
 - If a note implies code changes, treat as separate explicit task
 - Reference main NightGard notes: `~/Developer/NightGard/CLI Claude/Memory/NG_DeveloperNotes.md`

 ---

 ## Project Overview

 Diamond Notes Vault is an iOS blogging application that combines:
 - Obsidian's transparent folder structure and infinite organization depth
 - Apple Notes' WYSIWYG editing experience and intuitive interface
 - Part of the NightGard ecosystem

 **Primary Purpose:** CLI Claude CMS interface for blogging with WYSIWYG editing

 **Bundle ID:** com.NightGuard.DiamondNotesVault
 **Swift Version:** 6.0+ (strict concurrency enabled)
 **Deployment Target:** iOS 28+
 **App Store:** Sandboxed, compliant with App Store Connect distribution


 ## Core Philosophy

 1. **"Just Works™"** - Minimal configuration, intuitive operation out of the box
 2. **Transparent** - All file structures human-readable, manually editable
 3. **User Configurable** - Infinite flexibility while maintaining simplicity
 4. **Apple Design Language** - Clone of Apple Notes + Reminders patterns
 5. **Opposite of Community Plugins** - No complex setup required


 ## Architecture Overview

 ### Navigation Hierarchy (Sheet-Based)

 1. **Root Picker** - List of blogs/folders with Edit mode
 2. **Folder/Section View** - Navigate deeper into folder structure
 3. **Post List** - Chronological view with auto-generated today entry
 4. **WYSIWYG Editor** - Full Apple Notes clone

 Each level is its own sheet with:
 - Edit button (minus circles + drag handles)
 - Search (contextual to current location)
 - Plus button for adding new items
 - Safari-style back button navigation


 ## File Structure (iCloud Drive)

 ```
 iCloud Drive/DiamondNotesVault/
 ├─ Personal Blog/
 │  ├─ .config.json
 │  ├─ Announcements/
 │  │  ├─ .config.json
 │  │  ├─ media/
 │  │  └─ 2025 NOV 05 New App [Announcements].md
 │  └─ Personal/
 │     ├─ .config.json
 │     ├─ media/
 │     └─ 2025 NOV 06 Morning Thoughts [Personal].md
 └─ Work Blog/
    └─ ...
 ```

 ### File Naming Convention

 **Automatic:** `YYYY MMM DD [Title][Breadcrumb].md`

 - Date: Auto-generated on post creation
 - Title: Extracted from first line or user input
 - Breadcrumb: Folder hierarchy (e.g., [Announcements/Product-Launches])
 - Makes files self-documenting even if moved


 ## Key Features

 ### 1. Infinite Folder Depth
 - Users define their own structure
 - Can nest blogs within blogs, sections within sections
 - No fixed hierarchy - total flexibility
 - Example: Private/ → Personal/ → Daily Journal/ → Morning Thoughts/

 ### 2. Auto-Today Entry
 - Top of every post list shows: `2025 NOV 06 <<no text>>`
 - Only persists if content added (title or body)
 - Prevents bloat from empty dated entries
 - Per-section, not global

 ### 3. Smart Auto-Save/Delete
 - **Auto-save:** Every keystroke saved immediately to iCloud
 - **Auto-delete:** Backspace all content → file removed automatically
 - **Swipe-to-delete:** Standard iOS swipe left on post titles
 - No "Save" button needed

 ### 4. Contextual Search
 - Root level: searches all blogs/folders
 - Within folder: searches that folder first, then others
 - Results ordered by user-defined priority (drag handles)
 - Results grouped by section

 ### 5. Edit Mode
 - Edit button in nav bar (standard iOS pattern)
 - Shows minus circles (delete) + drag handles (reorder)
 - Plus button to add new folder/section
 - Delete dialog: "Move all posts to Uncategorized?"


 ## Data Models (To Be Implemented)

 ### Folder
 - id: UUID
 - name: String
 - parentID: UUID?
 - displayOrder: Int
 - configPath: URL
 - lastModified: Date

 ### Post
 - id: UUID
 - title: String
 - folderID: UUID
 - filePath: URL
 - dateCreated: Date
 - lastModified: Date
 - breadcrumb: String

 ### FolderConfig (.config.json)
 ```json
 {
   "displayOrder": ["item1", "item2"],
   "tags": ["tag1", "tag2"],
   "folderIndex": 0,
   "publishDestination": "https://...",
   "lastModified": "2025-11-06T10:30:00Z"
 }
 ```


 ## Publishing Workflow (CLI Claude CMS)

 ### Phase 1 (MVP) - Manual
 1. User writes blog post in Diamond Notes Vault (iPhone)
 2. Post auto-saves to iCloud Drive
 3. File syncs to Mac automatically
 4. User tells CLI Claude: "Publish new posts from Personal blog"
 5. Claude reads markdown from iCloud folder
 6. Claude converts to HTML and publishes to portfolio

 ### Phase 2 (Future) - Integrated
 - Git integration
 - Blogger API
 - Direct Claude CMS publishing
 - A folder becomes "publishable" when destination configured


 ## Development Phases

 ### Phase 1 - MVP (Current)
 - [x] Create Xcode project
 - [x] Configure Swift 6
 - [ ] Enable iCloud entitlements
 - [ ] Enable App Sandbox
 - [ ] Build folder navigation (sheet-based)
 - [ ] Create post list view with auto-today entry
 - [ ] Build WYSIWYG editor (Apple Notes clone)
 - [ ] Implement auto-save on keystroke
 - [ ] Implement auto-delete on backspace all content
 - [ ] Set up iCloud Drive integration
 - [ ] Implement file naming convention
 - [ ] Create .config.json per folder
 - [ ] Build search functionality
 - [ ] Add Edit mode (reorder/delete)

 ### Phase 2 - Future Enhancements
 - [ ] Tags system
 - [ ] Publishing integrations (git, Blogger, Claude CMS)
 - [ ] Wikilinks `[[Note Title]]`
 - [ ] Mind map view (Obsidian-style graph)
 - [ ] Advanced blog management


 ## Technical Requirements

 ### Swift 6 Concurrency
 - Strict concurrency checking enabled
 - Modern async/await patterns
 - Proper `@MainActor` annotations
 - `Sendable` protocol compliance
 - Actor isolation where needed

 ### iCloud Integration
 - Document-based app using UIDocument
 - iCloud container: iCloud.com.NightGuard.DiamondNotesVault
 - File coordination for conflict resolution
 - NSFilePresenter for real-time updates

 ### App Store Compliance
 - App Sandbox enabled
 - Proper entitlements configured
 - Privacy descriptions for photo/video access
 - Compliant with App Store guidelines
 - Ready for TestFlight and App Store Connect


 ## Design Patterns

 ### UI Patterns (Apple Native)
 - **Apple Notes** - Editor experience
 - **Apple Reminders** - Organization patterns
 - **iOS Files** - Sheet navigation
 - **Safari** - Back button behavior
 - **Standard iOS** - Edit mode (minus circles + drag handles)

 ### Screen Space Priority
 - Minimal chrome - screen space is premium on iOS
 - Post lists show ONLY titles (no thumbnails/snippets)
 - Section cards: title + maybe post count (decided based on visual testing)
 - Clean, focused interface


 ## Known Limitations (MVP)

 - No publishing integration (manual workflow only)
 - No tags system (Phase 2)
 - No wikilinks (Phase 2)
 - No mind map view (Phase 2)
 - Markdown formatting limited to Apple Notes feature set


 ## AI Continuity Notes

 When working on this project:
 1. Always reference this file for project context
 2. Follow Apple's design guidelines strictly
 3. Maintain Swift 6 concurrency compliance
 4. Keep file structure transparent and human-readable
 5. Test on real device with iCloud sync
 6. Update this file when architecture changes
 7. Reference Diamond Notes Vault Kanban in ~/Developer/NightGard/CLI Claude/Workspace/
 8. Check project summary at ~/Developer/NightGard/CLI Claude/Journal/2025-11-06-Diamond-Notes-Vault-Project-Summary.md
 9. Review OnionBlog post at ~/Developer/NightGard/CLI Claude/Journal/OnionBlog/Claude-Sessions/2025 NOV 06 Diamond Notes Vault Project Kickoff [Claude-Sessions].md


 ## Project Links

 - **Kanban Board:** ~/Developer/NightGard/CLI Claude/Workspace/Diamond-Notes-Vault-Kanban.md
 - **Project Summary:** ~/Developer/NightGard/CLI Claude/Journal/2025-11-06-Diamond-Notes-Vault-Project-Summary.md
 - **Blog Post:** ~/Developer/NightGard/CLI Claude/Journal/OnionBlog/Claude-Sessions/2025 NOV 06 Diamond Notes Vault Project Kickoff [Claude-Sessions].md
 - **Architecture Canvas:** ~/Developer/NightGard/CLI Claude/Workshop/Diamond-Notes-Vault-Architecture.canvas

 ---

 ## Project Status & Chat Summary

 ### [2025 NOV 06 0930] (Claude) Diamond Notes Vault - Initial Project Setup
 - **Q&A Design Session:** Structured question-and-answer session to define project requirements
   - One question at a time methodology to explore design space methodically
   - Established core philosophy: "Just Works™" out of the box, transparent, Apple design language
   - Determined navigation: Sheet-based hierarchy (Root → Folder → Posts → Editor)
   - Confirmed file format: Markdown with WYSIWYG display
   - Defined auto-naming: `YYYY MMM DD [Title][Breadcrumb].md`
   - Decided on infinite folder depth (total user flexibility)
   - Auto-today entry that only persists if content added
   - Contextual search (current folder first, then by priority)
 - **Project Name:** "Diamond Notes Vault" chosen (strong, transparent, secure metaphor)
   - Diamond = strong, transparent, unbreakable
   - Vault = secure storage, Obsidian connection
   - Part of NightGard ecosystem (com.NightGuard.DiamondNotesVault)
 - **Documentation Created:**
   - Project summary: ~/Developer/NightGard/CLI Claude/Journal/2025-11-06-Diamond-Notes-Vault-Project-Summary.md
   - OnionBlog post: ~/Developer/NightGard/CLI Claude/Journal/OnionBlog/Claude-Sessions/2025 NOV 06 Diamond Notes Vault Project Kickoff [Claude-Sessions].md
   - Architecture canvas: ~/Developer/NightGard/CLI Claude/Workshop/Diamond-Notes-Vault-Architecture.canvas
   - Kanban board: ~/Developer/NightGard/CLI Claude/Workspace/Diamond-Notes-Vault-Kanban.md
 - **Xcode Project Created:**
   - Location: /Users/michaelfluharty/Developer/NightGard/DiamondNotesVault/
   - Bundle ID: com.NightGuard.DiamondNotesVault
   - Team: Michael Fluharty
   - Storage: SwiftData
   - CloudKit: Enabled (Host in CloudKit checked)
   - Swift Language Version: Swift 6 (resolved)
 - **Developer Notes:** Created this file for AI continuity within project
   - Structured like main NG_DeveloperNotes.md in CLI Claude apartment
   - Provides persistent memory for AI assistants across sessions
   - Includes comprehensive architecture, features, and development phases
 - **Next Steps:**
   - Configure iCloud entitlements (iCloud Documents)
   - Enable App Sandbox capability
   - Begin implementing folder navigation UI
   - Build post list with auto-today entry
   - Create WYSIWYG editor (Apple Notes clone)
 - **Status:** Foundation complete, ready for Phase 1 MVP development

 ---

 ## Developer Notes Log (Historical)

 ### Critical Workflow Rules
 - [2025 NOV 06 0930] (Claude) Project follows main NightGard workflow rules from NG_DeveloperNotes.md
 - [2025 NOV 06 0930] (Claude) Swift 6 strict concurrency enabled from project start
 - [2025 NOV 06 0930] (Claude) App Store compliance: Sandboxed, iCloud enabled, proper entitlements

 ---

 *This file serves as persistent memory for AI assistants working on Diamond Notes Vault.*

 *Last updated: 2025-NOV-06 0930*

 */

// This file is for documentation purposes only and should not be compiled into the app
// To exclude from compilation, ensure this file is not part of any target membership
// or mark it as documentation in Xcode file inspector

import Foundation

// MARK: - Project Constants

enum ProjectConstants {
    static let bundleIdentifier = "com.NightGuard.DiamondNotesVault"
    static let iCloudContainerIdentifier = "iCloud.com.NightGuard.DiamondNotesVault"
    static let appName = "Diamond Notes Vault"
    static let fileNamingPattern = "YYYY MMM DD [Title][Breadcrumb].md"
    static let configFileName = ".config.json"
    static let mediaFolderName = "media"
}

// MARK: - Development Notes

enum DevelopmentPhase {
    case mvp
    case phase2

    var description: String {
        switch self {
        case .mvp:
            return "Phase 1 - MVP: Core navigation, editing, and file management"
        case .phase2:
            return "Phase 2 - Future: Tags, publishing, wikilinks, mind maps"
        }
    }
}
