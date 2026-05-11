import AVFoundation
import Combine
import Foundation

final class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()

    private let session = AVAudioSession.sharedInstance()
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private var resumeHandler: (() -> Void)?

    private init() {
        observeAudioNotifications()
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        if let routeChangeObserver {
            NotificationCenter.default.removeObserver(routeChangeObserver)
        }
    }

    func configureForPlayback(resumeHandler: (() -> Void)? = nil) {
        self.resumeHandler = resumeHandler

        do {
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            try session.setActive(true)
        } catch {
            print("AudioSessionManager: failed to configure playback session: \(error)")
        }
    }

    func activate() {
        do {
            try session.setActive(true)
        } catch {
            print("AudioSessionManager: failed to activate session: \(error)")
        }
    }

    private func observeAudioNotifications() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }

        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            self?.activate()
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: rawType)
        else {
            return
        }

        switch type {
        case .began:
            break
        case .ended:
            activate()
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            if options.contains(.shouldResume) {
                resumeHandler?()
            }
        @unknown default:
            activate()
        }
    }
}
