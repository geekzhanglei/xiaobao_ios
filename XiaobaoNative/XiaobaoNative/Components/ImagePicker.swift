import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    let onImagesPicked: ([URL]) -> Void

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
        let onImagesPicked: ([URL]) -> Void

        init(onImagesPicked: @escaping ([URL]) -> Void) {
            self.onImagesPicked = onImagesPicked
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard !results.isEmpty else {
                self.onImagesPicked([])
                return
            }

            var pickedURLs: [URL] = []
            let group = DispatchGroup()

            for result in results {
                group.enter()
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                    defer { group.leave() }
                    
                    if let url = url {
                        do {
                            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let destination = documentsPath.appendingPathComponent(UUID().uuidString + ".jpg")
                            try FileManager.default.copyItem(at: url, to: destination)
                            pickedURLs.append(destination)
                        } catch {
                            print("Error copying picked image: \(error)")
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.onImagesPicked(pickedURLs)
            }
        }
    }
}
