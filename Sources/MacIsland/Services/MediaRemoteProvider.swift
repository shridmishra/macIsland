import Foundation
import AppKit

// MARK: - MediaRemote Implementation of NowPlayingProvider
// Listens to system-wide media events and converts raw dictionary metadata into MediaItem models.
// Uses MediaRemoteCLIHelper (persistent background subprocess) to retrieve system metadata
// and execute playback commands across all audio sources on modern macOS without permission restrictions.
public final class MediaRemoteProvider: NowPlayingProvider, @unchecked Sendable {
    public var onMediaChange: (@Sendable (MediaItem?) -> Void)?
    
    private let cliHelper = MediaRemoteCLIHelper.shared
    private var notificationObservers: [NSObjectProtocol] = []
    private var heartbeatTimer: Timer?
    private var isObserving = false
    
    public init() {}
    
    public func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        
        print("🎵 [MediaRemoteProvider] Starting media observation via persistent helper...")
        
        // 1. Connect to persistent MediaRemote helper stream
        cliHelper.startObserving { [weak self] item in
            DispatchQueue.main.async {
                self?.onMediaChange?(item)
            }
        }
        
        // 2. Distributed Notification Center (Apple Music & Spotify system broadcasts)
        let musicObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            self?.handleMusicNotification(notif, service: .appleMusic, bundleId: "com.apple.Music", appName: "Music")
        }
        
        let spotifyObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            self?.handleMusicNotification(notif, service: .spotify, bundleId: "com.spotify.client", appName: "Spotify")
        }
        
        notificationObservers = [musicObserver, spotifyObserver]
        
        // 3. Periodic query heartbeat fallback (every 2.0s) to guarantee robust browser & 3rd-party audio recognition
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchCurrentMedia()
        }
        
        // Initial immediate fetch
        fetchCurrentMedia()
    }
    
    public func stopObserving() {
        guard isObserving else { return }
        isObserving = false
        
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        for observer in notificationObservers {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        notificationObservers.removeAll()
        
        cliHelper.stopObserving()
    }
    
    public func fetchCurrentMedia() {
        cliHelper.fetchNowPlaying { [weak self] item in
            DispatchQueue.main.async {
                self?.onMediaChange?(item)
            }
        }
    }
    
    public func togglePlayPause() {
        cliHelper.sendCommand("toggle")
    }
    
    public func nextTrack() {
        cliHelper.sendCommand("next")
    }
    
    public func previousTrack() {
        cliHelper.sendCommand("prev")
    }
    
    public func seek(to seconds: Double) {
        cliHelper.seek(to: seconds)
    }
    
    // MARK: - Native Music App Notification & Direct Query
    private func handleMusicNotification(_ notification: Notification, service: MediaService, bundleId: String, appName: String) {
        guard let userInfo = notification.userInfo else {
            fetchCurrentMedia()
            return
        }
        
        let playerState = (userInfo["Player State"] as? String)?.lowercased() ?? ""
        let isPlaying = playerState == "playing"
        let isStopped = playerState == "stopped"
        
        let title = (userInfo["Name"] as? String) ?? ""
        let artist = (userInfo["Artist"] as? String) ?? ""
        let album = (userInfo["Album"] as? String) ?? ""
        
        var duration: Double = 0.0
        if let totalTime = userInfo["Total Time"] as? NSNumber {
            duration = totalTime.doubleValue / 1000.0
        } else if let dur = userInfo["Duration"] as? NSNumber {
            let val = dur.doubleValue
            duration = val > 1000 ? val / 1000.0 : val
        }
        
        var position: Double = 0.0
        if let pos = userInfo["Player Position"] as? NSNumber {
            position = pos.doubleValue
        } else if let pos = userInfo["Position"] as? NSNumber {
            position = pos.doubleValue
        }
        
        if !title.isEmpty && !isStopped {
            let item = MediaItem(
                title: title,
                artist: artist,
                album: album,
                duration: duration,
                currentTime: position,
                isPlaying: isPlaying,
                application: appName,
                bundleIdentifier: bundleId,
                lastUpdated: Date(),
                service: service
            )
            DispatchQueue.main.async { [weak self] in
                self?.onMediaChange?(item)
            }
        } else if isStopped || playerState == "paused" {
            if !title.isEmpty {
                let item = MediaItem(
                    title: title,
                    artist: artist,
                    album: album,
                    duration: duration,
                    currentTime: position,
                    isPlaying: false,
                    application: appName,
                    bundleIdentifier: bundleId,
                    lastUpdated: Date(),
                    service: service
                )
                DispatchQueue.main.async { [weak self] in
                    self?.onMediaChange?(item)
                }
            } else {
                fetchCurrentMedia()
            }
        } else {
            fetchCurrentMedia()
        }
    }
    
    /// Checks if native Apple Music or Spotify is actively running and playing.
    public static func checkNativeMusicActive() -> MediaItem? {
        let isMusicRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty
        let isSpotifyRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty
        
        if isMusicRunning {
            let script = """
            tell application "Music"
                if running then
                    try
                        if player state is playing then
                            set tName to name of current track
                            set tArtist to artist of current track
                            set tAlbum to album of current track
                            set tDur to duration of current track
                            set tPos to player position
                            return tName & "|||" & tArtist & "|||" & tAlbum & "|||" & tDur & "|||" & tPos
                        end if
                    end try
                end if
            end tell
            return ""
            """
            var error: NSDictionary?
            if let res = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue, !res.isEmpty {
                let parts = res.components(separatedBy: "|||")
                if parts.count >= 5 {
                    return MediaItem(
                        title: parts[0],
                        artist: parts[1],
                        album: parts[2],
                        duration: Double(parts[3]) ?? 0,
                        currentTime: Double(parts[4]) ?? 0,
                        isPlaying: true,
                        application: "Music",
                        bundleIdentifier: "com.apple.Music",
                        service: .appleMusic
                    )
                }
            }
        }
        
        if isSpotifyRunning {
            let script = """
            tell application "Spotify"
                if running then
                    try
                        if player state is playing then
                            set tName to name of current track
                            set tArtist to artist of current track
                            set tAlbum to album of current track
                            set tDur to (duration of current track) / 1000.0
                            set tPos to player position
                            return tName & "|||" & tArtist & "|||" & tAlbum & "|||" & tDur & "|||" & tPos
                        end if
                    end try
                end if
            end tell
            return ""
            """
            var error: NSDictionary?
            if let res = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue, !res.isEmpty {
                let parts = res.components(separatedBy: "|||")
                if parts.count >= 5 {
                    return MediaItem(
                        title: parts[0],
                        artist: parts[1],
                        album: parts[2],
                        duration: Double(parts[3]) ?? 0,
                        currentTime: Double(parts[4]) ?? 0,
                        isPlaying: true,
                        application: "Spotify",
                        bundleIdentifier: "com.spotify.client",
                        service: .spotify
                    )
                }
            }
        }
        
        return nil
    }
}
