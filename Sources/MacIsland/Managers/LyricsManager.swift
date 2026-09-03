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
            if isLyricsEnabled && currentLyrics == nil && !isLoading {
                fetchCurrentTrackLyrics()
            }
        }
    }
    
    @Published public private(set) var currentLyrics: SongLyrics?
    @Published public private(set) var currentLine: LyricLine?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var hasLyrics: Bool = false
    
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
                }
            }
        }
    }
    
    // MARK: - Synchronized Line Tracker
    private func startSyncTicker() {
        // Runs a timer every 0.3 seconds to check the active lyrics line smoothly
        let ticker = Timer(timeInterval: 0.3, repeats: true) { [weak self] _ in
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
            if currentLine != nil { currentLine = nil }
            return
        }
        
        if lyrics.isInstrumental {
            if currentLine?.text != "Instrumental" {
                currentLine = LyricLine(timestamp: 0, text: "Instrumental")
            }
            return
        }
        
        guard !lyrics.lines.isEmpty else {
            if let plain = lyrics.plainLyrics, !plain.isEmpty {
                // If only plain lyrics exist, display non-synced note or first line
                if currentLine == nil {
                    let firstLine = plain.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? plain
                    currentLine = LyricLine(timestamp: 0, text: firstLine)
                }
            }
            return
        }
        
        let currentTime = item.currentProgress()
        let matchingLine = lyrics.line(at: currentTime)
        
        if currentLine != matchingLine {
            currentLine = matchingLine
        }
    }
    
    deinit {
        syncTicker?.invalidate()
    }
}
