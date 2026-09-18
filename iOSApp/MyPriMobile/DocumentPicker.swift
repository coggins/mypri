import SwiftUI
import UniformTypeIdentifiers

/// Wraps UIDocumentPickerViewController so the user can pick a file that
/// lives in any Files-integrated location — Google Drive, iCloud Drive,
/// Dropbox, On My iPhone, etc. — without this app needing any
/// provider-specific SDK or authentication.
struct DocumentPicker: UIViewControllerRepresentable {
    enum Mode {
        case open
        case exportNew(tempURL: URL)
    }

    var mode: Mode
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker: UIDocumentPickerViewController
        switch mode {
        case .open:
            // Filtering strictly by .json hides files from providers (Google
            // Drive included) that don't report that exact UTI. .data is a
            // near-universal ancestor type, so this shows any regular file
            // without also listing folders.
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: false)
        case .exportNew(let tempURL):
            picker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: false)
        }
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
