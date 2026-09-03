import Foundation
import Combine
import AppKit
import os.log

// MARK: - MediaManager
// Central state manager for media playback information.
// Connects to NowPlayingProvider and automatically detects browser streaming services
// (YouTube, Netflix, Prime Video, Spotify, etc.) via BrowserServiceDetector.
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
        
        // Retain previously resolved service if the track title is unchanged
        let resolvedService: MediaService
        if newItem.service != .generic {
            resolvedService = newItem.service
        } else if let existing = self.currentItem, existing.title == newItem.title, existing.service != .generic {
            resolvedService = existing.service
        } else if let cached = BrowserServiceDetector.shared.cachedService(bundleId: newItem.bundleIdentifier ?? "", trackTitle: newItem.title) {
            resolvedService = cached
        } else {
            resolvedService = newItem.service
        }
        
        let mergedItem = MediaItem(
            id: newItem.id,
            title: newItem.title,
            artist: newItem.artist,
            album: newItem.album,
            artworkData: newItem.artworkData ?? self.currentItem?.artworkData,
            duration: newItem.duration,
            currentTime: newItem.currentTime,
            isPlaying: newItem.isPlaying,
            application: newItem.application,
            bundleIdentifier: newItem.bundleIdentifier,
            lastUpdated: newItem.lastUpdated,
            service: resolvedService
        )
        
        self.currentItem = mergedItem
        self.playbackState = mergedItem.isPlaying ? .playing : .paused
        let progress = mergedItem.currentProgress()
        self.interpolatedProgress = mergedItem.progressFraction()
        self.formattedCurrentTime = MediaItem.formatTime(progress)
        self.formattedDuration = MediaItem.formatTime(mergedItem.duration)
        
        let remaining = max(0, mergedItem.duration - progress)
        self.formattedRemainingTime = mergedItem.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
        
        // If still generic in a browser, query background tab detector
        if mergedItem.isBrowserMedia && mergedItem.service == .generic {
            let bundleId = mergedItem.bundleIdentifier ?? ""
            let appName = mergedItem.application
            let trackTitle = mergedItem.title
            
            Task {
                if let detected = await BrowserServiceDetector.shared.detectService(
                    bundleId: bundleId,
                    appName: appName,
                    trackTitle: trackTitle
                ) {
                    await MainActor.run { [weak self] in
                        guard let self = self, self.currentItem?.title == trackTitle else { return }
                        self.currentItem = MediaItem(
                            id: mergedItem.id,
                            title: mergedItem.title,
                            artist: mergedItem.artist,
                            album: mergedItem.album,
                            artworkData: mergedItem.artworkData,
                            duration: mergedItem.duration,
                            currentTime: mergedItem.currentTime,
                            isPlaying: mergedItem.isPlaying,
                            application: mergedItem.application,
                            bundleIdentifier: mergedItem.bundleIdentifier,
                            lastUpdated: mergedItem.lastUpdated,
                            service: detected
                        )
                    }
                }
            }
        }
    }
    
    private func startProgressTicker() {
        // Run ticker every 0.5 seconds to advance the progress bar smoothly in all run loop modes
        let ticker = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, let item = self.currentItem, item.isPlaying else { return }
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
        // Optimistic UI update for instant feedback
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
    
    deinit {
        progressTicker?.invalidate()
        provider.stopObserving()
    }
}
