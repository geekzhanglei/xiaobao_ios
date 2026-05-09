import ImageIO
import SwiftUI

struct LocalImageView<Placeholder: View>: View {
    let url: URL?
    let targetSize: CGSize
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var loadID = UUID()

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .onAppear(perform: load)
        .onChange(of: url) { _ in
            image = nil
            load()
        }
    }

    private func load() {
        guard let url else { return }
        let currentLoadID = UUID()
        loadID = currentLoadID
        let pixelSize = max(targetSize.width, targetSize.height) * UIScreen.main.scale

        DispatchQueue.global(qos: .userInitiated).async {
            let loaded = Self.downsampleImage(at: url, maxPixelSize: max(1, pixelSize))
            DispatchQueue.main.async {
                guard loadID == currentLoadID else { return }
                image = loaded
            }
        }
    }

    nonisolated private static func downsampleImage(at url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else {
            return UIImage(contentsOfFile: url.path)
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize)
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return UIImage(contentsOfFile: url.path)
        }
        return UIImage(cgImage: cgImage)
    }
}
