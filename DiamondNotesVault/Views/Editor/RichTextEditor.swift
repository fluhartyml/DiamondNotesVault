//
//  RichTextEditor.swift
//  DiamondNotesVault
//
//  UITextView wrapper for rich text editing (Apple Notes style)
//

import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var isFirstResponder: Bool

    var placeholder: String = "Start writing..."
    var onFormatChange: ((TextFormatting) -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.allowsEditingTextAttributes = true
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .sentences
        textView.spellCheckingType = .yes
        textView.keyboardType = .default
        textView.textColor = .label
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attributedText
            uiView.selectedRange = selectedRange
        }

        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Notify about current formatting at cursor
            if let formatting = currentFormatting(in: textView) {
                parent.onFormatChange?(formatting)
            }
        }

        private func currentFormatting(in textView: UITextView) -> TextFormatting? {
            guard textView.selectedRange.location < textView.textStorage.length else {
                return nil
            }

            let attributes = textView.textStorage.attributes(
                at: textView.selectedRange.location,
                effectiveRange: nil
            )

            let isBold = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false
            let isItalic = (attributes[.font] as? UIFont)?.fontDescriptor.symbolicTraits.contains(.traitItalic) ?? false
            let isUnderlined = attributes[.underlineStyle] != nil

            return TextFormatting(isBold: isBold, isItalic: isItalic, isUnderlined: isUnderlined)
        }
    }
}

struct TextFormatting {
    var isBold: Bool
    var isItalic: Bool
    var isUnderlined: Bool
}
