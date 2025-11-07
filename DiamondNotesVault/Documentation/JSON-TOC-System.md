# JSON TOC System - Diamond Notes Vault

## Overview

The JSON TOC (Table of Contents) system provides hierarchical metadata management for the entire library structure:

- **Library** (e.g., OnionBlog) → Parent folder containing all notebooks → `index.json` at root
- **Notebook/Binder** (e.g., Claude-Sessions) → Subfolder containing pages → `toc.json` in each notebook folder
- **Page** (e.g., 2025-NOV-07-Note.md) → Individual markdown files (notes) → Frontmatter at top of file
- **Media** (media/) → Pocket folder in each notebook holding images/videos used in pages

## Structure

### 1. Library Level: `index.json`

Located at: `OnionBlog/index.json`

```json
{
  "libraryName": "OnionBlog",
  "createdDate": "2025-11-07T14:30:00Z",
  "lastModified": "2025-11-07T15:45:00Z",
  "notebooks": [
    {
      "id": "Claude-Sessions",
      "displayName": "🤖 Claude Sessions",
      "description": "Technical conversations and development logs",
      "tags": ["tech", "ai", "development"],
      "icon": "🤖",
      "color": "blue",
      "noteCount": 42,
      "lastModified": "2025-11-06T14:30:00Z",
      "createdDate": "2025-10-01T09:00:00Z"
    },
    {
      "id": "Personal",
      "displayName": "📝 Personal",
      "description": "Private thoughts and reflections",
      "tags": ["journal", "personal"],
      "icon": "📝",
      "color": "green",
      "noteCount": 128,
      "lastModified": "2025-11-05T09:15:00Z",
      "createdDate": "2025-09-15T12:00:00Z"
    }
  ]
}
```

**User-Editable Fields:**
- `displayName` - Show custom name instead of folder name
- `description` - Short description of notebook purpose
- `tags` - Categorize notebooks (searchable/filterable)
- `icon` - Emoji or symbol for visual identification
- `color` - Color theme for UI elements

**Auto-Generated Fields:**
- `noteCount` - Number of markdown files
- `lastModified` - Most recent change
- `createdDate` - Folder creation date

### 2. Notebook Level: `toc.json`

Located at: `OnionBlog/Claude-Sessions/toc.json`

```json
{
  "notebookName": "Claude-Sessions",
  "displayName": "🤖 Claude Sessions",
  "description": "Technical conversations and development logs",
  "tags": ["tech", "ai", "development"],
  "createdDate": "2025-10-01T09:00:00Z",
  "lastModified": "2025-11-06T14:30:00Z",
  "pages": [
    {
      "id": "2025-NOV-06-Diamond-Notes-Vault-Project-Summary.md",
      "title": "2025 NOV 06 Diamond Notes Vault Project Summary",
      "tags": ["project", "summary", "ios"],
      "preview": "Complete specification and architecture for Diamond Notes Vault...",
      "wordCount": 1247,
      "createdDate": "2025-11-06T10:30:00Z",
      "lastModified": "2025-11-06T14:30:00Z",
      "hasFrontmatter": true
    }
  ]
}
```

**User-Editable Fields:**
- `tags` - Per-page tags for organization

**Auto-Generated Fields:**
- `title` - First line or filename
- `preview` - First 200 characters
- `wordCount` - Total words in file
- `hasFrontmatter` - Whether page has YAML frontmatter

### 3. Page Level: Frontmatter

Located at: Top of each `.md` file

```markdown
---
title: 2025 NOV 06 Diamond Notes Vault Project Summary
tags: [project, summary, ios]
created: 2025-11-06T10:30:00Z
modified: 2025-11-06T14:30:00Z
---

# 2025 NOV 06 Diamond Notes Vault Project Summary

Content starts here...
```

## Components

### Models (`LibraryIndex.swift`)

- `LibraryIndex` - Root library structure
- `NotebookMetadata` - Individual notebook info
- `NotebookTOC` - Notebook table of contents
- `PageMetadata` - Individual page info
- `PageFrontmatter` - YAML frontmatter parser

### Manager (`IndexManager.swift`)

Key methods:

```swift
// Library operations
loadLibraryIndex(libraryURL:) -> LibraryIndex
saveLibraryIndex(_:to:)
rebuildLibraryIndex(libraryURL:)

// Notebook operations
loadNotebookTOC(notebookURL:) -> NotebookTOC
saveNotebookTOC(_:to:)
rebuildNotebookTOC(notebookURL:)

// User edits
updateNotebookMetadata(libraryURL:notebookID:displayName:description:tags:icon:color:)
updatePageMetadata(notebookURL:pageID:tags:)
```

### Views

**NotebookPickerView**
- Shows rich notebook cards with icons, colors, descriptions, tags
- Tap to switch notebooks
- Tap info button to edit metadata
- Refresh button rebuilds index from filesystem

**NotebookMetadataEditor**
- Edit display name, description, tags
- Choose from emoji icons
- Select color theme
- View statistics (note count, dates)

**PageMetadataEditor**
- Edit page tags
- View title, preview, word count, dates
- Check if frontmatter exists

## Usage Flow

### Initial Setup (First Launch)

1. User completes onboarding, selects library folder (e.g., OnionBlog)
2. User selects notebook subfolder (e.g., Claude-Sessions)
3. App calls `IndexManager.rebuildLibraryIndex(OnionBlog)`
   - Creates `OnionBlog/index.json` with default metadata
   - Scans all subfolders, creates NotebookMetadata entries

### Creating/Editing Notes

1. User creates new note in current notebook
2. Note saved to filesystem
3. App calls `IndexManager.rebuildNotebookTOC(Claude-Sessions)`
   - Updates `Claude-Sessions/toc.json` with new PageMetadata
   - Increments noteCount in library index

### Switching Notebooks

1. User taps folder icon in editor toolbar
2. NotebookPickerView appears showing all notebooks with rich metadata
3. User taps a notebook → switches active notebook for new notes
4. OR user taps info icon → NotebookMetadataEditor appears

### Editing Metadata

**Notebook Metadata:**
1. Open NotebookPickerView
2. Tap info icon on any notebook
3. Edit display name, description, tags, icon, color
4. Save → updates `index.json`

**Page Metadata:**
1. Open note list view (future)
2. Long-press or swipe on note
3. Select "Edit Info"
4. Edit tags
5. Save → updates `toc.json` and optionally frontmatter

## Benefits

1. **Rich Presentation** - Icons, colors, descriptions make notebooks visually distinct
2. **User Control** - Editable metadata for personalization
3. **Fast Search** - Pre-indexed tags, titles, previews
4. **Persistence** - Metadata survives filesystem changes
5. **Extensibility** - Easy to add new fields (priority, starred, archived, etc.)
6. **Interoperability** - JSON readable by other tools
7. **Smart Sorting** - Sort by note count, last modified, custom order
8. **Statistics** - Track usage patterns, growth over time

## Future Enhancements

- [ ] Search notebooks by tags/description
- [ ] Filter pages by tags
- [ ] Custom notebook ordering (drag to reorder)
- [ ] Starred/pinned notebooks
- [ ] Archive notebooks (hide from picker)
- [ ] Export TOC as Markdown or HTML
- [ ] Import/export notebook metadata
- [ ] Sync TOC across devices (iCloud)
- [ ] Smart collections (virtual notebooks based on tags)
- [ ] Note linking graph visualization

## Terminology

**Library** = Parent folder (OnionBlog)
- Contains the `index.json` master index
- Contains multiple notebook binder subfolders
- Root level of your knowledge base

**Notebook Binder** = Subfolder (Claude-Sessions, Personal, Support)
- Contains `toc.json` table of contents
- Contains page files (.md)
- Has a `media/` pocket folder for assets used in pages
- Think of it like a physical 3-ring binder holding pages

**Page** = Individual markdown file (2025-NOV-07-Note.md)
- The actual note content (like a page in a binder)
- Can have frontmatter metadata
- Can embed images/videos from the binder's media pocket folder

**Media Pocket Folder** = Assets folder (media/)
- Located inside each notebook binder
- Holds images and videos used within pages
- Like a pocket in the front of a physical binder
- Keeps assets organized with their related notes

## File Locations

```
OnionBlog/                                    # Library (parent folder)
├── index.json                                # Library index (all notebook binders)
├── Claude-Sessions/                          # Notebook Binder (subfolder)
│   ├── toc.json                             # Binder TOC (all pages)
│   ├── media/                               # Media pocket folder
│   │   ├── screenshot-2025-11-06.png
│   │   └── demo-video.mp4
│   ├── 2025-NOV-06-Note-1.md                # Page (note)
│   └── 2025-NOV-07-Note-2.md                # Page (note)
├── Personal/                                 # Notebook Binder
│   ├── toc.json
│   ├── media/                               # Each binder has own media pocket folder
│   │   └── photo.jpg
│   └── 2025-NOV-05-Journal.md
└── Support/                                  # Notebook Binder
    ├── toc.json
    ├── media/
    └── support-notes.md
```

## Notes

- Index files are auto-created on first access
- Rebuild operations preserve user-edited fields
- Files are atomic writes (no corruption on crash)
- ISO8601 date format for cross-platform compatibility
- Pretty-printed JSON for human readability
