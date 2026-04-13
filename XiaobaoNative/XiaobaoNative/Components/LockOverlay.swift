import SwiftUI

struct LockOverlay: View {
    let onUnlock: () -> Void
    @State private var tapCount = 0
    @State private var lastTapTime: Date?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Button(action: {
                    handleTap()
                }) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                }

                VStack(spacing: 10) {
                    Text("今日学习已结束")
                        .font(.title)
                        .foregroundColor(.white)

                    Text("不能再看了")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    Text("点击锁图标5次进入家长管理")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    private func handleTap() {
        let now = Date()

        if let lastTime = lastTapTime {
            if now.timeIntervalSince(lastTime) > 1 {
                tapCount = 0
            }
        }

        tapCount += 1
        lastTapTime = now

        if tapCount >= 5 {
            onUnlock()
            tapCount = 0
        }
    }
}
