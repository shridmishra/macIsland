import Foundation

// MARK: - Lyric Line
/// Represents a single synchronized lyric line with millisecond timestamp.
/// Maintains both the original source text and the phonetic Romanized Latin script.
public struct LyricLine: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: TimeInterval
    public let text: String
    public let originalText: String
    public let romanizedText: String
    
    public init(
        id: UUID = UUID(),
        timestamp: TimeInterval,
        text: String,
        originalText: String? = nil,
        romanizedText: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        let orig = originalText ?? text
        let roman = romanizedText ?? (LyricsRomanizer.shared.containsNonLatin(orig) ? LyricsRomanizer.shared.romanize(orig) : orig)
        self.originalText = orig
        self.romanizedText = roman
        self.text = text
    }
    
    /// Returns a copy of this line displaying either romanized or original text.
    public func withRomanization(_ romanized: Bool) -> LyricLine {
        return LyricLine(
            id: id,
            timestamp: timestamp,
            text: romanized ? romanizedText : originalText,
            originalText: originalText,
            romanizedText: romanizedText
        )
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
    public let romanizedPlainLyrics: String?
    
    public init(
        trackName: String,
        artistName: String,
        duration: TimeInterval = 0,
        isInstrumental: Bool = false,
        lines: [LyricLine] = [],
        plainLyrics: String? = nil,
        romanizedPlainLyrics: String? = nil
    ) {
        self.trackName = trackName
        self.artistName = artistName
        self.duration = duration
        self.isInstrumental = isInstrumental
        self.lines = lines
        self.plainLyrics = plainLyrics
        self.romanizedPlainLyrics = romanizedPlainLyrics
    }
    
    /// Returns an instance where all lines are updated to match the romanization preference.
    public func withRomanization(_ romanized: Bool) -> SongLyrics {
        let updatedLines = lines.map { $0.withRomanization(romanized) }
        return SongLyrics(
            trackName: trackName,
            artistName: artistName,
            duration: duration,
            isInstrumental: isInstrumental,
            lines: updatedLines,
            plainLyrics: plainLyrics,
            romanizedPlainLyrics: romanizedPlainLyrics
        )
    }
    
    /// Returns plain lyrics formatted according to the romanization preference.
    public func displayPlainLyrics(romanized: Bool) -> String? {
        if romanized, let roman = romanizedPlainLyrics, !roman.isEmpty {
            return roman
        }
        return plainLyrics
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
