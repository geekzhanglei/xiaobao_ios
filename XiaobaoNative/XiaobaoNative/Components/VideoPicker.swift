import SwiftUI
import PhotosUI

struct VideoPicker: UIViewControllerRepresentable {
    let onVideosPicked: ([URL]) -> Void

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
        let onVideosPicked: ([URL]) -> Void

        init(onVideosPicked: @escaping ([URL]) -> Void) {
            self.onVideosPicked = onVideosPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else {
                self.onVideosPicked([])
                return
            }

            var pickedURLs: [URL] = []
            let group = DispatchGroup()

            for result in results {
                group.enter()
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    defer { group.leave() }
                    
                    if let url = url {
                        do {
                            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let destination = documentsPath.appendingPathComponent(UUID().uuidString + ".mp4")
                            try FileManager.default.copyItem(at: url, to: destination)
                            pickedURLs.append(destination)
                        } catch {
                            print("Error copying picked video: \(error)")
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.onVideosPicked(pickedURLs)
            }
        }
    }
}
