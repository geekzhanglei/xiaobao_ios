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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}
