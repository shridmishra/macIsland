import Foundation
import AppKit

// MARK: - MediaRemote Implementation of NowPlayingProvider
// Listens to system-wide media events and converts raw dictionary metadata into MediaItem models.
// Uses MediaRemoteCLIHelper to retrieve system metadata across all audio sources on modern macOS.
public final class MediaRemoteProvider: NowPlayingProvider, @unchecked Sendable {
    public var onMediaChange: (@Sendable (MediaItem?) -> Void)?
    
    private let bridge = MediaRemoteBridge.shared
    private let cliHelper = MediaRemoteCLIHelper.shared
    private var notificationObservers: [NSObjectProtocol] = []
    private var isObserving = false
    private var pollingTimer: Timer?
    
    public init() {}
    
    public func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        
        print("🎵 [MediaRemoteProvider] Starting media observation...")
        
        // 1. NotificationCenter.default observers
        let infoObserver = NotificationCenter.default.addObserver(
            forName: MediaRemoteBridge.nowPlayingInfoDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
        
        let appObserver = NotificationCenter.default.addObserver(
            forName: MediaRemoteBridge.nowPlayingAppDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
        
        notificationObservers = [infoObserver, appObserver]
        
        // 2. Distributed Notification Center (Apple Music & Spotify system broadcasts)
        let musicObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
        
        let spotifyObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
        
        notificationObservers.append(contentsOf: [musicObserver, spotifyObserver])
        
        // 3. Darwin Notification Center (mediaremoted system daemon broadcasts)
        let darwinCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let observerPtr = Unmanaged.passUnretained(self).toOpaque()
        
        CFNotificationCenterAddObserver(
            darwinCenter,
            observerPtr,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let provider = Unmanaged<MediaRemoteProvider>.fromOpaque(observer).takeUnretainedValue()
                provider.fetchCurrentMedia()
            },
            "kMRMediaRemoteNowPlayingInfoDidChangeNotification" as CFString,
            nil,
            .deliverImmediately
        )
        
        CFNotificationCenterAddObserver(
            darwinCenter,
            observerPtr,
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let provider = Unmanaged<MediaRemoteProvider>.fromOpaque(observer).takeUnretainedValue()
                provider.fetchCurrentMedia()
            },
            "kMRMediaRemoteNowPlayingApplicationDidChangeNotification" as CFString,
            nil,
            .deliverImmediately
        )
        
        // 4. Heartbeat polling timer added to RunLoop .common mode (1.5 seconds)
        let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.pollingTimer = timer
        
        // Initial immediate fetch
        fetchCurrentMedia()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.fetchCurrentMedia()
        }
    }
    
    public func stopObserving() {
        guard isObserving else { return }
        isObserving = false
        
        pollingTimer?.invalidate()
        pollingTimer = nil
        
        let darwinCenter = CFNotificationCenterGetDarwinNotifyCenter()
        let observerPtr = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterRemoveEveryObserver(darwinCenter, observerPtr)
        
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        notificationObservers.removeAll()
    }
    
    public func fetchCurrentMedia() {
        cliHelper.fetchNowPlaying { [weak self] item in
            DispatchQueue.main.async {
                self?.onMediaChange?(item)
            }
        }
    }
    
    public func togglePlayPause() {
        bridge.sendCommand(MediaRemoteBridge.commandTogglePlayPause)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.fetchCurrentMedia()
        }
    }
    
    public func nextTrack() {
        bridge.sendCommand(MediaRemoteBridge.commandNextTrack)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.fetchCurrentMedia()
        }
    }
    
    public func previousTrack() {
        bridge.sendCommand(MediaRemoteBridge.commandPreviousTrack)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.fetchCurrentMedia()
        }
    }
    
    public func seek(to seconds: Double) {
        bridge.setElapsedTime(seconds)
    }
}
