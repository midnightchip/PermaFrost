import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileUrl: String
    @Binding var fileTitle: String

    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        // Allow opening of files of type .ipa
        // let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .open)
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        controller.allowsMultipleSelection = false
        controller.shouldShowFileExtensions = true
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_: UIDocumentPickerViewController, context _: UIViewControllerRepresentableContext<DocumentPicker>) {}

    func makeCoordinator() -> DocumentPickerCoordinator {
        DocumentPickerCoordinator(fileUrl: $fileUrl, fileTitle: $fileTitle)
    }
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    @Binding var fileUrl: String
    @Binding var fileTitle: String

    init(fileUrl: Binding<String>, fileTitle: Binding<String>) {
        _fileUrl = fileUrl
        _fileTitle = fileTitle
    }

    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        // Check if the file is an ipa
        if url.pathExtension == "ipa" {
            fileUrl = url.path
            fileTitle = url.lastPathComponent
        }
    }
}
