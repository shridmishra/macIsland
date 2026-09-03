import Foundation
import Combine
import AppKit
import os.log

// MARK: - MediaManager
// Central state manager for media playback information and real-time timeline progress.
// Connects to NowPlayingProvider and automatically detects browser streaming services
// and exact playback position (currentTime / duration) via BrowserServiceDetector.
@MainActor
public final class MediaManager: ObservableObject {
    public static let shared = MediaManager()
    
    @Published public private(set) var currentItem: MediaItem?
    @Published public private(set) var playbackState: PlaybackState = .stopped
    @Published public private(set) var interpolatedProgress: Double = 0.0
    @Published public private(set) var formattedCurrentTime: String = "0:00"
    @Published public private(set) var formattedDuration: String = "0:00"
    @Published public private(set) var formattedRemainingTime: String = "-0:00"
    
    private let provider: NowPlayingProvider
    private var progressTicker: Timer?
    private var lastSeekDate: Date?
    private var lastSeekTargetSeconds: Double?
    private let logger = Logger(subsystem: "com.macisland.app", category: "MediaManager")
    
    public init(provider: NowPlayingProvider = MediaRemoteProvider()) {
        self.provider = provider
        setupProvider()
        startProgressTicker()
    }
    
    private func setupProvider() {
        provider.onMediaChange = { [weak self] item in
            DispatchQueue.main.async {
                self?.updateMediaItem(item)
            }
        }
        provider.startObserving()
    }
    
    private func updateMediaItem(_ item: MediaItem?) {
        guard let newItem = item else {
            self.currentItem = nil
            self.playbackState = .stopped
            self.interpolatedProgress = 0.0
            self.formattedCurrentTime = "0:00"
            self.formattedDuration = "0:00"
            self.formattedRemainingTime = "-0:00"
            return
        }
        
        // 1. Retain previously resolved service
        let resolvedService: MediaService
        if newItem.service != .generic {
            resolvedService = newItem.service
        } else if let active = BrowserServiceDetector.shared.activeService(for: newItem.bundleIdentifier ?? newItem.application) {
            resolvedService = active
        } else if let cached = BrowserServiceDetector.shared.cachedService(bundleId: newItem.bundleIdentifier ?? "", trackTitle: newItem.title) {
            resolvedService = cached
        } else if let existing = self.currentItem, existing.service != .generic {
            resolvedService = existing.service
        } else {
            resolvedService = newItem.service
        }
        
        // 2. Retain duration and running progress if new item has zero or stale progress
        let resolvedDuration: Double
        if newItem.duration > 0 {
            resolvedDuration = newItem.duration
        } else if let existing = self.currentItem, existing.title == newItem.title, existing.duration > 0 {
            resolvedDuration = existing.duration
        } else {
            resolvedDuration = 0.0
        }
        
        let resolvedCurrentTime: Double
        let resolvedLastUpdated: Date
        
        // If a seek occurred recently (< 2.0 seconds), don't allow a stale poller update to revert the seek!
        if let seekDate = self.lastSeekDate, let seekTarget = self.lastSeekTargetSeconds, Date().timeIntervalSince(seekDate) < 2.0 {
            let elapsed = Date().timeIntervalSince(seekDate)
            let expectedTime = seekTarget + (newItem.isPlaying ? elapsed : 0)
            
            // Check if player has acknowledged the seek (reported time close to or past expected)
            if newItem.currentTime > 0 && (abs(newItem.currentTime - expectedTime) < 3.0 || newItem.currentTime >= (seekTarget - 1.0)) {
                self.lastSeekDate = nil
                self.lastSeekTargetSeconds = nil
                resolvedCurrentTime = newItem.currentTime
                resolvedLastUpdated = newItem.lastUpdated
            } else {
                resolvedCurrentTime = min(resolvedDuration > 0 ? resolvedDuration : expectedTime, expectedTime)
                resolvedLastUpdated = Date()
            }
        } else if newItem.currentTime > 0 {
            resolvedCurrentTime = newItem.currentTime
            resolvedLastUpdated = newItem.lastUpdated
        } else if let existing = self.currentItem, existing.title == newItem.title, existing.currentProgress() > 0 {
            // Retain running progress and advance from wall clock
            resolvedCurrentTime = existing.currentProgress()
            resolvedLastUpdated = Date()
        } else {
            resolvedCurrentTime = newItem.currentTime
            resolvedLastUpdated = newItem.lastUpdated
        }
        
        let mergedItem = MediaItem(
            id: newItem.id,
            title: newItem.title,
            artist: newItem.artist,
            album: newItem.album,
            artworkData: newItem.artworkData ?? self.currentItem?.artworkData,
            duration: resolvedDuration,
            currentTime: resolvedCurrentTime,
            isPlaying: newItem.isPlaying,
            application: newItem.application,
            bundleIdentifier: newItem.bundleIdentifier,
            lastUpdated: resolvedLastUpdated,
            service: resolvedService
        )
        
        self.currentItem = mergedItem
        logger.info("🎵 [MediaManager] current: \(mergedItem.title, privacy: .public) | effectiveApp: \(mergedItem.effectiveAppName, privacy: .public) | service: \(mergedItem.service.rawValue, privacy: .public)")
        self.playbackState = mergedItem.isPlaying ? .playing : .paused
        let progress = mergedItem.currentProgress()
        self.interpolatedProgress = mergedItem.progressFraction()
        self.formattedCurrentTime = MediaItem.formatTime(progress)
        self.formattedDuration = MediaItem.formatTime(mergedItem.duration)
        
        let remaining = max(0, mergedItem.duration - progress)
        self.formattedRemainingTime = mergedItem.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
        
        // 3. Query background tab detector for accurate service and video currentTime/duration
        if mergedItem.isBrowserMedia {
            var bundleId = mergedItem.bundleIdentifier ?? ""
            let appName = mergedItem.application
            if bundleId.isEmpty || bundleId.contains("helper") {
                let lowerApp = appName.lowercased()
                if lowerApp.contains("brave") { bundleId = "com.brave.Browser" }
                else if lowerApp.contains("chrome") { bundleId = "com.google.Chrome" }
                else if lowerApp.contains("safari") { bundleId = "com.apple.Safari" }
                else if lowerApp.contains("edge") { bundleId = "com.microsoft.edgemac" }
                else if lowerApp.contains("arc") { bundleId = "company.thebrowser.Arc" }
            }
            let trackTitle = mergedItem.title
            
            Task {
                if let detected = await BrowserServiceDetector.shared.detectService(
                    bundleId: bundleId,
                    appName: appName,
                    trackTitle: trackTitle
                ) {
                    await MainActor.run { [weak self] in
                        guard let self = self else { return }
                        let finalDuration = (detected.duration ?? 0) > 0 ? (detected.duration ?? mergedItem.duration) : (self.currentItem?.duration ?? mergedItem.duration)
                        
                        let finalCurrentTime: Double
                        let finalLastUpdated: Date
                        
                        // Guard against stale background detection pulling progress backward after a seek
                        if let seekDate = self.lastSeekDate, let seekTarget = self.lastSeekTargetSeconds, Date().timeIntervalSince(seekDate) < 2.0 {
                            let elapsed = Date().timeIntervalSince(seekDate)
                            let expectedTime = seekTarget + (self.currentItem?.isPlaying == true ? elapsed : 0)
                            
                            if let detTime = detected.currentTime, detTime > 0 && (abs(detTime - expectedTime) < 3.0 || detTime >= (seekTarget - 1.0)) {
                                // Player confirmed seek
                                self.lastSeekDate = nil
                                self.lastSeekTargetSeconds = nil
                                finalCurrentTime = detTime
                                finalLastUpdated = Date()
                            } else {
                                // Ignore stale pre-seek time
                                finalCurrentTime = expectedTime
                                finalLastUpdated = Date()
                            }
                        } else if let detTime = detected.currentTime, detTime > 0 {
                            finalCurrentTime = detTime
                            finalLastUpdated = Date()
                        } else {
                            finalCurrentTime = self.currentItem?.currentTime ?? mergedItem.currentTime
                            finalLastUpdated = self.currentItem?.lastUpdated ?? mergedItem.lastUpdated
                        }
                        
                        let serviceToUse = detected.service != .generic ? detected.service : (self.currentItem?.service ?? mergedItem.service)
                        
                        let updated = MediaItem(
                            id: mergedItem.id,
                            title: self.currentItem?.title ?? mergedItem.title,
                            artist: self.currentItem?.artist ?? mergedItem.artist,
                            album: self.currentItem?.album ?? mergedItem.album,
                            artworkData: self.currentItem?.artworkData ?? mergedItem.artworkData,
                            duration: finalDuration,
                            currentTime: finalCurrentTime,
                            isPlaying: self.currentItem?.isPlaying ?? mergedItem.isPlaying,
                            application: mergedItem.application,
                            bundleIdentifier: mergedItem.bundleIdentifier,
                            lastUpdated: finalLastUpdated,
                            service: serviceToUse
                        )
                        self.currentItem = updated
                        self.logger.info("🎯 [MediaManager:Detected] updated: \(updated.title, privacy: .public) | effectiveApp: \(updated.effectiveAppName, privacy: .public) | service: \(updated.service.rawValue, privacy: .public)")
                        let progress = updated.currentProgress()
                        self.interpolatedProgress = updated.progressFraction()
                        self.formattedCurrentTime = MediaItem.formatTime(progress)
                        self.formattedDuration = MediaItem.formatTime(updated.duration)
                        let remaining = max(0, updated.duration - progress)
                        self.formattedRemainingTime = updated.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
                    }
                }
            }
        }
    }
    
    private func startProgressTicker() {
        // Run ticker every 0.25 seconds to advance the progress bar smoothly in all run loop modes
        let ticker = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, let item = self.currentItem, item.isPlaying else { return }
                
                // If in active seek lock (under 2.0s), advance smoothly from seek target
                if let seekDate = self.lastSeekDate, let seekTarget = self.lastSeekTargetSeconds {
                    let elapsed = Date().timeIntervalSince(seekDate)
                    if elapsed < 2.0 {
                        let current = min(item.duration > 0 ? item.duration : seekTarget + elapsed, seekTarget + elapsed)
                        self.interpolatedProgress = item.duration > 0 ? current / item.duration : 0.0
                        self.formattedCurrentTime = MediaItem.formatTime(current)
                        let remaining = max(0, item.duration - current)
                        self.formattedRemainingTime = item.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
                        return
                    } else {
                        self.lastSeekDate = nil
                        self.lastSeekTargetSeconds = nil
                    }
                }
                
                let progress = item.currentProgress()
                self.interpolatedProgress = item.progressFraction()
                self.formattedCurrentTime = MediaItem.formatTime(progress)
                let remaining = max(0, item.duration - progress)
                self.formattedRemainingTime = item.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
            }
        }
        RunLoop.main.add(ticker, forMode: .common)
        self.progressTicker = ticker
    }
    
    // MARK: - Playback Actions
    public func togglePlayPause() {
        provider.togglePlayPause()
        if let item = currentItem {
            let nextPlaying = !item.isPlaying
            playbackState = nextPlaying ? .playing : .paused
        }
    }
    
    public func nextTrack() {
        provider.nextTrack()
    }
    
    public func previousTrack() {
        provider.previousTrack()
    }
    
    public func seek(to fraction: Double) {
        guard let item = currentItem, item.duration > 0 else { return }
        let targetSeconds = max(0, min(item.duration, fraction * item.duration))
        
        // 1. Set seek lock to prevent polling ticks from snapping back
        lastSeekDate = Date()
        lastSeekTargetSeconds = targetSeconds
        
        // 2. Immediately update progress state so UI reflects scrub instantly
        interpolatedProgress = fraction
        formattedCurrentTime = MediaItem.formatTime(targetSeconds)
        let remaining = max(0, item.duration - targetSeconds)
        formattedRemainingTime = "-\(MediaItem.formatTime(remaining))"
        
        // 3. Immediately update currentItem so internal calculations use the new timestamp
        let updatedItem = MediaItem(
            id: item.id,
            title: item.title,
            artist: item.artist,
            album: item.album,
            artworkData: item.artworkData,
            duration: item.duration,
            currentTime: targetSeconds,
            isPlaying: item.isPlaying,
            application: item.application,
            bundleIdentifier: item.bundleIdentifier,
            lastUpdated: Date(),
            service: item.service
        )
        self.currentItem = updatedItem
        
        // 4. Perform actual seek across player integrations
        performSeek(targetSeconds: targetSeconds, item: updatedItem)
    }
    
    private func performSeek(targetSeconds: Double, item: MediaItem) {
        let appName = item.application
        let bundleId = item.bundleIdentifier ?? ""
        let trackTitle = item.title
        
        // Universal baseline: Tell MediaRemote bridge to seek
        provider.seek(to: targetSeconds)
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Native Apple Music
            if bundleId == "com.apple.Music" || (appName.contains("Music") && !item.isBrowserMedia) {
                let script = """
                tell application "Music"
                    if running then
                        try
                            set player position to \(targetSeconds)
                        end try
                    end if
                end tell
                """
                var error: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&error)
                return
            }
            
            // 2. Native Spotify
            if bundleId == "com.spotify.client" || (appName.contains("Spotify") && !item.isBrowserMedia) {
                let script = """
                tell application "Spotify"
                    if running then
                        try
                            set player position to \(targetSeconds)
                        end try
                    end if
                end tell
                """
                var error: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&error)
                return
            }
            
            // 3. QuickTime Player
            if bundleId == "com.apple.QuickTimePlayerX" || appName.contains("QuickTime") {
                let script = """
                tell application "QuickTime Player"
                    if running and (count of documents) > 0 then
                        try
                            set current time of document 1 to \(targetSeconds)
                        end try
                    end if
                end tell
                """
                var error: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&error)
                return
            }
            
            // 4. Web Browsers (Brave Browser, Chrome, Safari, Edge, Arc, Opera, Vivaldi)
            if item.isBrowserMedia || MediaService.browserBundleIds.contains(bundleId) {
                let stripped = trackTitle
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: "\\", with: "")
                    .filter { $0.isASCII || $0.isLetter || $0.isNumber || $0.isWhitespace }
                let cleanWords = stripped.split(separator: " ").prefix(2).joined(separator: " ")
                let prefix = cleanWords.isEmpty ? String(trackTitle.prefix(6)) : cleanWords
                let lowerPrefix = prefix.lowercased()
                
                let targetAppName = appName.contains("Media Player") ? "Brave Browser" : appName
                
                let script: String
                if bundleId == "com.apple.Safari" {
                    script = """
                    tell application "Safari"
                        if running then
                            try
                                tell current tab of window 1
                                    set res to do JavaScript "(() => { const yt = document.getElementById('movie_player'); if (yt && typeof yt.seekTo === 'function') { yt.seekTo(\(targetSeconds), true); return 'ok'; } const media = Array.from(document.querySelectorAll('video, audio')); if (media.length > 0) { for (const m of media) { m.currentTime = \(targetSeconds); } return 'ok'; } return ''; })()"
                                    if res is "ok" then return
                                end tell
                            end try
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        set res to do JavaScript "(() => { const u = window.location.href; const ms = navigator.mediaSession ? navigator.mediaSession.metadata : null; const msTitle = (ms && ms.title ? ms.title : '').toLowerCase(); const tabTitle = document.title.toLowerCase(); const media = Array.from(document.querySelectorAll('video, audio')); if (media.length === 0) return ''; const match = ('\(lowerPrefix)' !== '' && (tabTitle.includes('\(lowerPrefix)') || msTitle.includes('\(lowerPrefix)'))); const isPlaying = media.some(m => !m.paused); if (match || isPlaying) { const yt = document.getElementById('movie_player'); if (yt && typeof yt.seekTo === 'function') { yt.seekTo(\(targetSeconds), true); return 'ok'; } for (const m of media) { m.currentTime = \(targetSeconds); } return 'ok'; } return ''; })()" in t
                                        if res is "ok" then exit repeat
                                    end try
                                end repeat
                            end repeat
                        end if
                    end tell
                    """
                } else {
                    script = """
                    tell application "\(targetAppName)"
                        if running then
                            try
                                tell active tab of window 1
                                    set res to execute javascript "(() => { const yt = document.getElementById('movie_player'); if (yt && typeof yt.seekTo === 'function') { yt.seekTo(\(targetSeconds), true); return 'ok'; } const media = Array.from(document.querySelectorAll('video, audio')); if (media.length > 0) { for (const m of media) { m.currentTime = \(targetSeconds); } return 'ok'; } return ''; })()"
                                    if res is "ok" then return
                                end tell
                            end try
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        tell t
                                            set res to execute javascript "(() => { const u = window.location.href; const ms = navigator.mediaSession ? navigator.mediaSession.metadata : null; const msTitle = (ms && ms.title ? ms.title : '').toLowerCase(); const tabTitle = document.title.toLowerCase(); const media = Array.from(document.querySelectorAll('video, audio')); if (media.length === 0) return ''; const match = ('\(lowerPrefix)' !== '' && (tabTitle.includes('\(lowerPrefix)') || msTitle.includes('\(lowerPrefix)'))); const isPlaying = media.some(m => !m.paused); if (match || isPlaying) { const yt = document.getElementById('movie_player'); if (yt && typeof yt.seekTo === 'function') { yt.seekTo(\(targetSeconds), true); return 'ok'; } for (const m of media) { m.currentTime = \(targetSeconds); } return 'ok'; } return ''; })()"
                                            if res is "ok" then exit repeat
                                        end tell
                                    end try
                                end repeat
                            end repeat
                        end if
                    end tell
                    """
                }
                var error: NSDictionary?
                NSAppleScript(source: script)?.executeAndReturnError(&error)
            }
        }
    }
    
    deinit {
        progressTicker?.invalidate()
        provider.stopObserving()
    }
}
