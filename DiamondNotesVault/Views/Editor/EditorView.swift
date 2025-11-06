//
//  EditorView.swift
//  DiamondNotesVault
//
//  Main note editor view (Apple Notes style)
//

import SwiftUI
import UIKit

struct EditorView: View {
    @State private var title: String = ""
    @State private var attributedContent: NSAttributedString
    @State private var isEditing: Bool = true
    @State private var currentFormatting = TextFormatting(isBold: false, isItalic: false, isUnderlined: false)

    @FocusState private var titleFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var onSave: (String, NSAttributedString) -> Void
    var onDelete: () -> Void

    init(
        title: String = "",
        content: String = "",
        onSave: @escaping (String, NSAttributedString) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self._title = State(initialValue: title)

        let defaultFont = UIFont.preferredFont(forTextStyle: .body)
        let attrs: [NSAttributedString.Key: Any] = [.font: defaultFont]
        self._attributedContent = State(initialValue: NSAttributedString(string: content, attributes: attrs))

        self.onSave = onSave
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title field
            TextField("", text: $title, prompt: Text("Title"))
                .font(.title2.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .focused($titleFocused)

            Divider()

            // Rich text editor
            RichTextEditor(
                attributedText: $attributedContent,
                isFirstResponder: $isEditing,
                onFormatChange: { formatting in
                    currentFormatting = formatting
                }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                EditorToolbar(
                    onBold: { applyFormatting(.bold) },
                    onItalic: { applyFormatting(.italic) },
                    onUnderline: { applyFormatting(.underline) },
                    onBulletList: { /* TODO */ },
                    onNumberedList: { /* TODO */ },
                    onCheckbox: { /* TODO */ },
                    onPhoto: { /* TODO */ },
                    onCamera: { /* TODO */ }
                )
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    isEditing = false
                    dismiss()
                }
            }
        }
        .onDisappear {
            saveOrDelete()
        }
    }

    private func applyFormatting(_ style: FormattingStyle) {
        let mutableText = NSMutableAttributedString(attributedString: attributedContent)
        let range = NSRange(location: 0, length: mutableText.length)

        mutableText.enumerateAttribute(.font, in: range) { value, range, _ in
            guard let font = value as? UIFont else { return }

            var traits = font.fontDescriptor.symbolicTraits

            switch style {
            case .bold:
                if traits.contains(.traitBold) {
                    traits.remove(.traitBold)
                } else {
                    traits.insert(.traitBold)
                }
            case .italic:
                if traits.contains(.traitItalic) {
                    traits.remove(.traitItalic)
                } else {
                    traits.insert(.traitItalic)
                }
            case .underline:
                if mutableText.attributes(at: range.location, effectiveRange: nil)[.underlineStyle] != nil {
                    mutableText.removeAttribute(.underlineStyle, range: range)
                } else {
                    mutableText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                }
                return
            }

            if let newFontDescriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                let newFont = UIFont(descriptor: newFontDescriptor, size: font.pointSize)
                mutableText.addAttribute(.font, value: newFont, range: range)
            }
        }

        attributedContent = mutableText
    }

    private func saveOrDelete() {
        let contentText = attributedContent.string.trimmingCharacters(in: .whitespacesAndNewlines)

        if title.isEmpty && contentText.isEmpty {
            onDelete()
        } else {
            onSave(title, attributedContent)
        }
    }
}

enum FormattingStyle {
    case bold, italic, underline
}

#Preview {
    NavigationStack {
        EditorView(
            title: "Test Note",
            content: "This is sample content",
            onSave: { title, content in
                print("Saved: \(title)")
            },
            onDelete: {
                print("Deleted")
            }
        )
    }
}
