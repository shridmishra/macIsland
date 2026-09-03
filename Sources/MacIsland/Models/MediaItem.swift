import Foundation
import AppKit

// MARK: - Media Item Model
// Represents the currently active media playing on macOS.
// Supports smart service detection (mapping Netflix, Prime Video, YouTube, Spotify, etc.)
// even when audio/video is playing inside web browsers like Brave, Chrome, Safari, or Arc.
public struct MediaItem: Equatable, Sendable {
    public let id: String
    public let title: String
    public let artist: String
    public let album: String
    public let artworkData: Data?
    public let duration: TimeInterval
    public let currentTime: TimeInterval
    public let isPlaying: Bool
    public let application: String
    public let bundleIdentifier: String?
    public let lastUpdated: Date
    
    /// Detected underlying streaming service (e.g. .primeVideo, .netflix, .youtube, .spotify)
    public let service: MediaService
    
    /// Clean title with service branding prefixes/suffixes removed
    public let displayTitle: String
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        artist: String = "",
        album: String = "",
        artworkData: Data? = nil,
        duration: TimeInterval = 0,
        currentTime: TimeInterval = 0,
        isPlaying: Bool = false,
        application: String = "Media",
        bundleIdentifier: String? = nil,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.artworkData = artworkData
        self.duration = duration
        self.currentTime = currentTime
        self.isPlaying = isPlaying
        self.application = application
        self.bundleIdentifier = bundleIdentifier
        self.lastUpdated = lastUpdated
        
        // Smart Service Detection & Title Cleaning
        let detection = MediaService.detect(
            title: title,
            album: album,
            artist: artist,
            bundleId: bundleIdentifier
        )
        self.service = detection.service
        self.displayTitle = detection.cleanedTitle
    }
    
    /// Returns true if this media originated from a web browser (Brave, Chrome, Safari, etc.)
    public var isBrowserMedia: Bool {
        guard let bId = bundleIdentifier else { return false }
        return MediaService.browserBundleIds.contains(bId)
    }
    
    /// The user-facing application name.
    /// If playing inside a browser (e.g. Brave), displays "Prime Video" or "Netflix" instead of the browser name.
    public var effectiveAppName: String {
        if service != .generic {
            return service.rawValue
        }
        return application
    }
    
    /// Estimated current elapsed time based on playback status and elapsed wall-clock seconds.
    public func currentProgress(at referenceDate: Date = Date()) -> TimeInterval {
        guard isPlaying else { return currentTime }
        let elapsedSinceUpdate = referenceDate.timeIntervalSince(lastUpdated)
        let estimated = currentTime + max(0, elapsedSinceUpdate)
        return duration > 0 ? min(estimated, duration) : estimated
    }
    
    /// Returns the fractional playback progress from 0.0 to 1.0.
    public func progressFraction(at referenceDate: Date = Date()) -> Double {
        guard duration > 0 else { return 0.0 }
        return max(0.0, min(1.0, currentProgress(at: referenceDate) / duration))
    }
    
    /// Formats seconds into MM:SS (or HH:MM:SS for long media).
    public static func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN, !seconds.isInfinite, seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
