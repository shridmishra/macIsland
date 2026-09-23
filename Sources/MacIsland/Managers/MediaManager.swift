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
    
    /// Briefly `true` when the active track changes, allowing views to show skeleton loading placeholders.
    @Published public private(set) var isTransitioning: Bool = false
    
    private let provider: NowPlayingProvider
    private var progressTicker: Timer?
    private var musicHealthTicker: Timer?
    private var activeMusicItem: MediaItem?
    private var activeNonMusicItem: MediaItem?
    private var lastSeekDate: Date?
    private var lastSeekTargetSeconds: Double?
    private var transitionWorkItem: DispatchWorkItem?
    private var teardownWorkItem: DispatchWorkItem?
    private let webArtworkCache = NSCache<NSString, NSData>()
    private let trackArtworkCache = NSCache<NSString, NSData>()
    private let logger = Logger(subsystem: "com.macisland.app", category: "MediaManager")
    
    public init(provider: NowPlayingProvider = MediaRemoteProvider()) {
        self.provider = provider
        setupProvider()
        startProgressTicker()
        startMusicHealthTicker()
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
            // When seeking or fast forwarding, audio stops playing for ~1 second while buffering
            // and MediaRemote temporarily drops metadata. Do not immediately destroy currentItem!
            if self.currentItem != nil {
                if self.teardownWorkItem == nil {
                    // Mark playback as paused while audio doesn't play for a sec
                    self.playbackState = .paused
                    
                    let isRecentSeek = (self.lastSeekDate != nil && Date().timeIntervalSince(self.lastSeekDate!) < 4.0)
                    let gracePeriod: TimeInterval = isRecentSeek ? 4.0 : 3.0
                    
                    let workItem = DispatchWorkItem { [weak self] in
                        guard let self = self else { return }
                        self.logger.info("🛑 [MediaManager] Teardown grace period elapsed — resetting media state.")
                        self.currentItem = nil
                        self.playbackState = .stopped
                        self.interpolatedProgress = 0.0
                        self.formattedCurrentTime = "0:00"
                        self.formattedDuration = "0:00"
                        self.formattedRemainingTime = "-0:00"
                        self.isTransitioning = false
                        self.transitionWorkItem?.cancel()
                        self.teardownWorkItem = nil
                    }
                    self.teardownWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + gracePeriod, execute: workItem)
                }
            } else {
                self.playbackState = .stopped
                self.isTransitioning = false
            }
            return
        }
        
        // Active item arrived — cancel teardown grace period
        if let pending = self.teardownWorkItem {
            pending.cancel()
            self.teardownWorkItem = nil
            self.logger.info("▶️ [MediaManager] Active track received, cancelled teardown timer.")
        }
        
        // Priority Arbitration: Always give 100% preference to music players over non-music media
        
        // 1. Check if native Apple Music or Spotify is playing
        if let nativeMusic = MediaRemoteProvider.checkNativeMusicActive() {
            let isIncomingMatchingNative = (newItem.bundleIdentifier == nativeMusic.bundleIdentifier &&
                (newItem.title == nativeMusic.title ||
                 newItem.title.lowercased().contains(nativeMusic.title.lowercased()) ||
                 nativeMusic.title.lowercased().contains(newItem.title.lowercased())))
            if !isIncomingMatchingNative {
                self.activeNonMusicItem = newItem.isMusicPlayer ? nil : newItem
                self.applyMusicItem(nativeMusic)
                return
            }
        }
        
        // 2. Check if a browser music tab (YouTube Music, Spotify Web, Apple Music Web, etc.) is active
        if newItem.title.isEmpty, let musicTab = BrowserServiceDetector.shared.queryActiveMusicTab(), musicTab.isPlaying {
            let isIncomingMatchingMusic = (musicTab.rawTitle != nil && !musicTab.rawTitle!.isEmpty && (
                newItem.title.lowercased().contains(musicTab.rawTitle!.lowercased()) ||
                musicTab.rawTitle!.lowercased().contains(newItem.title.lowercased())
            )) || (musicTab.url != nil && newItem.url != nil && newItem.url == musicTab.url)
            
            // If music tab is actively playing and incoming item is non-music (e.g. from X, Twitter, YouTube video)
            if !isIncomingMatchingMusic {
                self.activeNonMusicItem = newItem
                let musicItem = MediaItem(
                    id: "browser-music-\(musicTab.service.rawValue)-\(musicTab.rawTitle ?? musicTab.tabTitle ?? "track")",
                    title: musicTab.rawTitle ?? musicTab.tabTitle ?? "Music",
                    artist: musicTab.rawArtist ?? musicTab.service.displayName,
                    album: musicTab.rawAlbum ?? "",
                    duration: musicTab.duration ?? 0,
                    currentTime: musicTab.currentTime ?? 0,
                    isPlaying: true,
                    application: musicTab.appName ?? musicTab.service.displayName,
                    bundleIdentifier: musicTab.bundleIdentifier ?? "com.brave.Browser",
                    service: musicTab.service,
                    url: musicTab.url,
                    artworkUrl: musicTab.artworkUrl
                )
                self.applyMusicItem(musicItem)
                return
            }
        }
        
        // Detect a genuine track change (different song) vs periodic update to the same song
        let isSameSong: Bool
        let isTrackChange: Bool
        if let existing = self.currentItem {
            let newTitleClean = newItem.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let existingTitleClean = existing.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let newDisplayClean = newItem.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let existingDisplayClean = existing.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            if newTitleClean.isEmpty && !existingTitleClean.isEmpty {
                // Temporary blank title during seek/buffer — not a genuine track change!
                isSameSong = true
                isTrackChange = false
            } else if existing.id == newItem.id ||
                      (existingTitleClean == newTitleClean && !newTitleClean.isEmpty) ||
                      (existingDisplayClean == newDisplayClean && !newDisplayClean.isEmpty) ||
                      (!existingTitleClean.isEmpty && !newTitleClean.isEmpty && (existingTitleClean.contains(newTitleClean) || newTitleClean.contains(existingTitleClean))) ||
                      (!existingDisplayClean.isEmpty && !newDisplayClean.isEmpty && (existingDisplayClean.contains(newDisplayClean) || newDisplayClean.contains(existingDisplayClean))) {
                isSameSong = true
                isTrackChange = false
            } else {
                isSameSong = false
                isTrackChange = true
            }
        } else {
            isSameSong = false
            isTrackChange = true
        }
        
        // Robust artwork resolution: check incoming -> same track existing -> active music -> trackArtworkCache
        let resolvedArtwork: Data?
        if let incoming = newItem.artworkData, !incoming.isEmpty {
            resolvedArtwork = incoming
        } else if isSameSong, let existing = self.currentItem?.artworkData, !existing.isEmpty {
            resolvedArtwork = existing
        } else if isSameSong, let active = self.activeMusicItem?.artworkData, !active.isEmpty {
            resolvedArtwork = active
        } else if let cached = trackArtworkCache.object(forKey: newItem.title.lowercased() as NSString) as Data? {
            resolvedArtwork = cached
        } else if let cached = trackArtworkCache.object(forKey: newItem.displayTitle.lowercased() as NSString) as Data? {
            resolvedArtwork = cached
        } else {
            resolvedArtwork = newItem.artworkData
        }
        
        if isTrackChange && newItem.isPlaying {
            // Cancel any pending transition clear
            transitionWorkItem?.cancel()
            
            // Only show skeleton if artwork isn't immediately available
            let hasImmediateArtwork = (resolvedArtwork != nil && !(resolvedArtwork?.isEmpty ?? true))
            if !hasImmediateArtwork {
                self.isTransitioning = true
                
                let workItem = DispatchWorkItem { [weak self] in
                    self?.isTransitioning = false
                }
                self.transitionWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: workItem)
            } else {
                self.isTransitioning = false
            }
        } else {
            self.isTransitioning = false
        }
        
        // 1. Retain previously resolved service
        let resolvedService: MediaService
        if newItem.service != .generic {
            resolvedService = newItem.service
        } else if let cached = BrowserServiceDetector.shared.cachedService(bundleId: newItem.bundleIdentifier ?? "", trackTitle: newItem.title) {
            resolvedService = cached
        } else if let existing = self.currentItem, existing.title == newItem.title, existing.service != .generic {
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
                resolvedLastUpdated = Date()
            } else {
                resolvedCurrentTime = min(resolvedDuration > 0 ? resolvedDuration : expectedTime, expectedTime)
                resolvedLastUpdated = Date()
            }
        } else if let existing = self.currentItem, existing.title == newItem.title {
            let sameMedia = (existing.duration == 0 || newItem.duration == 0 || abs(existing.duration - newItem.duration) < 2.0)
            if !sameMedia {
                // Different media on the same tab/page (e.g. scrolling Twitter feed or playlist)
                resolvedCurrentTime = newItem.currentTime
                resolvedLastUpdated = Date()
            } else if newItem.isBrowserMedia {
                let currentEstimated = existing.currentProgress()
                // Tight clock synchronization: If user seeked or if drift exceeds 350ms,
                // synchronize directly to authoritative player time.
                // If drift is small (<= 350ms), maintain smooth continuous progress to eliminate micro-jitter.
                if newItem.currentTime > 0 && abs(newItem.currentTime - currentEstimated) > 0.35 {
                    resolvedCurrentTime = newItem.currentTime
                    resolvedLastUpdated = newItem.lastUpdated
                } else {
                    // Maintain smooth continuous wall-clock progress
                    resolvedCurrentTime = currentEstimated
                    resolvedLastUpdated = Date()
                }
            } else {
                // Native media player (Apple Music, Spotify, QuickTime)
                if !newItem.isPlaying {
                    resolvedCurrentTime = newItem.currentTime
                    resolvedLastUpdated = Date()
                } else {
                    let currentEstimated = existing.currentProgress()
                    // Tight clock synchronization: resync if drift exceeds 350ms
                    if abs(newItem.currentTime - currentEstimated) > 0.35 && newItem.currentTime > 0 {
                        resolvedCurrentTime = newItem.currentTime
                        resolvedLastUpdated = newItem.lastUpdated
                    } else {
                        resolvedCurrentTime = currentEstimated
                        resolvedLastUpdated = Date()
                    }
                }
            }
        } else {
            // First time this track arrives
            resolvedCurrentTime = newItem.currentTime
            resolvedLastUpdated = Date()
        }
        
        let resolvedTitle: String
        let newTitleClean = newItem.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !newTitleClean.isEmpty {
            resolvedTitle = newItem.title
        } else if let existingTitle = self.currentItem?.title, !existingTitle.isEmpty {
            resolvedTitle = existingTitle
        } else {
            resolvedTitle = ""
        }
        
        let resolvedArtist: String
        if !newItem.artist.isEmpty {
            resolvedArtist = newItem.artist
        } else if let existingArtist = self.currentItem?.artist, !existingArtist.isEmpty {
            resolvedArtist = existingArtist
        } else {
            resolvedArtist = ""
        }
        
        let resolvedAlbum: String
        if !newItem.album.isEmpty {
            resolvedAlbum = newItem.album
        } else if let existingAlbum = self.currentItem?.album, !existingAlbum.isEmpty {
            resolvedAlbum = existingAlbum
        } else {
            resolvedAlbum = ""
        }
        
        let mergedId = (isSameSong && self.currentItem != nil) ? self.currentItem!.id : newItem.id
        
        let mergedItem = MediaItem(
            id: mergedId,
            title: resolvedTitle,
            artist: resolvedArtist,
            album: resolvedAlbum,
            artworkData: resolvedArtwork,
            duration: resolvedDuration,
            currentTime: resolvedCurrentTime,
            isPlaying: newItem.isPlaying,
            application: newItem.application,
            bundleIdentifier: newItem.bundleIdentifier,
            lastUpdated: resolvedLastUpdated,
            service: resolvedService,
            url: self.currentItem?.url,
            artworkUrl: newItem.artworkUrl ?? self.currentItem?.artworkUrl
        )
        
        if let art = resolvedArtwork, !art.isEmpty {
            trackArtworkCache.setObject(art as NSData, forKey: resolvedTitle.lowercased() as NSString)
            trackArtworkCache.setObject(art as NSData, forKey: newItem.title.lowercased() as NSString)
            trackArtworkCache.setObject(art as NSData, forKey: newItem.displayTitle.lowercased() as NSString)
        }
        
        let incomingIsMusic = newItem.isMusicPlayer
        if incomingIsMusic {
            self.activeMusicItem = mergedItem
        } else {
            self.activeNonMusicItem = mergedItem
        }
        
        self.currentItem = mergedItem
        
        // Clear skeleton transition once artwork arrives
        if self.isTransitioning, let art = mergedItem.artworkData, !art.isEmpty {
            self.transitionWorkItem?.cancel()
            self.isTransitioning = false
        }
        
        logger.info("🎵 [MediaManager] current: \(mergedItem.title, privacy: .public) | effectiveApp: \(mergedItem.effectiveAppName, privacy: .public) | service: \(mergedItem.service.rawValue, privacy: .public)")
        self.playbackState = mergedItem.isPlaying ? .playing : .paused
        let progress = mergedItem.currentProgress()
        self.interpolatedProgress = mergedItem.progressFraction()
        self.formattedCurrentTime = MediaItem.formatTime(progress)
        self.formattedDuration = MediaItem.formatTime(mergedItem.duration)
        
        let remaining = max(0, mergedItem.duration - progress)
        self.formattedRemainingTime = mergedItem.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
        
        // 3. Query background tab detector for accurate service and video metadata when needed
        let needsBrowserDetection = isTrackChange ||
                                    mergedItem.service == .generic ||
                                    (mergedItem.artworkData == nil && (self.currentItem?.artworkData == nil)) ||
                                    mergedItem.duration == 0
        if mergedItem.isBrowserMedia && needsBrowserDetection {
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
                        let currentEstimated = self.currentItem?.currentProgress() ?? mergedItem.currentProgress()
                        
                        // MediaRemote is the primary source of truth for duration.
                        // Only fallback to detected duration if MediaRemote provided 0.
                        let finalDuration: Double
                        if mergedItem.duration > 0 {
                            finalDuration = mergedItem.duration
                        } else if let detDur = detected.duration, detDur > 0 {
                            finalDuration = detDur
                        } else {
                            finalDuration = self.currentItem?.duration ?? 0.0
                        }
                        
                        // Check if the DOM video matches the active track's duration.
                        // If detected.duration is completely different (e.g. 276s vs 55s),
                        // it is a different video on the page and its currentTime must be ignored!
                        let domMatchesTrack = (mergedItem.duration == 0) ||
                            (detected.duration != nil && abs(detected.duration! - finalDuration) < 2.0)
                        
                        let finalCurrentTime: Double
                        let finalLastUpdated: Date
                        
                        // Guard against stale background detection pulling progress backward after a seek
                        if let seekDate = self.lastSeekDate, let seekTarget = self.lastSeekTargetSeconds, Date().timeIntervalSince(seekDate) < 2.0 {
                            let elapsed = Date().timeIntervalSince(seekDate)
                            let expectedTime = seekTarget + (self.currentItem?.isPlaying == true ? elapsed : 0)
                            
                            if domMatchesTrack, let detTime = detected.currentTime, detTime > 0 && (abs(detTime - expectedTime) < 3.0 || detTime >= (seekTarget - 1.0)) {
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
                        } else if domMatchesTrack, let detTime = detected.currentTime, detTime > 0 {
                            // DOM video is the ground truth for browser playback.
                            // If drift is within 250ms, keep smooth wall-clock progress.
                            // If drift exceeds 250ms, synchronize directly to DOM video position.
                            if currentEstimated > 0 && abs(detTime - currentEstimated) <= 0.25 {
                                finalCurrentTime = currentEstimated
                                finalLastUpdated = Date()
                            } else {
                                finalCurrentTime = detTime
                                finalLastUpdated = Date()
                            }
                        } else {
                            finalCurrentTime = currentEstimated > 0 ? currentEstimated : (self.currentItem?.currentTime ?? mergedItem.currentTime)
                            finalLastUpdated = Date()
                        }
                        
                        // If detected tab is music, prioritize it and extract clean metadata
                        let isDetectedMusic = detected.isMusic || detected.service.isMusicService
                        let finalTitle: String
                        let finalArtist: String
                        let finalAlbum: String
                        
                        if isDetectedMusic, let rawT = detected.rawTitle, !rawT.isEmpty {
                            finalTitle = rawT
                            finalArtist = detected.rawArtist ?? (self.currentItem?.artist ?? mergedItem.artist)
                            finalAlbum = detected.rawAlbum ?? (self.currentItem?.album ?? mergedItem.album)
                        } else {
                            finalTitle = self.currentItem?.title ?? mergedItem.title
                            finalArtist = self.currentItem?.artist ?? mergedItem.artist
                            finalAlbum = self.currentItem?.album ?? mergedItem.album
                        }
                        
                        let serviceToUse = detected.service != .generic ? detected.service : (self.currentItem?.service ?? mergedItem.service)
                        
                        let detectedArtwork = self.currentItem?.artworkData ??
                                              mergedItem.artworkData ??
                                              self.activeMusicItem?.artworkData ??
                                              (self.trackArtworkCache.object(forKey: finalTitle.lowercased() as NSString) as Data?)
                        
                        if let art = detectedArtwork, !art.isEmpty {
                            self.trackArtworkCache.setObject(art as NSData, forKey: finalTitle.lowercased() as NSString)
                        }
                        
                        let finalIsPlaying = mergedItem.isPlaying || (self.currentItem?.isPlaying ?? false) || detected.isPlaying
                        
                        let updated = MediaItem(
                            id: mergedItem.id,
                            title: finalTitle,
                            artist: finalArtist,
                            album: finalAlbum,
                            artworkData: detectedArtwork,
                            duration: finalDuration,
                            currentTime: finalCurrentTime,
                            isPlaying: finalIsPlaying,
                            application: mergedItem.application,
                            bundleIdentifier: mergedItem.bundleIdentifier,
                            lastUpdated: finalLastUpdated,
                            service: serviceToUse,
                            url: detected.url ?? self.currentItem?.url ?? mergedItem.url,
                            artworkUrl: detected.artworkUrl
                        )
                        
                        if updated.isMusicPlayer {
                            self.activeMusicItem = updated
                        }
                        
                        self.currentItem = updated
                        self.playbackState = finalIsPlaying ? .playing : .paused
                        self.logger.info("🎯 [MediaManager:Detected] updated: \(updated.title, privacy: .public) | effectiveApp: \(updated.effectiveAppName, privacy: .public) | service: \(updated.service.rawValue, privacy: .public)")
                        let progress = updated.currentProgress()
                        self.interpolatedProgress = updated.progressFraction()
                        self.formattedCurrentTime = MediaItem.formatTime(progress)
                        self.formattedDuration = MediaItem.formatTime(updated.duration)
                        let remaining = max(0, updated.duration - progress)
                        self.formattedRemainingTime = updated.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
                        
                        if let artUrl = detected.artworkUrl, !artUrl.isEmpty {
                            self.loadWebArtworkIfNeeded(for: updated, artworkUrl: artUrl)
                        }
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
                // Skip progress updates when island is collapsed — progress bar is only visible when expanded
                guard WindowManager.shared.islandState.isExpanded else { return }
                
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
    
    // MARK: - Scriptable Browser Name Resolution
    private func resolveBrowserApplicationName(appName: String, bundleId: String?) -> String {
        let lowerBId = (bundleId ?? "").lowercased()
        let lowerApp = appName.lowercased()
        
        if lowerBId.contains("brave") || lowerApp.contains("brave") {
            return "Brave Browser"
        } else if lowerBId.contains("chrome") || lowerApp.contains("chrome") {
            return "Google Chrome"
        } else if lowerBId.contains("safari") || lowerApp.contains("safari") {
            return "Safari"
        } else if lowerBId.contains("edge") || lowerApp.contains("edge") {
            return "Microsoft Edge"
        } else if lowerBId.contains("arc") || lowerApp.contains("arc") {
            return "Arc"
        } else if lowerBId.contains("opera") || lowerApp.contains("opera") {
            return "Opera"
        }
        
        for running in NSWorkspace.shared.runningApplications {
            let rBId = running.bundleIdentifier?.lowercased() ?? ""
            if rBId.contains("brave") { return "Brave Browser" }
            if rBId.contains("chrome") { return "Google Chrome" }
            if rBId.contains("arc") { return "Arc" }
            if rBId.contains("edge") { return "Microsoft Edge" }
            if rBId.contains("safari") { return "Safari" }
        }
        return "Brave Browser"
    }
    
    // MARK: - Universal System Media Key Fallback
    nonisolated public static func sendSystemMediaKey(key: Int32) {
        func postKey(down: Bool) {
            let flags = down ? 0xa00 : 0xb00
            let data1 = Int((key << 16) | (Int32(down ? 0xa : 0xb) << 8))
            let ev = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(flags)),
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            )
            ev?.cgEvent?.post(tap: .cghidEventTap)
        }
        postKey(down: true)
        postKey(down: false)
    }
    
    // MARK: - Playback Actions
    public func togglePlayPause() {
        if let item = currentItem {
            let nextPlaying = !item.isPlaying
            playbackState = nextPlaying ? .playing : .paused
            
            let bundleId = item.bundleIdentifier ?? ""
            let appName = item.application
            
            // 1. Native Apple Music
            if bundleId == "com.apple.Music" || (appName.contains("Music") && !item.isBrowserMedia) {
                let script = "tell application \"Music\" to if running then playpause"
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var error: NSDictionary?
                    _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
                    if error != nil {
                        self?.provider.togglePlayPause()
                        Self.sendSystemMediaKey(key: 16)
                    }
                }
                return
            }
            
            // 2. Native Spotify
            if bundleId == "com.spotify.client" || (appName.contains("Spotify") && !item.isBrowserMedia) {
                let script = "tell application \"Spotify\" to if running then playpause"
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var error: NSDictionary?
                    _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
                    if error != nil {
                        self?.provider.togglePlayPause()
                        Self.sendSystemMediaKey(key: 16)
                    }
                }
                return
            }
            
            // 3. Web Browser Media (e.g. YouTube Music, Spotify Web, YouTube)
            if item.isBrowserMedia {
                let targetAppName = resolveBrowserApplicationName(appName: appName, bundleId: bundleId)
                let js = """
                (() => {
                    const u = window.location.href.toLowerCase();
                    const media = Array.from(document.querySelectorAll(\\\"video, audio\\\"));
                    const activeMedia = media.find(m => !m.paused && !m.ended) || media.find(m => m.currentTime > 0) || media[0];
                    const ytmBtn = document.querySelector(\\\"#play-pause-button, tp-yt-paper-icon-button#play-pause-button\\\");
                    if (ytmBtn && u.includes(\\\"music.youtube.com\\\")) { ytmBtn.click(); return \\\"ok\\\"; }
                    const ytBtn = document.querySelector(\\\".ytp-play-button\\\");
                    if (ytBtn && (u.includes(\\\"youtube.com\\\") || u.includes(\\\"youtu.be\\\"))) { ytBtn.click(); return \\\"ok\\\"; }
                    const spotBtn = document.querySelector(\\\"button[data-testid=\\\\\\\"control-button-playpause\\\\\\\"]\\\");
                    if (spotBtn && u.includes(\\\"spotify.com\\\")) { spotBtn.click(); return \\\"ok\\\"; }
                    const genBtn = document.querySelector(\\\".play-pause-button, button[aria-label=\\\"Play\\\"], button[aria-label=\\\"Pause\\\"]\\\");
                    if (genBtn) { genBtn.click(); return \\\"ok\\\"; }
                    if (activeMedia) {
                        if (activeMedia.paused) { activeMedia.play(); } else { activeMedia.pause(); }
                        return \\\"ok\\\";
                    }
                    return \\\"\\\";
                })()
                """
                
                let script: String
                if targetAppName == "Safari" || bundleId == "com.apple.Safari" {
                    script = """
                    tell application "Safari"
                        if running then
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        set res to do JavaScript "\(js)" in t
                                        if res is "ok" then return "ok"
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
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        tell t
                                            set res to execute javascript "\(js)"
                                            if res is "ok" then return "ok"
                                        end tell
                                    end try
                                end repeat
                            end repeat
                        end if
                    end tell
                    """
                }
                
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var error: NSDictionary?
                    let res = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue ?? ""
                    if res != "ok" {
                        self?.provider.togglePlayPause()
                        Self.sendSystemMediaKey(key: 16)
                    }
                }
                return
            }
        }
        
        provider.togglePlayPause()
        Self.sendSystemMediaKey(key: 16)
        if let item = currentItem {
            let nextPlaying = !item.isPlaying
            playbackState = nextPlaying ? .playing : .paused
        }
    }
    
    public func nextTrack() {
        teardownWorkItem?.cancel()
        teardownWorkItem = nil
        isTransitioning = true
        
        if let item = currentItem {
            let bundleId = item.bundleIdentifier ?? ""
            let appName = item.application
            
            // 1. Native Apple Music
            if bundleId == "com.apple.Music" || (appName.contains("Music") && !item.isBrowserMedia) {
                let script = "tell application \"Music\" to if running then next track"
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var error: NSDictionary?
                    _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
                    if error != nil {
                        self?.provider.nextTrack()
                        Self.sendSystemMediaKey(key: 19)
                    }
                }
                return
            }
            
            // 2. Native Spotify
            if bundleId == "com.spotify.client" || (appName.contains("Spotify") && !item.isBrowserMedia) {
                let script = "tell application \"Spotify\" to if running then next track"
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var error: NSDictionary?
                    _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
                    if error != nil {
                        self?.provider.nextTrack()
                        Self.sendSystemMediaKey(key: 19)
                    }
                }
                return
            }
            
            // 3. Web Browser Media (e.g. YouTube Music, Spotify Web)
            if item.isBrowserMedia {
                let targetAppName = resolveBrowserApplicationName(appName: appName, bundleId: bundleId)
                let js = """
                (() => {
                    const u = window.location.href.toLowerCase();
                    const ytmNext = document.querySelector(\\\".next-button, #next-button, tp-yt-paper-icon-button.next-button\\\");
                    if (ytmNext && u.includes(\\\"music.youtube.com\\\")) { ytmNext.click(); return \\\"ok\\\"; }
                    const ytNext = document.querySelector(\\\".ytp-next-button\\\");
                    if (ytNext && (u.includes(\\\"youtube.com\\\") || u.includes(\\\"youtu.be\\\"))) { ytNext.click(); return \\\"ok\\\"; }
                    const spotNext = document.querySelector(\\\"button[data-testid=\\\\\\\"control-button-skip-forward\\\\\\\"]\\\");
                    if (spotNext && u.includes(\\\"spotify.com\\\")) { spotNext.click(); return \\\"ok\\\"; }
                    const btn = document.querySelector(\\\"button[aria-label=\\\"Next track\\\"], button[aria-label=\\\"Next\\\"]\\\");
                    if (btn) { btn.click(); return \\\"ok\\\"; }
                    return \\\"\\\";
                })()
                """
                
                let script: String
                if targetAppName == "Safari" || bundleId == "com.apple.Safari" {
                    script = """
                    tell application "Safari"
                        if running then
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        set res to do JavaScript "\(js)" in t
                                        if res is "ok" then return "ok"
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
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        tell t
                                            set res to execute javascript "\(js)"
                                            if res is "ok" then return "ok"
                                        end tell
                                    end try
                                end repeat
                            end repeat
                        end if
                    end tell
                    """
                }
                
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var error: NSDictionary?
                    let res = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue ?? ""
                    if res != "ok" {
                        self?.provider.nextTrack()
                        Self.sendSystemMediaKey(key: 19)
                    }
                }
                return
            }
        }
        
        provider.nextTrack()
        Self.sendSystemMediaKey(key: 19)
    }
    
    public func previousTrack() {
        teardownWorkItem?.cancel()
        teardownWorkItem = nil
        isTransitioning = true
        
        if let item = currentItem {
            let bundleId = item.bundleIdentifier ?? ""
            let appName = item.application
            
            // 1. Native Apple Music
            if bundleId == "com.apple.Music" || (appName.contains("Music") && !item.isBrowserMedia) {
                let script = "tell application \"Music\" to if running then previous track"
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var error: NSDictionary?
                    _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
                    if error != nil {
                        self?.provider.previousTrack()
                        Self.sendSystemMediaKey(key: 20)
                    }
                }
                return
            }
            
            // 2. Native Spotify
            if bundleId == "com.spotify.client" || (appName.contains("Spotify") && !item.isBrowserMedia) {
                let script = "tell application \"Spotify\" to if running then previous track"
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var error: NSDictionary?
                    _ = NSAppleScript(source: script)?.executeAndReturnError(&error)
                    if error != nil {
                        self?.provider.previousTrack()
                        Self.sendSystemMediaKey(key: 20)
                    }
                }
                return
            }
            
            // 3. Web Browser Media (e.g. YouTube Music, Spotify Web)
            if item.isBrowserMedia {
                let targetAppName = resolveBrowserApplicationName(appName: appName, bundleId: bundleId)
                let js = """
                (() => {
                    const u = window.location.href.toLowerCase();
                    const ytmPrev = document.querySelector(\\\".previous-button, #previous-button, tp-yt-paper-icon-button.previous-button\\\");
                    if (ytmPrev && u.includes(\\\"music.youtube.com\\\")) { ytmPrev.click(); return \\\"ok\\\"; }
                    const spotPrev = document.querySelector(\\\"button[data-testid=\\\\\\\"control-button-skip-back\\\\\\\"]\\\");
                    if (spotPrev && u.includes(\\\"spotify.com\\\")) { spotPrev.click(); return \\\"ok\\\"; }
                    const btn = document.querySelector(\\\"button[aria-label=\\\"Previous track\\\"], button[aria-label=\\\"Previous\\\"]\\\");
                    if (btn) { btn.click(); return \\\"ok\\\"; }
                    return \\\"\\\";
                })()
                """
                
                let script: String
                if targetAppName == "Safari" || bundleId == "com.apple.Safari" {
                    script = """
                    tell application "Safari"
                        if running then
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        set res to do JavaScript "\(js)" in t
                                        if res is "ok" then return "ok"
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
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        tell t
                                            set res to execute javascript "\(js)"
                                            if res is "ok" then return "ok"
                                        end tell
                                    end try
                                end repeat
                            end repeat
                        end if
                    end tell
                    """
                }
                
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    var error: NSDictionary?
                    let res = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue ?? ""
                    if res != "ok" {
                        self?.provider.previousTrack()
                        Self.sendSystemMediaKey(key: 20)
                    }
                }
                return
            }
        }
        
        provider.previousTrack()
        Self.sendSystemMediaKey(key: 20)
    }
    
    // MARK: - Navigation Actions
    /// Navigates directly to the active browser tab or native media app
    public func openCurrentSource() {
        guard let item = currentItem else { return }
        MediaSourceNavigator.shared.openSource(for: item)
    }
    
    public func seek(toSeconds seconds: TimeInterval) {
        guard let item = currentItem, item.duration > 0 else { return }
        let fraction = max(0.0, min(1.0, seconds / item.duration))
        seek(to: fraction)
    }
    
    public func seek(to fraction: Double) {
        guard let item = currentItem, item.duration > 0 else { return }
        let targetSeconds = max(0, min(item.duration, fraction * item.duration))
        
        // 1. Set seek lock to prevent polling ticks from snapping back
        lastSeekDate = Date()
        lastSeekTargetSeconds = targetSeconds
        
        // Cancel any pending teardown immediately
        teardownWorkItem?.cancel()
        teardownWorkItem = nil
        
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
            service: item.service,
            url: item.url
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
    
    // MARK: - Music Player Arbitration & Artwork Helpers
    private func isMusicItemStillPlaying(_ item: MediaItem) -> Bool {
        guard item.isMusicPlayer else { return false }
        let bId = item.bundleIdentifier ?? ""
        
        // 1. Native Apple Music
        if bId == "com.apple.Music" {
            let script = "tell application \"Music\" to if running then return (player state is playing) as string"
            var error: NSDictionary?
            let res = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue?.lowercased() ?? ""
            return res == "true"
        }
        
        // 2. Native Spotify
        if bId == "com.spotify.client" {
            let script = "tell application \"Spotify\" to if running then return (player state is playing) as string"
            var error: NSDictionary?
            let res = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue?.lowercased() ?? ""
            return res == "true"
        }
        
        // 3. Web Browser Media (YouTube Music, Spotify Web, Apple Music Web, etc.)
        // Trust MediaRemote's authoritative playback state directly.
        // Never run blocking or failing AppleScripts that freeze the main thread and erroneously force pause.
        return item.isPlaying
    }
    
    private func startMusicHealthTicker() {
        musicHealthTicker?.invalidate()
        let timer = Timer(timeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.verifyMusicPrecedence()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        musicHealthTicker = timer
    }
    
    public func applyMusicItem(_ musicItem: MediaItem) {
        let isSameSong: Bool
        let isTrackChange: Bool
        if let existing = self.currentItem {
            let newTitleClean = musicItem.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let existingTitleClean = existing.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let newDisplayClean = musicItem.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let existingDisplayClean = existing.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            if newTitleClean.isEmpty && !existingTitleClean.isEmpty {
                isSameSong = true
                isTrackChange = false
            } else if existing.id == musicItem.id ||
                      (existingTitleClean == newTitleClean && !newTitleClean.isEmpty) ||
                      (existingDisplayClean == newDisplayClean && !newDisplayClean.isEmpty) ||
                      (!existingTitleClean.isEmpty && !newTitleClean.isEmpty && (existingTitleClean.contains(newTitleClean) || newTitleClean.contains(existingTitleClean))) ||
                      (!existingDisplayClean.isEmpty && !newDisplayClean.isEmpty && (existingDisplayClean.contains(newDisplayClean) || newDisplayClean.contains(existingDisplayClean))) {
                isSameSong = true
                isTrackChange = false
            } else {
                isSameSong = false
                isTrackChange = true
            }
        } else {
            isSameSong = false
            isTrackChange = true
        }
        
        let mergedArtwork: Data?
        if let incoming = musicItem.artworkData, !incoming.isEmpty {
            mergedArtwork = incoming
        } else if isSameSong, let existing = self.currentItem?.artworkData, !existing.isEmpty {
            mergedArtwork = existing
        } else if let cached = trackArtworkCache.object(forKey: musicItem.title.lowercased() as NSString) as Data? {
            mergedArtwork = cached
        } else if let cached = trackArtworkCache.object(forKey: musicItem.displayTitle.lowercased() as NSString) as Data? {
            mergedArtwork = cached
        } else {
            mergedArtwork = musicItem.artworkData
        }
        
        if let art = mergedArtwork, !art.isEmpty {
            trackArtworkCache.setObject(art as NSData, forKey: musicItem.title.lowercased() as NSString)
            trackArtworkCache.setObject(art as NSData, forKey: musicItem.displayTitle.lowercased() as NSString)
        }
        
        if isTrackChange && musicItem.isPlaying {
            transitionWorkItem?.cancel()
            let hasImmediateArtwork = (mergedArtwork != nil && !(mergedArtwork?.isEmpty ?? true))
            if !hasImmediateArtwork {
                self.isTransitioning = true
                let workItem = DispatchWorkItem { [weak self] in
                    self?.isTransitioning = false
                }
                self.transitionWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: workItem)
            } else {
                self.isTransitioning = false
            }
        } else {
            self.isTransitioning = false
        }
        
        let merged = MediaItem(
            id: musicItem.id,
            title: musicItem.title,
            artist: musicItem.artist,
            album: musicItem.album,
            artworkData: mergedArtwork,
            duration: musicItem.duration,
            currentTime: musicItem.currentTime,
            isPlaying: musicItem.isPlaying,
            application: musicItem.application,
            bundleIdentifier: musicItem.bundleIdentifier,
            lastUpdated: Date(),
            service: musicItem.service,
            url: musicItem.url,
            artworkUrl: musicItem.artworkUrl
        )
        
        self.activeMusicItem = merged
        self.currentItem = merged
        self.playbackState = merged.isPlaying ? .playing : .paused
        let progress = merged.currentProgress()
        self.interpolatedProgress = merged.progressFraction()
        self.formattedCurrentTime = MediaItem.formatTime(progress)
        self.formattedDuration = MediaItem.formatTime(merged.duration)
        let remaining = max(0, merged.duration - progress)
        self.formattedRemainingTime = merged.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
        
        if self.isTransitioning, let art = merged.artworkData, !art.isEmpty {
            self.transitionWorkItem?.cancel()
            self.isTransitioning = false
        }
        
        if let artUrl = merged.artworkUrl, !artUrl.isEmpty {
            self.loadWebArtworkIfNeeded(for: merged, artworkUrl: artUrl)
        }
    }
    
    private func verifyMusicPrecedence() {
        // 1. Check if native Apple Music or Spotify is actively playing
        if let nativeMusic = MediaRemoteProvider.checkNativeMusicActive() {
            let isAlreadyCurrent = (self.currentItem?.bundleIdentifier == nativeMusic.bundleIdentifier &&
                                    self.currentItem?.title == nativeMusic.title &&
                                    self.playbackState == .playing)
            if !isAlreadyCurrent {
                self.logger.info("🎵 [MediaManager:HealthTicker] Elevating active native music: \(nativeMusic.title)")
                self.applyMusicItem(nativeMusic)
            }
            return
        }
        
        // 2. Check if a browser music tab is active only if no media is currently known
        if self.currentItem == nil, let musicTab = BrowserServiceDetector.shared.queryActiveMusicTab() {
            let isAlreadyCurrent = (self.currentItem?.isMusicPlayer == true &&
                                    self.currentItem?.title == musicTab.rawTitle &&
                                    self.playbackState == (musicTab.isPlaying ? .playing : .paused))
            if !isAlreadyCurrent {
                let musicItem = MediaItem(
                    id: "browser-music-\(musicTab.service.rawValue)-\(musicTab.rawTitle ?? musicTab.tabTitle ?? "track")",
                    title: musicTab.rawTitle ?? musicTab.tabTitle ?? "Music",
                    artist: musicTab.rawArtist ?? musicTab.service.displayName,
                    album: musicTab.rawAlbum ?? "",
                    duration: musicTab.duration ?? 0,
                    currentTime: musicTab.currentTime ?? 0,
                    isPlaying: musicTab.isPlaying,
                    application: musicTab.appName ?? musicTab.service.displayName,
                    bundleIdentifier: musicTab.bundleIdentifier ?? "com.brave.Browser",
                    service: musicTab.service,
                    url: musicTab.url,
                    artworkUrl: musicTab.artworkUrl
                )
                self.logger.info("🎵 [MediaManager:HealthTicker] Elevating active browser music tab '\(musicItem.title)'")
                self.applyMusicItem(musicItem)
            }
            return
        }
        
        // 3. If current item is music that stopped playing, fall back to non-music if available
        if let current = self.currentItem, current.isMusicPlayer && self.playbackState == .playing {
            if !isMusicItemStillPlaying(current) {
                self.logger.info("🎵 [MediaManager:HealthTicker] Active music item '\(current.title)' stopped playing")
                if let nonMusic = self.activeNonMusicItem, nonMusic.isPlaying {
                    self.logger.info("🎵 [MediaManager:HealthTicker] Falling back to non-music media '\(nonMusic.title)'")
                    self.currentItem = nonMusic
                    self.playbackState = .playing
                    let progress = nonMusic.currentProgress()
                    self.interpolatedProgress = nonMusic.progressFraction()
                    self.formattedCurrentTime = MediaItem.formatTime(progress)
                    self.formattedDuration = MediaItem.formatTime(nonMusic.duration)
                    let remaining = max(0, nonMusic.duration - progress)
                    self.formattedRemainingTime = nonMusic.duration > 0 ? "-\(MediaItem.formatTime(remaining))" : "-0:00"
                } else {
                    self.playbackState = .paused
                }
            }
        }
    }
    
    private func loadWebArtworkIfNeeded(for item: MediaItem, artworkUrl: String?) {
        guard let urlString = artworkUrl, !urlString.isEmpty, let url = URL(string: urlString) else { return }
        
        let cacheKey = urlString
        if let cachedData = webArtworkCache.object(forKey: cacheKey as NSString) as Data? {
            trackArtworkCache.setObject(cachedData as NSData, forKey: item.title.lowercased() as NSString)
            trackArtworkCache.setObject(cachedData as NSData, forKey: item.displayTitle.lowercased() as NSString)
            
            if (self.currentItem?.id == item.id || (self.currentItem?.title == item.title && self.currentItem?.artist == item.artist)) &&
                (self.currentItem?.artworkData == nil || self.currentItem?.artworkData?.isEmpty == true) {
                let updated = MediaItem(
                    id: item.id,
                    title: item.title,
                    artist: item.artist,
                    album: item.album,
                    artworkData: cachedData,
                    duration: item.duration,
                    currentTime: item.currentTime,
                    isPlaying: item.isPlaying,
                    application: item.application,
                    bundleIdentifier: item.bundleIdentifier,
                    lastUpdated: item.lastUpdated,
                    service: item.service,
                    url: item.url,
                    artworkUrl: item.artworkUrl
                )
                if updated.isMusicPlayer {
                    self.activeMusicItem = updated
                }
                self.currentItem = updated
                self.isTransitioning = false
                self.transitionWorkItem?.cancel()
            }
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil, !data.isEmpty else { return }
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.webArtworkCache.setObject(data as NSData, forKey: cacheKey as NSString)
                self.trackArtworkCache.setObject(data as NSData, forKey: item.title.lowercased() as NSString)
                self.trackArtworkCache.setObject(data as NSData, forKey: item.displayTitle.lowercased() as NSString)
                let isMatch = (self.currentItem?.id == item.id) ||
                    (self.currentItem?.title == item.title && self.currentItem?.artist == item.artist)
                if isMatch && (self.currentItem?.artworkData == nil || self.currentItem?.artworkData?.isEmpty == true) {
                    let updated = MediaItem(
                        id: item.id,
                        title: item.title,
                        artist: item.artist,
                        album: item.album,
                        artworkData: data,
                        duration: item.duration,
                        currentTime: item.currentTime,
                        isPlaying: item.isPlaying,
                        application: item.application,
                        bundleIdentifier: item.bundleIdentifier,
                        lastUpdated: item.lastUpdated,
                        service: item.service,
                        url: item.url,
                        artworkUrl: item.artworkUrl
                    )
                    if updated.isMusicPlayer {
                        self.activeMusicItem = updated
                    }
                    self.currentItem = updated
                    self.isTransitioning = false
                    self.transitionWorkItem?.cancel()
                    self.logger.info("🖼️ [MediaManager] Loaded and applied web artwork for '\(item.title)'")
                }
            }
        }.resume()
    }
    
    deinit {
        progressTicker?.invalidate()
        musicHealthTicker?.invalidate()
        transitionWorkItem?.cancel()
        teardownWorkItem?.cancel()
        provider.stopObserving()
    }
}
