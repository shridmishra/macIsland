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
        logger.info("🎧 [MediaManager] updateMediaItem: \(item?.title ?? "none", privacy: .public) | isPlaying: \(item?.isPlaying ?? false)")
        self.currentItem = item
        if let item = item {
            self.playbackState = item.isPlaying ? .playing : .paused
            let progress = item.currentProgress()
            self.interpolatedProgress = item.progressFraction()
            self.formattedCurrentTime = MediaItem.formatTime(progress)
            self.formattedDuration = MediaItem.formatTime(item.duration)
            
            let remaining = max(0, item.duration - progress)
            self.formattedRemainingTime = item.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
            
            // Asynchronously resolve specific media streaming service if playing inside a browser
            if item.isBrowserMedia && item.service == .generic {
                let bundleId = item.bundleIdentifier ?? ""
                let appName = item.application
                let trackTitle = item.title
                
                Task {
                    if let detected = await BrowserServiceDetector.shared.detectService(
                        bundleId: bundleId,
                        appName: appName,
                        trackTitle: trackTitle
                    ) {
                        await MainActor.run { [weak self] in
                            guard let self = self, self.currentItem?.title == trackTitle else { return }
                            let updated = MediaItem(
                                id: item.id,
                                title: item.title,
                                artist: item.artist,
                                album: item.album,
                                artworkData: item.artworkData,
                                duration: item.duration,
                                currentTime: item.currentTime,
                                isPlaying: item.isPlaying,
                                application: item.application,
                                bundleIdentifier: item.bundleIdentifier,
                                lastUpdated: item.lastUpdated,
                                service: detected
                            )
                            self.currentItem = updated
                        }
                    }
                }
            }
        } else {
            self.playbackState = .stopped
            self.interpolatedProgress = 0.0
            self.formattedCurrentTime = "0:00"
            self.formattedDuration = "0:00"
            self.formattedRemainingTime = "-0:00"
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
