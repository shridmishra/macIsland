import Foundation
import Combine
import SwiftUI
import os.log

// MARK: - LyricsManager
/// Coordinates song lyrics fetching, active line tracking, and user visibility toggle.
/// Defaults to disabled (isLyricsEnabled = false) as requested by user.
@MainActor
public final class LyricsManager: ObservableObject {
    public static let shared = LyricsManager()
    
    /// User toggle state: defaults to false (OFF)
    @Published public var isLyricsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLyricsEnabled, forKey: "MacIsland.isLyricsEnabled")
            if isLyricsEnabled {
                if currentLyrics == nil && !isLoading {
                    fetchCurrentTrackLyrics()
                } else if !hasLyrics && !isLoading {
                    triggerNoLyricsNotice()
                }
            } else {
                noLyricsTimer?.cancel()
                showNoLyricsNotice = false
            }
        }
    }
    
    @Published public private(set) var currentLyrics: SongLyrics?
    @Published public private(set) var currentLine: LyricLine?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var hasLyrics: Bool = false
    @Published public private(set) var showNoLyricsNotice: Bool = false
    
    private var noLyricsTimer: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var syncTicker: Timer?
    private var currentTrackKey: String = ""
    private let logger = Logger(subsystem: "com.macisland.app", category: "LyricsManager")
    
    public init() {
        // Default to false (turned OFF)
        self.isLyricsEnabled = UserDefaults.standard.bool(forKey: "MacIsland.isLyricsEnabled")
        setupTrackObservation()
        startSyncTicker()
    }
    
    public func toggleLyrics() {
        isLyricsEnabled.toggle()
    }
    
    // MARK: - Track Observation
    private func setupTrackObservation() {
        MediaManager.shared.$currentItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newItem in
                self?.handleTrackChange(newItem)
            }
            .store(in: &cancellables)
    }
    
    private func handleTrackChange(_ item: MediaItem?) {
        guard let item = item, !item.title.isEmpty else {
            self.currentLyrics = nil
            self.currentLine = nil
            self.hasLyrics = false
            self.currentTrackKey = ""
            return
        }
        
        let trackKey = "\(item.title.lowercased())|\(item.artist.lowercased())"
        guard trackKey != currentTrackKey else {
            // Track is the same, update current active line based on playback time
            updateCurrentLine(for: item)
            return
        }
        
        self.noLyricsTimer?.cancel()
        self.showNoLyricsNotice = false
        self.currentTrackKey = trackKey
        self.currentLyrics = nil
        self.currentLine = nil
        self.hasLyrics = false
        
        fetchCurrentTrackLyrics()
    }
    
    public func fetchCurrentTrackLyrics() {
        guard let item = MediaManager.shared.currentItem, !item.title.isEmpty else { return }
        
        let title = item.title
        let artist = item.artist
        let album = item.album
        let duration = item.duration
        let expectedKey = "\(title.lowercased())|\(artist.lowercased())"
        
        self.isLoading = true
        
        Task {
            let result = await LyricsService.shared.fetchLyrics(
                title: title,
                artist: artist,
                album: album,
                duration: duration
            )
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                
                // Verify we are still on the same track before committing
                guard self.currentTrackKey == expectedKey else { return }
                
                if let result = result {
                    self.currentLyrics = result
                    self.hasLyrics = !result.lines.isEmpty || (result.plainLyrics != nil) || result.isInstrumental
                    self.updateCurrentLine(for: MediaManager.shared.currentItem)
                    self.logger.info("✅ [LyricsManager] Loaded lyrics with \(result.lines.count) lines for '\(title, privacy: .public)'")
                } else {
                    self.currentLyrics = nil
                    self.currentLine = nil
                    self.hasLyrics = false
                    self.logger.info("ℹ️ [LyricsManager] No lyrics found for '\(title, privacy: .public)'")
                    if self.isLyricsEnabled {
                        self.triggerNoLyricsNotice()
                    }
                }
            }
        }
    }
    
    /// Shows "No lyrics" text for 5 seconds, then gracefully reverts to the audio waveform pulse
    public func triggerNoLyricsNotice() {
        noLyricsTimer?.cancel()
        showNoLyricsNotice = true
        noLyricsTimer = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            guard !Task.isCancelled else { return }
            withAnimation(IslandAnimation.notchSpring) {
                self?.showNoLyricsNotice = false
            }
        }
    }
    
    // MARK: - Synchronized Line Tracker
    private func startSyncTicker() {
        // High-precision 80ms ticker (12.5 ticks/sec) for instantaneous line transitions
        let ticker = Timer(timeInterval: 0.08, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, self.isLyricsEnabled else { return }
                self.updateCurrentLine(for: MediaManager.shared.currentItem)
            }
        }
        RunLoop.main.add(ticker, forMode: .common)
        self.syncTicker = ticker
    }
    
    private func updateCurrentLine(for item: MediaItem?) {
        guard let item = item, let lyrics = currentLyrics else {
            if currentLine != nil {
                withAnimation(IslandAnimation.notchSpring) {
                    currentLine = nil
                }
            }
            return
        }
        
        if lyrics.isInstrumental {
            if currentLine?.text != "Instrumental" {
                withAnimation(IslandAnimation.notchSpring) {
                    currentLine = LyricLine(timestamp: 0, text: "Instrumental")
                }
            }
            return
        }
        
        guard !lyrics.lines.isEmpty else {
            if let plain = lyrics.plainLyrics, !plain.isEmpty {
                // If only plain lyrics exist, display non-synced note or first line
                if currentLine == nil {
                    let firstLine = plain.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? plain
                    withAnimation(IslandAnimation.notchSpring) {
                        currentLine = LyricLine(timestamp: 0, text: firstLine)
                    }
                }
            }
            return
        }
        
        // Natural vocal lead anticipation offset:
        // LRC timestamps specify the exact millisecond audio frequencies start.
        // Adding 400ms anticipation ensures the line appears right as the singer
        // begins the phrase, eliminating any perceived lag.
        let anticipationLead: TimeInterval = 0.40
        let currentTime = item.currentProgress() + anticipationLead
        let matchingLine = lyrics.line(at: currentTime)
        
        if currentLine != matchingLine {
            withAnimation(IslandAnimation.notchSpring) {
                currentLine = matchingLine
            }
        }
    }
    
    deinit {
        syncTicker?.invalidate()
        noLyricsTimer?.cancel()
    }
}
