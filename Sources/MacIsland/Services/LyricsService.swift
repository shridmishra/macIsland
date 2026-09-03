import Foundation
import os.log

// MARK: - LRCLIB API Response Model
private struct LRCLIBResponse: Decodable {
    let id: Int?
    let trackName: String?
    let artistName: String?
    let albumName: String?
    let duration: Double?
    let instrumental: Bool?
    let plainLyrics: String?
    let syncedLyrics: String?
}

// MARK: - LyricsService
/// Fetches synchronized and plain song lyrics from LRCLIB (https://lrclib.net).
/// LRCLIB is a free, open-source community lyrics database requiring zero API keys.
public actor LyricsService {
    public static let shared = LyricsService()
    
    private let session: URLSession
    private let logger = Logger(subsystem: "com.macisland.app", category: "LyricsService")
    
    // Actor-isolated thread-safe in-memory cache
    private var cache: [String: SongLyrics] = [:]
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8.0
        config.timeoutIntervalForResource = 15.0
        config.httpAdditionalHeaders = [
            "User-Agent": "MacIsland/1.0 (https://github.com/macisland)"
        ]
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Fetch API
    public func fetchLyrics(
        title: String,
        artist: String = "",
        album: String = "",
        duration: TimeInterval = 0
    ) async -> SongLyrics? {
        // Clean metadata for optimal search hits
        let (cleanTitle, cleanArtist) = cleanTrackInfo(title: title, artist: artist)
        guard !cleanTitle.isEmpty else { return nil }
        
        let cacheKey = "\(cleanTitle.lowercased())|\(cleanArtist.lowercased())"
        if let cached = cache[cacheKey] {
            return cached
        }
        
        logger.info("🔍 [LyricsService] Fetching lyrics for: '\(cleanTitle, privacy: .public)' by '\(cleanArtist, privacy: .public)'")
        
        // Step 1: Direct lookup via /api/get
        if let directLyrics = await fetchDirect(title: cleanTitle, artist: cleanArtist, album: album, duration: duration) {
            cache[cacheKey] = directLyrics
            return directLyrics
        }
        
        // Step 2: Fallback search via /api/search
        if let searchLyrics = await fetchViaSearch(title: cleanTitle, artist: cleanArtist, duration: duration) {
            cache[cacheKey] = searchLyrics
            return searchLyrics
        }
        
        return nil
    }
    
    // MARK: - Direct /api/get Request
    private func fetchDirect(
        title: String,
        artist: String,
        album: String,
        duration: TimeInterval
    ) async -> SongLyrics? {
        var components = URLComponents(string: "https://lrclib.net/api/get")
        var queryItems = [
            URLQueryItem(name: "track_name", value: title)
        ]
        if !artist.isEmpty {
            queryItems.append(URLQueryItem(name: "artist_name", value: artist))
        }
        if !album.isEmpty {
            queryItems.append(URLQueryItem(name: "album_name", value: album))
        }
        if duration > 0 {
            queryItems.append(URLQueryItem(name: "duration", value: String(Int(duration))))
        }
        components?.queryItems = queryItems
        
        guard let url = components?.url else { return nil }
        
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            let item = try JSONDecoder().decode(LRCLIBResponse.self, from: data)
            return convertResponse(item, fallbackTitle: title, fallbackArtist: artist)
        } catch {
            logger.debug("⚠️ [LyricsService] Direct get returned: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Fallback /api/search Request
    private func fetchViaSearch(
        title: String,
        artist: String,
        duration: TimeInterval
    ) async -> SongLyrics? {
        var components = URLComponents(string: "https://lrclib.net/api/search")
        var queryItems = [
            URLQueryItem(name: "track_name", value: title)
        ]
        if !artist.isEmpty {
            queryItems.append(URLQueryItem(name: "artist_name", value: artist))
        }
        components?.queryItems = queryItems
        
        guard let url = components?.url else { return nil }
        
        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            let list = try JSONDecoder().decode([LRCLIBResponse].self, from: data)
            guard !list.isEmpty else { return nil }
            
            // Prefer results that have syncedLyrics
            let syncedList = list.filter { ($0.syncedLyrics?.count ?? 0) > 0 }
            let candidateList = syncedList.isEmpty ? list : syncedList
            
            // Pick candidate closest in duration if available
            let bestCandidate: LRCLIBResponse
            if duration > 0 {
                bestCandidate = candidateList.min(by: { abs(($0.duration ?? 0) - duration) < abs(($1.duration ?? 0) - duration) }) ?? candidateList[0]
            } else {
                bestCandidate = candidateList[0]
            }
            
            return convertResponse(bestCandidate, fallbackTitle: title, fallbackArtist: artist)
        } catch {
            logger.debug("⚠️ [LyricsService] Search fallback returned: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Helper Converter
    private func convertResponse(_ item: LRCLIBResponse, fallbackTitle: String, fallbackArtist: String) -> SongLyrics {
        var parsedLines: [LyricLine] = []
        if let synced = item.syncedLyrics, !synced.isEmpty {
            parsedLines = Self.parseLRC(synced)
        }
        
        return SongLyrics(
            trackName: item.trackName ?? fallbackTitle,
            artistName: item.artistName ?? fallbackArtist,
            duration: item.duration ?? 0,
            isInstrumental: item.instrumental ?? false,
            lines: parsedLines,
            plainLyrics: item.plainLyrics
        )
    }
    
    // MARK: - LRC Parser
    /// Parses LRC formatted text (e.g. "[00:15.30] Lyric line text") into an array of LyricLine
    public nonisolated static func parseLRC(_ lrcString: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let rawLines = lrcString.components(separatedBy: .newlines)
        
        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("[") else { continue }
            
            var content = trimmed
            var timestamps: [TimeInterval] = []
            
            // Extract all bracketed timestamp tags e.g. [01:23.45]
            while content.hasPrefix("["), let closeIndex = content.firstIndex(of: "]") {
                let tag = String(content[content.index(after: content.startIndex)..<closeIndex])
                if let seconds = parseTimestamp(tag) {
                    timestamps.append(seconds)
                }
                content = String(content[content.index(after: closeIndex)...]).trimmingCharacters(in: .whitespaces)
            }
            
            let lyricText = content.trimmingCharacters(in: .whitespaces)
            if !timestamps.isEmpty {
                for ts in timestamps {
                    lines.append(LyricLine(timestamp: ts, text: lyricText))
                }
            }
        }
        
        return lines.sorted { $0.timestamp < $1.timestamp }
    }
    
    private nonisolated static func parseTimestamp(_ tag: String) -> TimeInterval? {
        let parts = tag.split(separator: ":")
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else {
            return nil
        }
        return (minutes * 60.0) + seconds
    }
    
    // MARK: - Metadata Cleaning
    /// Strips YouTube prefixes/suffixes, "(feat. ...)", "[Official Video]", and extracts "Artist - Title" patterns
    private nonisolated func cleanTrackInfo(title: String, artist: String) -> (title: String, artist: String) {
        var cleanTitle = title
        var cleanArtist = artist
        
        // If artist is empty and title has " - ", split e.g. "Queen - Bohemian Rhapsody"
        if cleanArtist.isEmpty && cleanTitle.contains(" - ") {
            let parts = cleanTitle.components(separatedBy: " - ")
            if parts.count >= 2 {
                cleanArtist = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                cleanTitle = parts.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Common video/remaster noise patterns
        let noisePatterns = [
            "\\(Official Video\\)",
            "\\(Official Music Video\\)",
            "\\(Official Audio\\)",
            "\\(Music Video\\)",
            "\\(Lyric Video\\)",
            "\\[Official Video\\]",
            "\\[Official Music Video\\]",
            "\\[Official Audio\\]",
            "\\[HD\\]",
            "\\[4K\\]",
            "\\(Live\\)",
            "\\(Remastered.*\\)",
            "- Remastered.*"
        ]
        
        for pattern in noisePatterns {
            cleanTitle = cleanTitle.replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: nil)
        }
        
        return (
            cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            cleanArtist.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
