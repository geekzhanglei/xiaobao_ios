import SwiftUI
import AVKit

struct PlayerView: View {
    let items: [ContentItem]
    let initialIndex: Int
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var playerViewController: AVPlayerViewController?
    @State private var startTime: Date?
    @State private var timer: Timer?
    @State private var scale: CGFloat = 1.0
    @State private var playerItemObserver: Any?
    @State private var currentIndex: Int = 0

    private var currentItem: ContentItem {
        items[currentIndex]
    }

    init(items: [ContentItem], initialIndex: Int = 0) {
        self.items = items
        self.initialIndex = initialIndex
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if currentItem.type == .video {
                if let playerViewController = playerViewController {
                    PlayerViewControllerRepresentable(playerViewController: playerViewController)
                        .onAppear {
                            startTime = Date()
                            startTimer()
                            player?.play() // Reinforce play on appear
                        }
                        .onDisappear {
                            stopTimer()
                        }
                        .overlay(
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .allowsHitTesting(true)
                            .zIndex(10)
                            , alignment: .topTrailing
                        )
                } else {
                    Text("加载中...")
                        .foregroundColor(.white)
                }
            } else {
                // Image viewer with swipe support
                TabView(selection: $currentIndex) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        ImageViewer(item: item, scale: $scale)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .onAppear {
                    startTime = Date()
                    startTimer()
                }
                .onDisappear {
                    stopTimer()
                }
                .overlay(
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    , alignment: .topTrailing
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Configure Audio Session once for the entire session
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Failed to set audio session category: \(error)")
            }

            currentIndex = initialIndex
            if currentItem.type == .video {
                setupVideoPlayer()
            }
        }
        .onChange(of: currentIndex) { newIndex in
            if currentItem.type == .video {
                stopTimer()
                setupVideoPlayer()
                startTime = Date()
                startTimer()
            }
        }
    }

    private func setupVideoPlayer() {
        player?.pause()
        player = nil
        playerViewController = nil

        if let url = URL(string: currentItem.uri) {
            player = AVPlayer(url: url)
            player?.automaticallyWaitsToMinimizeStalling = true
            playerViewController = AVPlayerViewController()
            playerViewController?.player = player
            playerViewController?.allowsPictureInPicturePlayback = false
            playerViewController?.showsPlaybackControls = true
            if #available(iOS 16.0, *) {
                playerViewController?.allowsDisplayingPlaybackRateControls = false
            }
            player?.play()

            // Observe playback completion
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem,
                queue: .main
            ) { _ in
                dismiss()
            }
        }
    }

    private func startTimer() {
        // Ensure any existing timer is invalidated before starting a new one
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            store.incrementUsedTime(seconds: 1)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        // Remove observer
        if let observer = playerItemObserver {
            NotificationCenter.default.removeObserver(observer)
            playerItemObserver = nil
        }
        player?.pause()
        player = nil
        playerViewController = nil
    }
}

struct ImageViewer: View {
    let item: ContentItem
    @Binding var scale: CGFloat

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            AsyncImage(url: URL(string: item.uri)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    self.scale = value
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        if scale < 1 {
                                            scale = 1
                                        }
                                    }
                                }
                        )
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
        }
    }
}

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let playerViewController: AVPlayerViewController

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        playerViewController.player?.play() // Reinforce playback when UI is ready
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Ensure the correct player is used
        if uiViewController.player != playerViewController.player {
            uiViewController.player = playerViewController.player
        }
    }
}
