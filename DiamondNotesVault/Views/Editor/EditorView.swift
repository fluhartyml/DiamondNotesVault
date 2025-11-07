//
//  EditorView.swift
//  DiamondNotesVault
//
//  Main note editor view (Apple Notes style)
//

import SwiftUI
import UIKit
import PhotosUI
import VisionKit

struct EditorView: View {
    @State private var title: String = ""
    @State private var attributedContent: NSAttributedString
    @State private var currentFormatting = TextFormatting(isBold: false, isItalic: false, isUnderlined: false)
    @State private var shouldFocusBody = false

    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var showDocumentScanner = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var showTextFormatMenu = false
    @State private var showAttachmentMenu = false
    @State private var isDoneButtonTapped = false
    @State private var showNotebookPicker = false

    @State private var permissionManager = PermissionManager()
    @State private var appState = AppState.shared

    @FocusState private var titleFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var onSave: (String, NSAttributedString) -> Void
    var onDelete: () -> Void
    var onDone: ((String, NSAttributedString) -> Void)?

    init(
        title: String = "",
        content: String = "",
        attributedContent: NSAttributedString? = nil,
        onSave: @escaping (String, NSAttributedString) -> Void,
        onDelete: @escaping () -> Void,
        onDone: ((String, NSAttributedString) -> Void)? = nil
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
        self.onDone = onDone
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title field
            TextField("", text: $title, prompt: Text("Title"))
                .font(.title2.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .focused($titleFocused)
                .submitLabel(.done)
                .onSubmit {
                    print("DEBUG: Title field onSubmit triggered")
                    // When user presses return, move focus to body editor
                    titleFocused = false
                    shouldFocusBody = true
                    print("DEBUG: Set shouldFocusBody = true")
                }

            Divider()

            // Rich text editor with toolbar as inputAccessoryView
            RichTextEditor(
                attributedText: $attributedContent,
                shouldBecomeFirstResponder: $shouldFocusBody,
                onFormatChange: { formatting in
                    currentFormatting = formatting
                },
                onBold: { applyFormatting(.bold) },
                onItalic: { applyFormatting(.italic) },
                onUnderline: { applyFormatting(.underline) },
                onTextFormat: { handleTextFormatTap() },
                onAttachment: { handleAttachmentTap() }
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showNotebookPicker = true
                } label: {
                    Label(appState.libraryName ?? "Notebook Binder", systemImage: "folder")
                        .font(.subheadline)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    // Prevent multiple rapid-fire calls
                    guard !isDoneButtonTapped else {
                        print("DEBUG: Done button already processing, ignoring")
                        return
                    }
                    isDoneButtonTapped = true

                    print("DEBUG: Done button action triggered")
                    print("DEBUG: Title = '\(title)'")
                    print("DEBUG: Content length = \(attributedContent.length)")

                    // Hide keyboard
                    titleFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                    // Finalize the note
                    if let onDone = onDone {
                        print("DEBUG: onDone callback exists, calling it now")
                        onDone(title, attributedContent)
                        print("DEBUG: onDone callback completed")
                    } else {
                        print("DEBUG: ERROR - onDone callback is nil!")
                    }

                    // Reset flag after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isDoneButtonTapped = false
                    }
                }
            }
        }
        .onAppear {
            // Auto-focus title field for new notes
            if !title.isEmpty && title.hasSuffix(" ") {
                titleFocused = true
            }
        }
        .onChange(of: title) { _, _ in
            // Auto-save draft as user types (for persistence across app launches)
            autoSaveDraft()
        }
        .onChange(of: attributedContent) { _, _ in
            // Auto-save draft as user types
            autoSaveDraft()
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
        .sheet(isPresented: $showDocumentScanner) {
            DocumentScannerView { image in
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
        .confirmationDialog("Text Format", isPresented: $showTextFormatMenu) {
            Button("Title") { applyTextStyle(.title) }
            Button("Heading") { applyTextStyle(.heading) }
            Button("Body") { applyTextStyle(.body) }
            Button("Caption") { applyTextStyle(.caption) }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog("Add Attachment", isPresented: $showAttachmentMenu) {
            Button("Photo Library") { handlePhotoButtonTap() }
            Button("Take Photo") { handleCameraButtonTap() }
            Button("Scan Document") { showDocumentScanner = true }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showNotebookPicker) {
            NotebookPickerView(appState: appState)
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

    private func applyTextStyle(_ style: TextStyle) {
        let mutableText = NSMutableAttributedString(attributedString: attributedContent)
        let range = NSRange(location: 0, length: mutableText.length)

        // Apply the font style to entire content
        mutableText.addAttribute(.font, value: style.font, range: range)

        attributedContent = mutableText
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

    private func handleTextFormatTap() {
        showTextFormatMenu = true
    }

    private func handleAttachmentTap() {
        showAttachmentMenu = true
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

        // Create properly formatted newlines with body font
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont]

        // Insert at end with newlines
        mutableText.append(NSAttributedString(string: "\n", attributes: bodyAttributes))
        mutableText.append(attachmentString)
        mutableText.append(NSAttributedString(string: "\n", attributes: bodyAttributes))

        attributedContent = mutableText
    }

    private func autoSaveDraft() {
        // Auto-save current state as draft (doesn't finalize the note)
        let contentText = attributedContent.string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Only save if there's actual content
        if !title.isEmpty || !contentText.isEmpty {
            onSave(title, attributedContent)
        }
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

enum TextStyle {
    case title, heading, body, caption

    var font: UIFont {
        switch self {
        case .title:
            return .preferredFont(forTextStyle: .title1)
        case .heading:
            return .preferredFont(forTextStyle: .title2)
        case .body:
            return .preferredFont(forTextStyle: .body)
        case .caption:
            return .preferredFont(forTextStyle: .caption1)
        }
    }
}

// MARK: - Document Scanner

struct DocumentScannerView: UIViewControllerRepresentable {
    let onScan: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Get the first scanned page
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                parent.onScan(image)
            }
            parent.dismiss()
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Document scanning failed: \(error)")
            parent.dismiss()
        }
    }
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
