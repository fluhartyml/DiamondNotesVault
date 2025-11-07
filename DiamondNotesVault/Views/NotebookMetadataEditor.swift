//
//  NotebookMetadataEditor.swift
//  DiamondNotesVault
//
//  UX for editing notebook binder metadata (display name, description, tags, icon, color)
//

import SwiftUI

struct NotebookMetadataEditor: View {
    @Binding var notebook: NotebookMetadata
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String
    @State private var description: String
    @State private var tagsText: String  // Comma-separated tags
    @State private var selectedIcon: String
    @State private var selectedColor: String

    private let iconOptions = ["📓", "📔", "📕", "📗", "📘", "📙", "🗂️", "📁", "📂", "🎯", "💼", "🎨", "⚡️", "🔬", "💡"]
    private let colorOptions = ["blue", "green", "orange", "red", "purple", "pink", "yellow", "gray"]

    init(notebook: Binding<NotebookMetadata>) {
        self._notebook = notebook
        self._displayName = State(initialValue: notebook.wrappedValue.displayName)
        self._description = State(initialValue: notebook.wrappedValue.description)
        self._tagsText = State(initialValue: notebook.wrappedValue.tags.joined(separator: ", "))
        self._selectedIcon = State(initialValue: notebook.wrappedValue.icon ?? "📓")
        self._selectedColor = State(initialValue: notebook.wrappedValue.color ?? "blue")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Display Name") {
                    TextField("Notebook Binder Name", text: $displayName)
                }

                Section("Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                Section("Library Sections") {
                    TextField("Comma-separated sections", text: $tagsText)
                        .autocapitalization(.words)
                    Text("First tag = shelf section (e.g., Fiction, Non-Fiction, Reference)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Additional tags for sub-categories (e.g., Romance, Biography)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Text(icon)
                                    .font(.system(size: 30))
                                    .frame(width: 44, height: 44)
                                    .background(
                                        selectedIcon == icon
                                            ? Color.blue.opacity(0.2)
                                            : Color.clear
                                    )
                                    .cornerRadius(8)
                            }
                        }
                    }
                }

                Section("Color") {
                    HStack(spacing: 16) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(colorForName(color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        selectedColor == color
                                            ? Circle().strokeBorder(Color.primary, lineWidth: 3)
                                            : nil
                                    )
                            }
                        }
                    }
                }

                Section("Statistics") {
                    LabeledContent("Note Count", value: "\(notebook.noteCount)")
                    LabeledContent("Created", value: notebook.createdDate.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Modified", value: notebook.lastModified.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .navigationTitle("Edit Notebook Binder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        notebook.displayName = displayName
        notebook.description = description
        notebook.tags = tagsText.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        notebook.icon = selectedIcon
        notebook.color = selectedColor
        notebook.lastModified = Date()
    }

    private func colorForName(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .blue
        }
    }
}

#Preview {
    NotebookMetadataEditor(notebook: .constant(NotebookMetadata(
        id: "Claude-Sessions",
        displayName: "🤖 Claude Sessions",
        description: "Technical conversations and development logs",
        tags: ["tech", "ai", "development"],
        icon: "🤖",
        color: "blue",
        noteCount: 42,
        lastModified: Date(),
        createdDate: Date()
    )))
}
