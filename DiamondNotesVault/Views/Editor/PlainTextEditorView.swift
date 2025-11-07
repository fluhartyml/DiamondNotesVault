//
//  PlainTextEditorView.swift
//  DiamondNotesVault
//
//  Plain text editor view for JSON files
//

import SwiftUI

struct PlainTextEditorView: View {
    @State private var text: String
    @State private var isEditing: Bool = true
    @Environment(\.dismiss) private var dismiss

    var onSave: (String) -> Void
    var fileName: String

    init(
        text: String = "",
        fileName: String = "file.json",
        onSave: @escaping (String) -> Void
    ) {
        self._text = State(initialValue: text)
        self.fileName = fileName
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            PlainTextEditor(
                text: $text,
                isFirstResponder: $isEditing
            )
        }
        .navigationTitle(fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    onSave(text)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlainTextEditorView(
            text: "{\n  \"test\": \"value\"\n}",
            fileName: ".toc.json",
            onSave: { text in
                print("Saved: \(text)")
            }
        )
    }
}
