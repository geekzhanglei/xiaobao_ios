import SwiftUI

struct ParentGate: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void
    @State private var tapCount = 0
    @State private var lastTapTime: Date?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("家长验证")
                    .font(.title)
                    .foregroundColor(.white)
                
                Text("请在1秒内连续点击4次")
                    .foregroundColor(.white.opacity(0.8))
                
                Button("点击") {
                    handleTap()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("取消") {
                    onCancel()
                }
                .foregroundColor(.white)
            }
            .padding()
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
        
        if tapCount >= 4 {
            onSuccess()
            tapCount = 0
        }
    }
}
