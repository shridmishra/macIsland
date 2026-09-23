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
        let (cleanTitle, cleanArtist) = Self.cleanTrackInfo(title: title, artist: artist)
        guard !cleanTitle.isEmpty else { return nil }
        
        let normalizedArtist = Self.normalizeArtistName(cleanArtist)
        let primaryArtist = Self.primaryArtistName(cleanArtist)
        let primaryNormalized = Self.normalizeArtistName(primaryArtist)
        let cleanAlbum = Self.cleanAlbumName(album)
        
        let cacheKey = "\(cleanTitle.lowercased())|\(normalizedArtist.lowercased())"
        if let cached = cache[cacheKey] {
            return cached
        }
        
        logger.info("🔍 [LyricsService] Fetching lyrics for: '\(cleanTitle, privacy: .public)' by '\(cleanArtist, privacy: .public)' (norm: '\(normalizedArtist, privacy: .public)')")
        
        // Build list of artist variants to try in priority order:
        // 1. Normalized artist without initial dots (e.g. "KK" or "AR Rahman" - highest quality in LRCLIB)
        // 2. Original clean artist (if different)
        // 3. Primary artist if multi-artist
        // 4. Primary normalized
        var artistVariants: [String] = []
        for candidate in [normalizedArtist, cleanArtist, primaryNormalized, primaryArtist] {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !artistVariants.contains(trimmed) {
                artistVariants.append(trimmed)
            }
        }
        if artistVariants.isEmpty {
            artistVariants.append("")
        }
        
        // Step 1: Direct lookup via /api/get across artist variants
        for art in artistVariants {
            if let directLyrics = await fetchDirect(title: cleanTitle, artist: art, album: cleanAlbum, duration: duration) {
                // Verify candidate has synchronized lyrics if available
                if !directLyrics.lines.isEmpty {
                    cache[cacheKey] = directLyrics
                    return directLyrics
                }
            }
        }
        
        // Step 2: Fallback search via /api/search across artist variants
        for art in artistVariants {
            if let searchLyrics = await fetchViaSearch(title: cleanTitle, artist: art, duration: duration, expectedArtistVariants: artistVariants) {
                if !searchLyrics.lines.isEmpty {
                    cache[cacheKey] = searchLyrics
                    return searchLyrics
                }
            }
        }
        
        // Step 3: Broad search by title only with duration scoring and strict artist validation
        if let titleOnlyLyrics = await fetchViaSearch(title: cleanTitle, artist: "", duration: duration, expectedArtistVariants: artistVariants) {
            cache[cacheKey] = titleOnlyLyrics
            return titleOnlyLyrics
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
            return await convertResponse(item, fallbackTitle: title, fallbackArtist: artist)
        } catch {
            logger.debug("⚠️ [LyricsService] Direct get returned: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Fallback /api/search Request
    private func fetchViaSearch(
        title: String,
        artist: String,
        duration: TimeInterval,
        expectedArtistVariants: [String] = []
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
            
            // Filter candidates by artist matching if expected artist variants are provided
            let candidateList: [LRCLIBResponse]
            if !expectedArtistVariants.isEmpty && expectedArtistVariants.contains(where: { !$0.isEmpty }) {
                let matched = list.filter { item in
                    guard let candArtist = item.artistName else { return false }
                    return Self.isArtistMatch(candidate: candArtist, expectedVariants: expectedArtistVariants)
                }
                guard !matched.isEmpty else { return nil }
                candidateList = matched
            } else {
                candidateList = list
            }
            
            // Prefer results that have syncedLyrics
            let syncedList = candidateList.filter { ($0.syncedLyrics?.count ?? 0) > 0 }
            let pool = syncedList.isEmpty ? candidateList : syncedList
            
            // Pick candidate closest in duration with most complete synced lyrics
            let bestCandidate: LRCLIBResponse
            if duration > 0 {
                guard let closest = pool.min(by: { a, b in
                    let diffA = abs((a.duration ?? 0) - duration)
                    let diffB = abs((b.duration ?? 0) - duration)
                    if abs(diffA - diffB) < 1.5 {
                        return (a.syncedLyrics?.count ?? 0) > (b.syncedLyrics?.count ?? 0)
                    }
                    return diffA < diffB
                }) else { return nil }
                
                // If duration difference is excessive (> 8 seconds), reject candidate to prevent wrong track selection
                if let d = closest.duration, d > 0, abs(d - duration) > 8.0 {
                    return nil
                }
                bestCandidate = closest
            } else {
                bestCandidate = pool.max(by: { ($0.syncedLyrics?.count ?? 0) < ($1.syncedLyrics?.count ?? 0) }) ?? pool[0]
            }
            
            return await convertResponse(bestCandidate, fallbackTitle: title, fallbackArtist: bestCandidate.artistName ?? artist)
        } catch {
            logger.debug("⚠️ [LyricsService] Search fallback returned: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Helper Converter
    private func convertResponse(_ item: LRCLIBResponse, fallbackTitle: String, fallbackArtist: String) async -> SongLyrics {
        var parsedLines: [LyricLine] = []
        if let synced = item.syncedLyrics, !synced.isEmpty {
            parsedLines = await Self.parseLRCAsync(synced)
        }
        
        var romanizedPlain: String? = nil
        if let plain = item.plainLyrics {
            if LyricsRomanizer.shared.containsNonLatin(plain) {
                let lines = plain.components(separatedBy: .newlines)
                let roman = await LyricsRomanizer.shared.romanizeBatch(lines)
                romanizedPlain = roman.joined(separator: "\n")
            } else {
                romanizedPlain = plain
            }
        }
        
        return SongLyrics(
            trackName: item.trackName ?? fallbackTitle,
            artistName: item.artistName ?? fallbackArtist,
            duration: item.duration ?? 0,
            isInstrumental: item.instrumental ?? false,
            lines: parsedLines,
            plainLyrics: item.plainLyrics,
            romanizedPlainLyrics: romanizedPlain
        )
    }
    
    // MARK: - Lyric Text Sanitization
    public nonisolated static func sanitizeLyricText(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let musicGlyphs: CharacterSet = CharacterSet(charactersIn: "♪♫♬♩🎶\u{266a}\u{266b}\u{2669}")
        cleaned = cleaned.trimmingCharacters(in: musicGlyphs).trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
    }
    
    public nonisolated static func isCleanLyricText(_ text: String) -> Bool {
        let cleaned = sanitizeLyricText(text)
        if cleaned.isEmpty { return false }
        let lower = cleaned.lowercased()
        if lower == "(instrumental)" || lower == "[instrumental]" || lower == "(music)" || lower == "[music]" || lower == "instrumental" {
            return false
        }
        return true
    }

    // MARK: - LRC Parser
    /// Parses LRC formatted text with neural batch transliteration for full accuracy & vowel restoration.
    /// Retains empty timestamp lines (e.g. [01:09.16]) as vocal pause / instrumental markers.
    public nonisolated static func parseLRCAsync(_ lrcString: String) async -> [LyricLine] {
        var rawEntries: [(timestamp: TimeInterval, text: String)] = []
        let rawLines = lrcString.components(separatedBy: .newlines)
        
        var fileOffset: TimeInterval = 0.0
        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if let off = parseOffsetTag(trimmed) {
                fileOffset = off
                break
            }
        }
        
        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("[") else { continue }
            
            var content = trimmed
            var timestamps: [TimeInterval] = []
            
            while content.hasPrefix("["), let closeIndex = content.firstIndex(of: "]") {
                let tag = String(content[content.index(after: content.startIndex)..<closeIndex])
                if let seconds = parseTimestamp(tag) {
                    timestamps.append(max(0.0, seconds + fileOffset))
                }
                content = String(content[content.index(after: closeIndex)...]).trimmingCharacters(in: .whitespaces)
            }
            
            let rawText = content.trimmingCharacters(in: .whitespaces)
            let lower = rawText.lowercased()
            let isInstrumentalTag = lower == "(instrumental)" || lower == "[instrumental]" || lower == "(music)" || lower == "[music]" || lower == "instrumental"
            let lyricText = isInstrumentalTag ? "" : sanitizeLyricText(rawText)
            
            if !timestamps.isEmpty {
                for ts in timestamps {
                    rawEntries.append((timestamp: ts, text: lyricText))
                }
            }
        }
        
        guard !rawEntries.isEmpty else { return [] }
        
        let nonBlankIndices = rawEntries.indices.filter { !rawEntries[$0].text.isEmpty }
        let nonBlankTexts = nonBlankIndices.map { rawEntries[$0].text }
        let romanizedTexts = await LyricsRomanizer.shared.romanizeBatch(nonBlankTexts)
        
        var romanizedMap: [Int: String] = [:]
        for (idx, originalIdx) in nonBlankIndices.enumerated() {
            romanizedMap[originalIdx] = (idx < romanizedTexts.count) ? romanizedTexts[idx] : nonBlankTexts[idx]
        }
        
        var lines: [LyricLine] = []
        for (i, entry) in rawEntries.enumerated() {
            let orig = entry.text
            let roman: String
            if orig.isEmpty {
                roman = ""
            } else {
                roman = romanizedMap[i] ?? (LyricsRomanizer.shared.containsNonLatin(orig) ? LyricsRomanizer.shared.romanize(orig) : orig)
            }
            lines.append(LyricLine(timestamp: entry.timestamp, text: roman, originalText: orig, romanizedText: roman))
        }
        
        return lines.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Synchronous fallback LRC parser
    public nonisolated static func parseLRC(_ lrcString: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let rawLines = lrcString.components(separatedBy: .newlines)
        
        var fileOffset: TimeInterval = 0.0
        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            if let off = parseOffsetTag(trimmed) {
                fileOffset = off
                break
            }
        }
        
        for rawLine in rawLines {
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("[") else { continue }
            
            var content = trimmed
            var timestamps: [TimeInterval] = []
            
            // Extract all bracketed timestamp tags e.g. [01:23.45]
            while content.hasPrefix("["), let closeIndex = content.firstIndex(of: "]") {
                let tag = String(content[content.index(after: content.startIndex)..<closeIndex])
                if let seconds = parseTimestamp(tag) {
                    timestamps.append(max(0.0, seconds + fileOffset))
                }
                content = String(content[content.index(after: closeIndex)...]).trimmingCharacters(in: .whitespaces)
            }
            
            let rawText = content.trimmingCharacters(in: .whitespaces)
            let lower = rawText.lowercased()
            let isInstrumentalTag = lower == "(instrumental)" || lower == "[instrumental]" || lower == "(music)" || lower == "[music]" || lower == "instrumental"
            let lyricText = isInstrumentalTag ? "" : sanitizeLyricText(rawText)
            
            if !timestamps.isEmpty {
                let romanized: String
                if lyricText.isEmpty {
                    romanized = ""
                } else {
                    romanized = LyricsRomanizer.shared.containsNonLatin(lyricText) ? LyricsRomanizer.shared.romanize(lyricText) : lyricText
                }
                for ts in timestamps {
                    lines.append(LyricLine(timestamp: ts, text: romanized, originalText: lyricText, romanizedText: romanized))
                }
            }
        }
        
        return lines.sorted { $0.timestamp < $1.timestamp }
    }
    
    private nonisolated static func parseTimestamp(_ tag: String) -> TimeInterval? {
        let parts = tag.split(separator: ":")
        if parts.count == 2 {
            guard let minutes = Double(parts[0]),
                  let seconds = Double(parts[1]) else {
                return nil
            }
            return (minutes * 60.0) + seconds
        } else if parts.count == 3 {
            guard let hours = Double(parts[0]),
                  let minutes = Double(parts[1]),
                  let seconds = Double(parts[2]) else {
                return nil
            }
            return (hours * 3600.0) + (minutes * 60.0) + seconds
        }
        return nil
    }
    
    private nonisolated static func parseOffsetTag(_ line: String) -> TimeInterval? {
        let lower = line.lowercased()
        guard lower.hasPrefix("[offset:"), let closeIndex = lower.firstIndex(of: "]") else { return nil }
        let numStr = lower[lower.index(lower.startIndex, offsetBy: 8)..<closeIndex].trimmingCharacters(in: .whitespaces)
        if let ms = Double(numStr) {
            return ms / 1000.0
        }
        return nil
    }
    
    // MARK: - Metadata Cleaning
    /// Strips YouTube prefixes/suffixes, "(feat. ...)", "[Official Video]", and extracts "Artist - Title" patterns
    public nonisolated static func cleanTrackInfo(title: String, artist: String) -> (title: String, artist: String) {
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
            "\\(Lyrical Video\\)",
            "\\[Official Video\\]",
            "\\[Official Music Video\\]",
            "\\[Official Audio\\]",
            "\\[Lyric Video\\]",
            "\\[Lyrical Video\\]",
            "\\(Full Song\\)",
            "\\[Full Song\\]",
            "\\(Audio\\)",
            "\\[Audio\\]",
            "\\|.*",
            "\\[HD\\]",
            "\\[4K\\]",
            "\\(Live\\)",
            "\\(Remastered.*\\)",
            "- Remastered.*",
            "\\(From [\"“].*?[\"”]\\)",
            "\\[From [\"“].*?[\"”]\\]"
        ]
        
        for pattern in noisePatterns {
            cleanTitle = cleanTitle.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive], range: nil)
        }
        
        let trimmedTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "-|:/ "))
        
        return (
            trimmedTitle,
            cleanArtist.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    /// Normalizes artist initials by stripping periods (e.g. "K.K." -> "KK", "A.R. Rahman" -> "AR Rahman")
    public nonisolated static func normalizeArtistName(_ name: String) -> String {
        var cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "(?<=\\b[A-Za-z])\\.", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extracts the primary artist when comma, ampersand, or "feat" is used (e.g. "Himesh Reshammiya, KK, Shaan" -> "Himesh Reshammiya")
    public nonisolated static func primaryArtistName(_ name: String) -> String {
        let separators = [",", ";", "/", " feat. ", " feat ", " ft. ", " ft ", " & ", " and "]
        var first = name
        for sep in separators {
            if let range = first.range(of: sep, options: .caseInsensitive) {
                first = String(first[..<range.lowerBound])
            }
        }
        return first.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Checks if a candidate artist name matches any expected artist name variants.
    /// Supports exact matching, substring inclusion, and token overlap (ignoring common noise words like 'feat', 'and', 'the').
    public nonisolated static func isArtistMatch(candidate: String, expectedVariants: [String]) -> Bool {
        let nonEmpties = expectedVariants.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if nonEmpties.isEmpty { return true }
        
        let candLower = candidate.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if candLower.isEmpty { return false }
        
        for exp in nonEmpties {
            let expLower = exp.lowercased()
            if candLower == expLower || candLower.contains(expLower) || expLower.contains(candLower) {
                return true
            }
            
            let expWords = Set(expLower.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init).filter { $0.count >= 3 })
            let candWords = Set(candLower.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init).filter { $0.count >= 3 })
            let noiseWords: Set<String> = ["the", "and", "feat", "featuring", "ft", "music", "official", "records", "band", "from", "original"]
            let mExp = expWords.subtracting(noiseWords)
            let mCand = candWords.subtracting(noiseWords)
            
            if !mExp.isEmpty && !mCand.isEmpty && !mExp.isDisjoint(with: mCand) {
                return true
            }
        }
        return false
    }

    /// Cleans album clutter like "(Original Motion Picture Soundtrack)" or "[Deluxe Edition]"
    public nonisolated static func cleanAlbumName(_ album: String) -> String {
        var clean = album.trimmingCharacters(in: .whitespacesAndNewlines)
        let patterns = [
            "\\(Original Motion Picture Soundtrack.*\\)",
            "\\[Original Motion Picture Soundtrack.*\\]",
            "\\(Soundtrack.*\\)",
            "\\[Soundtrack.*\\]",
            "\\(Deluxe.*\\)",
            "\\[Deluxe.*\\]",
            "\\(Remastered.*\\)",
            "\\[Remastered.*\\]"
        ]
        for pattern in patterns {
            clean = clean.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
