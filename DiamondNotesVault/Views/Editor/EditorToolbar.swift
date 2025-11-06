//
//  EditorToolbar.swift
//  DiamondNotesVault
//
//  Formatting toolbar for the editor (Apple Notes style)
//

import SwiftUI

struct EditorToolbar: View {
    var onBold: () -> Void
    var onItalic: () -> Void
    var onUnderline: () -> Void
    var onBulletList: () -> Void
    var onNumberedList: () -> Void
    var onCheckbox: () -> Void
    var onPhoto: () -> Void
    var onCamera: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Text formatting group
            Group {
                ToolbarButton(icon: "bold") { onBold() }
                ToolbarButton(icon: "italic") { onItalic() }
                ToolbarButton(icon: "underline") { onUnderline() }
            }

            Spacer()

            // List group
            Group {
                ToolbarButton(icon: "list.bullet") { onBulletList() }
                ToolbarButton(icon: "list.number") { onNumberedList() }
            }

            Spacer()

            // Checkbox
            ToolbarButton(icon: "checklist") { onCheckbox() }

            Spacer()

            // Media group
            Group {
                ToolbarButton(icon: "photo") { onPhoto() }
                ToolbarButton(icon: "camera") { onCamera() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct ToolbarButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
        }
    }
}
