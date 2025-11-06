//
//  ContentView.swift
//  DiamondNotesVault
//
//  Temporary: Shows editor directly for testing
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            EditorView(
                title: "",
                content: "",
                onSave: { title, content in
                    print("Note saved - Title: \(title)")
                    print("Content: \(content.string)")
                },
                onDelete: {
                    print("Note deleted")
                }
            )
            .navigationTitle("New Note")
        }
    }
}

#Preview {
    ContentView()
}
