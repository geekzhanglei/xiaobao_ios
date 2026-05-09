import SwiftUI

struct ContentCard: View {
    let item: ContentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                let coverURL = item.validCoverFileURL ?? (item.type == .image ? item.validFileURL : nil)
                if let coverURL = coverURL {
                    LocalImageView(url: coverURL, targetSize: CGSize(width: 150, height: 120), contentMode: .fill) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
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
            .clipped() // Ensure content doesn't bleed out
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5) // More visible inner border
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(8)
        .frame(width: 150) // Enforce width to prevent expansion
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08)) // Slightly brighter background
                .blur(radius: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) // More visible outer border
        )
        .clipped() // Ensure no inner elements bleed out horizontally
    }
}
