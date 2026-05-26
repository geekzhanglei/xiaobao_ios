import AVKit
import Combine
import SwiftUI

struct PlayerView: View {
    let items: [ContentItem]
    let initialIndex: Int

    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var videoController = VideoPlayerController()
    @StateObject private var usageTracker = UsageTimeTracker()
    @State private var scale: CGFloat = 1.0
    @State private var currentIndex: Int = 0

    private var currentItem: ContentItem? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    init(items: [ContentItem], initialIndex: Int = 0) {
        self.items = items
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: min(max(initialIndex, 0), max(items.count - 1, 0)))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let currentItem {
                if currentItem.type == .video {
                    videoBody(for: currentItem)
                } else {
                    imageBody
                }
            } else {
                Text("内容不存在")
                    .foregroundColor(.white)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            currentIndex = min(max(initialIndex, 0), max(items.count - 1, 0))
            configureCurrentItem()
            startTimer()
        }
        .onDisappear {
            stopTimer()
            videoController.stop()
        }
        .onChange(of: currentIndex) { _ in
            configureCurrentItem()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                AudioSessionManager.shared.activate()
                videoController.resumeIfNeeded()
            } else if phase == .background {
                videoController.pauseForBackground()
            }
        }
    }

    private func videoBody(for item: ContentItem) -> some View {
        ZStack {
            PlayerViewControllerRepresentable(player: videoController.player)
                .ignoresSafeArea()

            if videoController.isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
            }

            if let errorMessage = videoController.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                    Text(errorMessage)
                        .font(.body)
                        .multilineTextAlignment(.center)
                    Button("关闭") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .foregroundColor(.white)
                .padding(24)
                .background(Color.black.opacity(0.72))
                .cornerRadius(12)
                .padding()
            }

            closeButton
        }
        .onAppear {
            videoController.load(item: item) {
                dismiss()
            }
        }
    }

    private var imageBody: some View {
        TabView(selection: $currentIndex) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if item.type == .image {
                    ImageViewer(item: item, scale: $scale)
                        .tag(index)
                } else {
                    ZStack {
                        Color.black
                        Image(systemName: "video.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .tag(index)
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .overlay(closeButton, alignment: .topTrailing)
    }

    private var closeButton: some View {
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
    }

    private func configureCurrentItem() {
        guard let currentItem else { return }
        scale = 1.0
        if currentItem.type == .video {
            videoController.load(item: currentItem) {
                dismiss()
            }
        } else {
            videoController.stop()
        }
    }

    private func startTimer() {
        usageTracker.start { seconds in
            store.incrementUsedTime(seconds: seconds)
        }
    }

    private func stopTimer() {
        usageTracker.stop { seconds in
            store.incrementUsedTime(seconds: seconds)
        }
    }
}

@MainActor
final class UsageTimeTracker: ObservableObject {
    private let flushInterval = 10
    private var timer: Timer?
    private var pendingSeconds = 0

    func start(onFlush: @escaping (Int) -> Void) {
        stop(onFlush: onFlush)

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.pendingSeconds += 1
                if self.pendingSeconds >= self.flushInterval {
                    self.flush(onFlush: onFlush)
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop(onFlush: (Int) -> Void) {
        timer?.invalidate()
        timer = nil
        flush(onFlush: onFlush)
    }

    private func flush(onFlush: (Int) -> Void) {
        guard pendingSeconds > 0 else { return }
        let seconds = pendingSeconds
        pendingSeconds = 0
        onFlush(seconds)
    }
}

final class VideoPlayerController: ObservableObject {
    let player = AVPlayer()

    @Published var isLoading = false
    @Published var errorMessage: String?

    private var currentItemID: String?
    private var shouldResumeAfterBackground = false
    private var statusObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var failedObserver: NSObjectProtocol?
    private var stalledObserver: NSObjectProtocol?
    private var finishHandler: (() -> Void)?

    func load(item: ContentItem, onFinish: @escaping () -> Void) {
        guard currentItemID != item.id else { return }
        guard let url = item.validFileURL else {
            stop()
            errorMessage = "视频文件路径无效"
            isLoading = false
            return
        }

        currentItemID = item.id
        finishHandler = onFinish
        errorMessage = nil
        isLoading = true
        removeObservers()

        AudioSessionManager.shared.configureForPlayback { [weak self] in
            self?.resumeIfNeeded()
        }

        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: true]
        )
        let playerItem = AVPlayerItem(asset: asset)
        statusObservation = playerItem.observe(\.status, options: [.initial, .new]) { [weak self] observedItem, _ in
            DispatchQueue.main.async {
                self?.handleStatusChange(observedItem)
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.finishHandler?()
        }

        failedObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            self?.showPlaybackError(error)
        }

        stalledObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player.play()
        }

        player.automaticallyWaitsToMinimizeStalling = true
        player.replaceCurrentItem(with: playerItem)
    }

    func stop() {
        shouldResumeAfterBackground = false
        currentItemID = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        removeObservers()
        isLoading = false
    }

    func pauseForBackground() {
        shouldResumeAfterBackground = player.timeControlStatus == .playing
        player.pause()
    }

    func resumeIfNeeded() {
        guard player.currentItem != nil else { return }
        AudioSessionManager.shared.activate()
        if shouldResumeAfterBackground || player.timeControlStatus != .playing {
            shouldResumeAfterBackground = false
            player.play()
        }
    }

    deinit {
        stop()
    }

    private func handleStatusChange(_ item: AVPlayerItem) {
        switch item.status {
        case .readyToPlay:
            isLoading = false
            AudioSessionManager.shared.activate()
            player.play()
        case .failed:
            showPlaybackError(item.error)
        case .unknown:
            isLoading = true
        @unknown default:
            showPlaybackError(nil)
        }
    }

    private func showPlaybackError(_ error: Error?) {
        isLoading = false
        errorMessage = error?.localizedDescription ?? "视频无法播放，请重新导入该文件"
    }

    private func removeObservers() {
        statusObservation?.invalidate()
        statusObservation = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let failedObserver {
            NotificationCenter.default.removeObserver(failedObserver)
            self.failedObserver = nil
        }
        if let stalledObserver {
            NotificationCenter.default.removeObserver(stalledObserver)
            self.stalledObserver = nil
        }
    }
}

struct ImageViewer: View {
    let item: ContentItem
    @Binding var scale: CGFloat

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            LocalImageView(
                url: item.validFileURL,
                targetSize: UIScreen.main.bounds.size,
                contentMode: .fit
            ) {
                ProgressView()
                    .tint(.white)
            }
            .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
                    .onEnded { _ in
                        withAnimation {
                            if scale < 1 {
                                scale = 1
                            }
                        }
                    }
            )
        }
        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height)
    }
}

struct PlayerViewControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = false
        controller.showsPlaybackControls = true
        if #available(iOS 16.0, *) {
            controller.speeds = []
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player !== player {
            uiViewController.player = player
        }
    }
}
