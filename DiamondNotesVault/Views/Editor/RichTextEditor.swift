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
    @Binding var shouldBecomeFirstResponder: Bool

    var placeholder: String = "Start writing..."
    var onFormatChange: ((TextFormatting) -> Void)?
    var onBold: (() -> Void)?
    var onItalic: (() -> Void)?
    var onUnderline: (() -> Void)?
    var onTextFormat: (() -> Void)?  // Aa button
    var onAttachment: (() -> Void)?  // Paperclip menu (photo/camera/scan)

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

        // Create and attach toolbar (only for THIS text view)
        textView.inputAccessoryView = createToolbar(for: context.coordinator)

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attributedText
            uiView.selectedRange = selectedRange
        }

        // Handle programmatic focus request
        if shouldBecomeFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
            DispatchQueue.main.async {
                shouldBecomeFirstResponder = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func createToolbar(for coordinator: Coordinator) -> UIView {
        // Create toolbar container
        let toolbarView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60))
        toolbarView.backgroundColor = .systemBackground
        toolbarView.autoresizingMask = [.flexibleWidth]

        // Add top border
        let border = UIView(frame: CGRect(x: 0, y: 0, width: toolbarView.frame.width, height: 0.5))
        border.backgroundColor = .separator
        border.autoresizingMask = [.flexibleWidth]
        toolbarView.addSubview(border)

        // Create button stack
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Create toolbar buttons with actions
        let buttons: [(String, (() -> Void)?)] = [
            ("textformat", onTextFormat),  // Aa button
            ("bold", onBold),
            ("italic", onItalic),
            ("underline", onUnderline),
            ("list.bullet", nil), // TODO
            ("list.number", nil), // TODO
            ("checklist", nil), // TODO
            ("paperclip", onAttachment)  // Unified attachment menu
        ]

        for (icon, action) in buttons {
            let button = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 20)
            button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
            button.tintColor = .label

            if let action = action {
                button.addAction(UIAction { _ in action() }, for: .touchUpInside)
            } else {
                button.isEnabled = false
                button.tintColor = .systemGray
            }

            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 44),
                button.heightAnchor.constraint(equalToConstant: 44)
            ])
            stackView.addArrangedSubview(button)
        }

        toolbarView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: toolbarView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: toolbarView.trailingAnchor, constant: -16),
            stackView.centerYAnchor.constraint(equalTo: toolbarView.centerYAnchor)
        ])

        return toolbarView
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // When user presses return, reset to body text style
            if text == "\n" {
                // Set typing attributes to body font for next line
                let bodyFont = UIFont.preferredFont(forTextStyle: .body)
                textView.typingAttributes = [.font: bodyFont]
            }
            return true
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
