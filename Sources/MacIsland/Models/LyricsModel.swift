import Foundation

// MARK: - Lyric Line
/// Represents a single synchronized lyric line with millisecond timestamp.
public struct LyricLine: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: TimeInterval
    public let text: String
    
    public init(id: UUID = UUID(), timestamp: TimeInterval, text: String) {
        self.id = id
        self.timestamp = timestamp
        self.text = text
    }
}

// MARK: - Song Lyrics
/// Complete lyrics container for a track, supporting both synchronized and plain lyrics.
public struct SongLyrics: Equatable, Sendable {
    public let trackName: String
    public let artistName: String
    public let duration: TimeInterval
    public let isInstrumental: Bool
    public let lines: [LyricLine]
    public let plainLyrics: String?
    
    public init(
        trackName: String,
        artistName: String,
        duration: TimeInterval = 0,
        isInstrumental: Bool = false,
        lines: [LyricLine] = [],
        plainLyrics: String? = nil
    ) {
        self.trackName = trackName
        self.artistName = artistName
        self.duration = duration
        self.isInstrumental = isInstrumental
        self.lines = lines
        self.plainLyrics = plainLyrics
    }
    
    /// Finds the synchronized lyric line currently active at the specified elapsed playback time.
    public func line(at currentTime: TimeInterval) -> LyricLine? {
        guard !lines.isEmpty else { return nil }
        return lines.last(where: { $0.timestamp <= currentTime })
    }
    
    /// Finds the upcoming next line after the currently active line.
    public func nextLine(at currentTime: TimeInterval) -> LyricLine? {
        guard !lines.isEmpty else { return nil }
        return lines.first(where: { $0.timestamp > currentTime })
    }
}
