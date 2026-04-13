import SwiftUI

struct ContentCard: View {
    let item: ContentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                let coverURL = item.cover ?? (item.type == .image ? item.uri : nil)
                if let coverURL = coverURL {
                    AsyncImage(url: URL(string: coverURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }

                if item.type == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 120)
            .cornerRadius(12)

            if let title = item.title {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
    }
}
