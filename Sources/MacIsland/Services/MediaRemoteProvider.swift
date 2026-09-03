import Foundation
import AppKit

// MARK: - MediaRemote Implementation of NowPlayingProvider
// Listens to system-wide media events and converts raw dictionary metadata into MediaItem models.
public final class MediaRemoteProvider: NowPlayingProvider, @unchecked Sendable {
    public var onMediaChange: (@Sendable (MediaItem?) -> Void)?
    
    private let bridge = MediaRemoteBridge.shared
    private var notificationObservers: [NSObjectProtocol] = []
    private var isObserving = false
    private var pollingTimer: Timer?
    
    public init() {}
    
    public func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        
        // Register MediaRemote notification pipeline
        bridge.registerForNotifications(queue: .main)
        
        // 1. When track info changes (title, artist, artwork, duration)
        let infoObserver = NotificationCenter.default.addObserver(
            forName: MediaRemoteBridge.nowPlayingInfoDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
        
        // 2. When active media player changes (e.g. Spotify -> Brave)
        let appObserver = NotificationCenter.default.addObserver(
            forName: MediaRemoteBridge.nowPlayingAppDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
        
        // 3. When playback state changes (play -> pause)
        let stateObserver = NotificationCenter.default.addObserver(
            forName: MediaRemoteBridge.nowPlayingPlaybackStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
        
        notificationObservers = [infoObserver, appObserver, stateObserver]
        
        // Initial fetch immediately
        fetchCurrentMedia()
        
        // Periodic heartbeat poll (ensures elapsed time and state stay synchronized)
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
    }
    
    public func stopObserving() {
        guard isObserving else { return }
        isObserving = false
        
        pollingTimer?.invalidate()
        pollingTimer = nil
        
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        notificationObservers.removeAll()
        
        bridge.unregisterForNotifications()
    }
    
    public func fetchCurrentMedia() {
        bridge.getNowPlayingInfo(queue: .main) { [weak self] info in
            guard let self = self else { return }
            
            guard let info = info, !info.isEmpty else {
                self.onMediaChange?(nil)
                return
            }
            
            // Extract core metadata
            let rawTitle = info[MediaRemoteBridge.keyTitle] as? String
            let rawArtist = info[MediaRemoteBridge.keyArtist] as? String
            let rawAlbum = info[MediaRemoteBridge.keyAlbum] as? String
            let artworkData = info[MediaRemoteBridge.keyArtworkData] as? Data
            let duration = (info[MediaRemoteBridge.keyDuration] as? Double) ?? 0.0
            let elapsedTime = (info[MediaRemoteBridge.keyElapsedTime] as? Double) ?? 0.0
            let playbackRate = (info[MediaRemoteBridge.keyPlaybackRate] as? Double) ?? 0.0
            let isPlaying = playbackRate > 0.0
            
            // If there is no title and no artist, treat as no media playing
            guard let title = rawTitle, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self.onMediaChange?(nil)
                return
            }
            
            // Query current application process ID to retrieve app name & icon
            self.bridge.getNowPlayingApplicationPID(queue: .main) { pid in
                var appName = "Media Player"
                var bundleId: String? = nil
                
                if pid > 0, let runningApp = NSRunningApplication(processIdentifier: pid) {
                    appName = runningApp.localizedName ?? "Media Player"
                    bundleId = runningApp.bundleIdentifier
                }
                
                let mediaItem = MediaItem(
                    title: title,
                    artist: rawArtist ?? "",
                    album: rawAlbum ?? "",
                    artworkData: artworkData,
                    duration: duration,
                    currentTime: elapsedTime,
                    isPlaying: isPlaying,
                    application: appName,
                    bundleIdentifier: bundleId,
                    lastUpdated: Date()
                )
                
                self.onMediaChange?(mediaItem)
            }
        }
    }
    
    public func togglePlayPause() {
        bridge.sendCommand(MediaRemoteBridge.commandTogglePlayPause)
        // Re-fetch shortly after command dispatch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.fetchCurrentMedia()
        }
    }
    
    public func nextTrack() {
        bridge.sendCommand(MediaRemoteBridge.commandNextTrack)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.fetchCurrentMedia()
        }
    }
    
    public func previousTrack() {
        bridge.sendCommand(MediaRemoteBridge.commandPreviousTrack)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.fetchCurrentMedia()
        }
    }
}
