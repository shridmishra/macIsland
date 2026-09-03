import Foundation
import Combine
import SwiftUI

// MARK: - MediaManager
// Central coordinator for media state in Mac Island.
// Think of this like a React Context / Zustand store:
// It holds the reactive state (`@Published var currentItem`), runs background timers for smooth
// second-by-second playback bar interpolation, and dispatches user actions (play, pause, next).
@MainActor
public final class MediaManager: ObservableObject {
    public static let shared = MediaManager()
    
    @Published public private(set) var currentItem: MediaItem?
    @Published public private(set) var playbackState: PlaybackState = .stopped
    @Published public private(set) var interpolatedProgress: Double = 0.0
    @Published public private(set) var formattedCurrentTime: String = "0:00"
    @Published public private(set) var formattedDuration: String = "0:00"
    
    private var provider: NowPlayingProvider
    private var progressTicker: Timer?
    
    public init(provider: NowPlayingProvider = MediaRemoteProvider()) {
        self.provider = provider
        setupProvider()
        startProgressTicker()
    }
    
    private func setupProvider() {
        provider.onMediaChange = { [weak self] item in
            Task { @MainActor [weak self] in
                self?.updateMediaItem(item)
            }
        }
        provider.startObserving()
    }
    
    private func updateMediaItem(_ item: MediaItem?) {
        self.currentItem = item
        if let item = item {
            self.playbackState = item.isPlaying ? .playing : .paused
            self.interpolatedProgress = item.progressFraction()
            self.formattedCurrentTime = MediaItem.formatTime(item.currentProgress())
            self.formattedDuration = MediaItem.formatTime(item.duration)
        } else {
            self.playbackState = .stopped
            self.interpolatedProgress = 0.0
            self.formattedCurrentTime = "0:00"
            self.formattedDuration = "0:00"
        }
    }
    
    private func startProgressTicker() {
        // Run ticker every 0.5 seconds to advance the progress bar smoothly
        progressTicker = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let item = self.currentItem, item.isPlaying else { return }
                let progress = item.currentProgress()
                self.interpolatedProgress = item.progressFraction()
                self.formattedCurrentTime = MediaItem.formatTime(progress)
            }
        }
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
