import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct VideoPicker: UIViewControllerRepresentable {
    let onVideosPicked: ([PickedMediaFile]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 0 // 0 means no limit

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onVideosPicked: onVideosPicked)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onVideosPicked: ([PickedMediaFile]) -> Void

        init(onVideosPicked: @escaping ([PickedMediaFile]) -> Void) {
            self.onVideosPicked = onVideosPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else {
                self.onVideosPicked([])
                return
            }

            var pickedFiles: [PickedMediaFile] = []
            let group = DispatchGroup()
            let lock = NSLock()

            for result in results {
                group.enter()
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    defer { group.leave() }
                    
                    if let url = url {
                        do {
                            let contentID = UUID().uuidString
                            let suggestedName = result.itemProvider.suggestedName
                            let destination = try MediaStorage.storeImportedFile(
                                from: url,
                                kind: .video,
                                contentID: contentID,
                                preferredFilename: suggestedName
                            )
                            let title = suggestedName ?? "视频"
                            lock.lock()
                            pickedFiles.append(PickedMediaFile(id: contentID, url: destination, title: title))
                            lock.unlock()
                        } catch {
                            print("Error copying picked video: \(error)")
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.onVideosPicked(pickedFiles)
            }
        }
    }
}
