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
                    triggerNoLyricsNotice(hasPlainLyrics: currentLyrics?.plainLyrics != nil)
                }
            } else {
                noLyricsTimer?.cancel()
                showNoLyricsNotice = false
            }
        }
    }
    
    /// Romanization toggle state: defaults to true (Latin script in notch for Urdu, Punjabi, etc.)
    @Published public var isRomanizationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isRomanizationEnabled, forKey: "MacIsland.isRomanizationEnabled")
            applyRomanizationPreference()
        }
    }
    
    /// User-calibrated anticipation lead offset in seconds.
    /// Defaults to 0.6 seconds so the line appears a bit ahead of vocals for comfortable reading.
    @Published public var syncOffset: Double {
        didSet {
            UserDefaults.standard.set(syncOffset, forKey: "MacIsland.lyricsSyncOffset")
            updateCurrentLine(for: MediaManager.shared.currentItem)
        }
    }
    
    @Published public private(set) var currentLyrics: SongLyrics?
    @Published public private(set) var currentLine: LyricLine?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var hasLyrics: Bool = false
    @Published public private(set) var showNoLyricsNotice: Bool = false
    @Published public private(set) var noLyricsNoticeText: String = "No lyrics"
    
    private var noLyricsTimer: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var syncTicker: Timer?
    private var currentTrackKey: String = ""
    private let logger = Logger(subsystem: "com.macisland.app", category: "LyricsManager")
    
    public init() {
        // Default to false (turned OFF)
        self.isLyricsEnabled = UserDefaults.standard.bool(forKey: "MacIsland.isLyricsEnabled")
        // Default to true (turned ON for Latin script lyrics in notch)
        if UserDefaults.standard.object(forKey: "MacIsland.isRomanizationEnabled") == nil {
            self.isRomanizationEnabled = true
        } else {
            self.isRomanizationEnabled = UserDefaults.standard.bool(forKey: "MacIsland.isRomanizationEnabled")
        }
        // Default to 0.6s (a bit ahead for comfortable reading before vocals start)
        if let storedOffset = UserDefaults.standard.object(forKey: "MacIsland.lyricsSyncOffset") as? Double {
            self.syncOffset = storedOffset
        } else {
            self.syncOffset = 0.6
        }
        setupTrackObservation()
        startSyncTicker()
    }
    
    public func toggleLyrics() {
        isLyricsEnabled.toggle()
    }
    
    public func toggleRomanization() {
        isRomanizationEnabled.toggle()
    }
    
    public func setSyncOffset(_ offset: Double) {
        self.syncOffset = max(-1.5, min(4.0, offset))
    }
    
    public func nudgeSyncOffset(by delta: Double) {
        self.syncOffset = max(-1.5, min(4.0, (round((syncOffset + delta) * 10) / 10.0)))
    }
    
    private func applyRomanizationPreference() {
        guard let lyrics = currentLyrics else { return }
        let updated = lyrics.withRomanization(isRomanizationEnabled)
        self.currentLyrics = updated
        if let line = currentLine {
            self.currentLine = line.withRomanization(isRomanizationEnabled)
        }
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
            self.noLyricsTimer?.cancel()
            self.showNoLyricsNotice = false
            self.currentLyrics = nil
            self.currentLine = nil
            self.hasLyrics = false
            self.currentTrackKey = ""
            return
        }
        
        let (cleanTitle, cleanArtist) = LyricsService.cleanTrackInfo(title: item.title, artist: item.artist)
        let trackKey = "\(cleanTitle.lowercased())|\(cleanArtist.lowercased())"
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
        guard let item = MediaManager.shared.currentItem, !item.title.isEmpty else {
            self.isLoading = false
            return
        }
        
        let title = item.title
        let artist = item.artist
        let album = item.album
        let duration = item.duration
        let (cleanTitle, cleanArtist) = LyricsService.cleanTrackInfo(title: title, artist: artist)
        let expectedKey = "\(cleanTitle.lowercased())|\(cleanArtist.lowercased())"
        
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
                    let configuredLyrics = result.withRomanization(self.isRomanizationEnabled)
                    self.currentLyrics = configuredLyrics
                    let hasSynced = !configuredLyrics.lines.isEmpty || configuredLyrics.isInstrumental
                    self.hasLyrics = hasSynced
                    self.updateCurrentLine(for: MediaManager.shared.currentItem)
                    if hasSynced {
                        self.logger.info("✅ [LyricsManager] Loaded lyrics with \(configuredLyrics.lines.count) lines for '\(title, privacy: .public)'")
                    } else {
                        self.logger.info("ℹ️ [LyricsManager] Track has plain lyrics only (no timestamps) for '\(title, privacy: .public)'")
                        if self.isLyricsEnabled && !(MediaManager.shared.currentItem?.service.isVideoService ?? false) {
                            self.triggerNoLyricsNotice(hasPlainLyrics: configuredLyrics.plainLyrics != nil)
                        }
                    }
                } else {
                    self.currentLyrics = nil
                    self.currentLine = nil
                    self.hasLyrics = false
                    self.logger.info("ℹ️ [LyricsManager] No lyrics found for '\(title, privacy: .public)'")
                    if self.isLyricsEnabled && !(MediaManager.shared.currentItem?.service.isVideoService ?? false) {
                        self.triggerNoLyricsNotice(hasPlainLyrics: false)
                    }
                }
            }
        }
    }
    
    /// Shows "No lyrics" or "Lyrics not synced" for 5 seconds, then gracefully reverts to the audio waveform pulse
    public func triggerNoLyricsNotice(hasPlainLyrics: Bool = false) {
        guard !(MediaManager.shared.currentItem?.service.isVideoService ?? false) else { return }
        noLyricsTimer?.cancel()
        noLyricsNoticeText = hasPlainLyrics ? "Lyrics not synced" : "No lyrics"
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
        // 250ms ticker (4 ticks/sec) for responsive line transitions with minimal battery impact
        let ticker = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.updateCurrentLine(for: MediaManager.shared.currentItem)
            }
        }
        RunLoop.main.add(ticker, forMode: .common)
        self.syncTicker = ticker
    }
    
    private func updateCurrentLine(for item: MediaItem?) {
        guard let item = item, let lyrics = currentLyrics else {
            if currentLine != nil {
                currentLine = nil
            }
            return
        }
        
        if lyrics.isInstrumental {
            if currentLine?.text != "Instrumental" {
                currentLine = LyricLine(timestamp: 0, text: "Instrumental")
            }
            return
        }
        
        guard !lyrics.lines.isEmpty else {
            if currentLine != nil {
                currentLine = nil
            }
            return
        }
        
        let currentTime = item.currentProgress() + syncOffset
        let matchingLine = lyrics.line(at: currentTime)
        
        if currentLine != matchingLine {
            currentLine = matchingLine
        }
    }
    
    deinit {
        syncTicker?.invalidate()
        noLyricsTimer?.cancel()
    }
}
