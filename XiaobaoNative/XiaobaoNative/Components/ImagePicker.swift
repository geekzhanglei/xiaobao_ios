import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ImagePicker: UIViewControllerRepresentable {
    let onImagesPicked: ([PickedMediaFile]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0 // 0 means no limit

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagesPicked: onImagesPicked)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImagesPicked: ([PickedMediaFile]) -> Void

        init(onImagesPicked: @escaping ([PickedMediaFile]) -> Void) {
            self.onImagesPicked = onImagesPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else {
                self.onImagesPicked([])
                return
            }

            var pickedFiles: [PickedMediaFile] = []
            let group = DispatchGroup()
            let lock = NSLock()

            for result in results {
                group.enter()
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                    defer { group.leave() }
                    
                    if let url = url {
                        do {
                            let contentID = UUID().uuidString
                            let suggestedName = result.itemProvider.suggestedName
                            let destination = try MediaStorage.storeImportedFile(
                                from: url,
                                kind: .image,
                                contentID: contentID,
                                preferredFilename: suggestedName
                            )
                            let title = suggestedName ?? "图片"
                            lock.lock()
                            pickedFiles.append(PickedMediaFile(id: contentID, url: destination, title: title))
                            lock.unlock()
                        } catch {
                            print("Error copying picked image: \(error)")
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.onImagesPicked(pickedFiles)
            }
        }
    }
}
