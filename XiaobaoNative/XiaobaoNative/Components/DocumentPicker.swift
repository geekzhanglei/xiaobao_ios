import SwiftUI
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentsPicked: ([PickedMediaFile]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentsPicked: onDocumentsPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentsPicked: ([PickedMediaFile]) -> Void

        init(onDocumentsPicked: @escaping ([PickedMediaFile]) -> Void) {
            self.onDocumentsPicked = onDocumentsPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            DispatchQueue.global(qos: .userInitiated).async {
                var destinationFiles: [PickedMediaFile] = []

                for url in urls {
                    do {
                        let isSecurityScoped = url.startAccessingSecurityScopedResource()
                        defer {
                            if isSecurityScoped {
                                url.stopAccessingSecurityScopedResource()
                            }
                        }
                        let contentID = UUID().uuidString
                        let destination = try MediaStorage.storeImportedFile(
                            from: url,
                            kind: .video,
                            contentID: contentID,
                            preferredFilename: url.lastPathComponent
                        )
                        destinationFiles.append(PickedMediaFile(id: contentID, url: destination, title: url.lastPathComponent))
                    } catch {
                        print("Error copying picked document: \(error)")
                    }
                }

                DispatchQueue.main.async {
                    self.onDocumentsPicked(destinationFiles)
                }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            self.onDocumentsPicked([])
        }
    }
}
