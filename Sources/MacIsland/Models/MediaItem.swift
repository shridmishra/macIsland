import Foundation
import AppKit

// MARK: - Media Item Model
// Represents the currently active media playing on macOS.
// Designed cleanly like a TypeScript interface/model:
//   interface MediaItem {
//     title: string;
//     artist: string;
//     album: string;
//     artworkData?: Data;
//     duration: number;
//     currentTime: number;
//     isPlaying: boolean;
//     application: string;
//   }
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
    }
    
    /// Estimated current elapsed time based on playback status and elapsed wall-clock seconds.
    public func currentProgress(at referenceDate: Date = Date()) -> TimeInterval {
        guard isPlaying else { return currentTime }
        let elapsedSinceUpdate = referenceDate.timeIntervalSince(lastUpdated)
        let estimated = currentTime + max(0, elapsedSinceUpdate)
        if duration > 0 {
            return min(estimated, duration)
        }
        return estimated
    }
    
    /// Normalized progress between 0.0 and 1.0.
    public func progressFraction(at referenceDate: Date = Date()) -> Double {
        guard duration > 0 else { return 0.0 }
        let current = currentProgress(at: referenceDate)
        return min(max(current / duration, 0.0), 1.0)
    }
    
    /// Formats a time interval (in seconds) into a readable "m:ss" string (e.g. 214s -> "3:34").
    public static func formatTime(_ seconds: TimeInterval) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else { return "0:00" }
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}
