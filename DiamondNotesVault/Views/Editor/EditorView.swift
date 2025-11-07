//
//  EditorView.swift
//  DiamondNotesVault
//
//  Main note editor view (Apple Notes style)
//

import SwiftUI
import UIKit
import PhotosUI

struct EditorView: View {
    @State private var title: String = ""
    @State private var attributedContent: NSAttributedString
    @State private var isEditing: Bool = true
    @State private var currentFormatting = TextFormatting(isBold: false, isItalic: false, isUnderlined: false)

    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""

    @State private var permissionManager = PermissionManager()

    @FocusState private var titleFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var onSave: (String, NSAttributedString) -> Void
    var onDelete: () -> Void

    init(
        title: String = "",
        content: String = "",
        attributedContent: NSAttributedString? = nil,
        onSave: @escaping (String, NSAttributedString) -> Void,
        onDelete: @escaping () -> Void
    ) {
        // Auto-populate title with date if empty (new note)
        if title.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy MMM dd "
            formatter.locale = Locale(identifier: "en_US_POSIX") // Ensures MMM is always English 3-letter abbreviation
            let dateString = formatter.string(from: Date()).uppercased() // Convert to uppercase for YYYY MMM DD format
            self._title = State(initialValue: dateString)
        } else {
            self._title = State(initialValue: title)
        }

        // Use provided attributed content or create from plain string
        if let attributed = attributedContent, attributed.length > 0 {
            self._attributedContent = State(initialValue: attributed)
        } else {
            let defaultFont = UIFont.preferredFont(forTextStyle: .body)
            let attrs: [NSAttributedString.Key: Any] = [.font: defaultFont]
            self._attributedContent = State(initialValue: NSAttributedString(string: content, attributes: attrs))
        }

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

            // Rich text editor with toolbar as inputAccessoryView
            RichTextEditor(
                attributedText: $attributedContent,
                isFirstResponder: $isEditing,
                onFormatChange: { formatting in
                    currentFormatting = formatting
                },
                toolbarView: createToolbarView()
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    isEditing = false
                    dismiss()
                }
            }
        }
        .onAppear {
            // Auto-focus title field for new notes
            if !title.isEmpty && title.hasSuffix(" ") {
                titleFocused = true
            }
        }
        .onDisappear {
            saveOrDelete()
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedPhotos,
            maxSelectionCount: 10,
            matching: .images
        )
        .sheet(isPresented: $showCamera) {
            CameraView { image in
                insertImage(image)
            }
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
        } message: {
            Text(permissionAlertMessage)
        }
        .onChange(of: selectedPhotos) { _, newPhotos in
            Task {
                for item in newPhotos {
                    // Extract metadata first (iOS 16+)
                    var metadata: PhotoMetadata?
                    if #available(iOS 16.0, *) {
                        metadata = await PhotoMetadataExtractor.extractMetadata(from: item)
                    }

                    // Load image
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        insertImage(image, metadata: metadata)
                    }
                }
                selectedPhotos = []
            }
        }
    }

    private func createToolbarView() -> UIView {
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

        // Create toolbar buttons
        let buttons: [(String, () -> Void)] = [
            ("bold", { self.applyFormatting(.bold) }),
            ("italic", { self.applyFormatting(.italic) }),
            ("underline", { self.applyFormatting(.underline) }),
            ("list.bullet", { /* TODO */ }),
            ("list.number", { /* TODO */ }),
            ("checklist", { /* TODO */ }),
            ("photo", { self.handlePhotoButtonTap() }),
            ("camera", { self.handleCameraButtonTap() })
        ]

        for (icon, action) in buttons {
            let button = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 20)
            button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
            button.tintColor = .label
            button.addAction(UIAction { _ in action() }, for: .touchUpInside)
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

    private func handlePhotoButtonTap() {
        Task {
            let hasPermission = await permissionManager.requestPhotoLibraryAccess()
            if hasPermission {
                showPhotoPicker = true
            } else {
                permissionAlertMessage = "Diamond Notes Vault needs access to your photo library to add photos to your notes. Please enable photo library access in Settings."
                showPermissionAlert = true
            }
        }
    }

    private func handleCameraButtonTap() {
        Task {
            let hasPermission = await permissionManager.requestCameraAccess()
            if hasPermission {
                showCamera = true
            } else {
                permissionAlertMessage = "Diamond Notes Vault needs access to your camera to take photos for your notes. Please enable camera access in Settings."
                showPermissionAlert = true
            }
        }
    }

    private func insertImage(_ image: UIImage, metadata: PhotoMetadata? = nil) {
        // Create text attachment with image
        let attachment = NSTextAttachment()
        attachment.image = image

        // Store metadata in attachment for later retrieval
        if let metadata = metadata {
            // Store as JSON in attachment's fileType (we'll use this when saving)
            attachment.fileType = metadata.originalFilename
        }

        // Scale image to fit within editor width (assuming ~350pt width for iPad)
        let maxWidth: CGFloat = 350
        if image.size.width > maxWidth {
            let scale = maxWidth / image.size.width
            attachment.bounds = CGRect(x: 0, y: 0, width: maxWidth, height: image.size.height * scale)
        } else {
            attachment.bounds = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        }

        // Create attributed string with attachment
        let attachmentString = NSAttributedString(attachment: attachment)
        let mutableText = NSMutableAttributedString(attributedString: attributedContent)

        // Insert at end with newlines
        mutableText.append(NSAttributedString(string: "\n"))
        mutableText.append(attachmentString)
        mutableText.append(NSAttributedString(string: "\n"))

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
