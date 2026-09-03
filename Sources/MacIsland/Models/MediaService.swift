import SwiftUI

// MARK: - MediaService
// Identifies specific media streaming services (Netflix, Prime Video, YouTube, YouTube Music, Spotify, etc.)
// even when playing inside browsers (Brave, Chrome, Safari, Edge, Arc, Firefox).
public enum MediaService: String, CaseIterable, Sendable {
    case primeVideo = "Prime Video"
    case netflix = "Netflix"
    case youtubeMusic = "YouTube Music"
    case youtube = "YouTube"
    case x = "X"
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case jioSaavn = "JioSaavn"
    case gaana = "Gaana"
    case amazonMusic = "Amazon Music"
    case disneyPlus = "Disney+"
    case soundcloud = "SoundCloud"
    case twitch = "Twitch"
    case appleTV = "Apple TV"
    case generic = "Media"
    
    /// Vibrant brand colors matching the streaming service's official logo
    public var brandColor: Color {
        switch self {
        case .x:
            return Color.white // X Monochrome White
        case .youtube, .youtubeMusic:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // Pure YouTube Red #FF0000
        case .netflix:
            return Color(red: 0.90, green: 0.06, blue: 0.10) // Netflix Iconic Red #E50914
        case .spotify:
            return Color(red: 0.11, green: 0.84, blue: 0.38) // Spotify Electric Green #1DB954
        case .primeVideo, .amazonMusic:
            return Color(red: 0.0, green: 0.65, blue: 0.95) // Prime Video / Amazon Music Cyan-Blue #00A8E1
        case .appleMusic:
            return Color(red: 0.99, green: 0.24, blue: 0.36) // Apple Music Coral Red #FC3C44
        case .jioSaavn:
            return Color(red: 0.17, green: 0.77, blue: 0.71) // JioSaavn Teal #2BC5B4
        case .gaana:
            return Color(red: 0.91, green: 0.17, blue: 0.19) // Gaana Red #E72C30
        case .disneyPlus:
            return Color(red: 0.07, green: 0.39, blue: 0.90) // Disney+ Royal Blue #0063E5
        case .soundcloud:
            return Color(red: 1.0, green: 0.35, blue: 0.0) // SoundCloud Orange #FF5500
        case .twitch:
            return Color(red: 0.57, green: 0.27, blue: 1.0) // Twitch Purple #9146FF
        case .appleTV:
            return Color.white
        case .generic:
            return Color(red: 0.40, green: 0.70, blue: 1.0) // Default Cool Cyan/Blue
        }
    }
    
    /// Common URL domain substrings associated with this streaming service
    public var domainKeywords: [String] {
        switch self {
        case .youtubeMusic:
            return ["music.youtube.com"]
        case .youtube:
            return ["youtube.com", "youtu.be"]
        case .x:
            return ["x.com", "twitter.com"]
        case .spotify:
            return ["open.spotify.com", "spotify.com"]
        case .netflix:
            return ["netflix.com"]
        case .primeVideo:
            return ["primevideo.com", "amazon.com/gp/video"]
        case .amazonMusic:
            return ["music.amazon"]
        case .appleMusic:
            return ["music.apple.com"]
        case .jioSaavn:
            return ["jiosaavn.com"]
        case .gaana:
            return ["gaana.com"]
        case .disneyPlus:
            return ["disneyplus.com", "hotstar.com"]
        case .soundcloud:
            return ["soundcloud.com"]
        case .twitch:
            return ["twitch.tv"]
        case .appleTV:
            return ["tv.apple.com"]
        case .generic:
            return []
        }
    }
    
    /// Known browser bundle identifiers on macOS
    public static let browserBundleIds: Set<String> = [
        "com.brave.Browser",
        "com.google.Chrome",
        "com.apple.Safari",
        "com.microsoft.edgemac",
        "company.thebrowser.Arc",
        "com.operasoftware.Opera",
        "org.mozilla.firefox",
        "com.vivaldi.Vivaldi"
    ]
    
    /// Detects the underlying media service from title, album, artist, and bundle ID,
    /// and strips unnecessary brand prefixes from the track title.
    public static func detect(
        title: String,
        album: String = "",
        artist: String = "",
        bundleId: String? = nil,
        appName: String = ""
    ) -> (service: MediaService, cleanedTitle: String, extractedAuthor: String?) {
        let combined = "\(title) \(album) \(artist) \(appName)".lowercased()
        let isBrowser = bundleId.map { browserBundleIds.contains($0) } ?? false
        
        // 0. X (Twitter)
        if combined.contains("on x: ") || combined.contains(" / x") || combined.contains("on twitter: ") || combined.contains(" / twitter") || combined.contains("x.com") || combined.contains("twitter.com") {
            let (clean, author) = cleanXTitle(title)
            return (.x, clean, author)
        }
        
        // 1. Prime Video
        if combined.contains("prime video") || combined.contains("amazon prime") || combined.contains("primevideo") {
            let clean = cleanPrefix(title, prefix: "Prime Video: ")
            return (.primeVideo, clean, nil)
        }
        
        // 2. Netflix
        if combined.contains("netflix") {
            let clean = cleanPrefix(title, prefix: "Netflix: ")
            return (.netflix, clean, nil)
        }
        
        // 3. YouTube Music
        if combined.contains("youtube music") || combined.contains("music.youtube") {
            let clean = cleanPrefix(title, prefix: "YouTube Music: ")
            return (.youtubeMusic, clean, nil)
        }
        
        // 4. YouTube (videos, channels)
        if combined.contains("youtube") || combined.contains("youtu.be") {
            let clean = cleanPrefix(title, prefix: "YouTube: ")
            return (.youtube, clean, nil)
        }
        
        // 5. Spotify
        if combined.contains("spotify") || bundleId == "com.spotify.client" {
            return (.spotify, title, nil)
        }
        
        // 6. Apple Music
        if combined.contains("apple music") || bundleId == "com.apple.Music" {
            return (.appleMusic, title, nil)
        }
        
        // 7. JioSaavn
        if combined.contains("jiosaavn") || combined.contains("saavn") {
            return (.jioSaavn, title, nil)
        }
        
        // 8. Gaana
        if combined.contains("gaana") {
            return (.gaana, title, nil)
        }
        
        // 9. Disney+
        if combined.contains("disney+") || combined.contains("disneyplus") || combined.contains("hotstar") {
            return (.disneyPlus, title, nil)
        }
        
        // 10. SoundCloud
        if combined.contains("soundcloud") {
            return (.soundcloud, title, nil)
        }
        
        // 11. Twitch
        if combined.contains("twitch") {
            return (.twitch, title, nil)
        }
        
        // Fallback for native apps
        if !isBrowser {
            if appName.contains("Music") {
                return (.appleMusic, title, nil)
            } else if appName.contains("Spotify") {
                return (.spotify, title, nil)
            } else if appName.contains("TV") {
                return (.appleTV, title, nil)
            }
        }
        
        return (.generic, title, nil)
    }
    
    public static func cleanXTitle(_ raw: String) -> (title: String, author: String?) {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Strip trailing " / X" or " / Twitter"
        if text.hasSuffix(" / X") {
            text = String(text.dropLast(4))
        } else if text.hasSuffix(" / Twitter") {
            text = String(text.dropLast(10))
        }
        
        // Strip leading notification badge e.g. "(1) ", "(99+) "
        if text.hasPrefix("(") {
            if let closeParen = text.firstIndex(of: ")") {
                let afterParen = text.index(after: closeParen)
                let remainder = text[afterParen...].trimmingCharacters(in: .whitespaces)
                text = remainder
            }
        }
        
        // Regex for: [Author] on X: "[Tweet]" or [Author] on Twitter: "[Tweet]"
        let pattern = #"^(.*?)\s+on\s+(?:X|Twitter):\s*["“](.*?)["”]?$"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
            let nsString = text as NSString
            if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsString.length)) {
                let author = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                var tweet = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
                
                // Strip trailing t.co links e.g. https://t.co/KyVUhyQSXn
                if let linkRegex = try? NSRegularExpression(pattern: #"https://t\.co/\S+$"#) {
                    tweet = linkRegex.stringByReplacingMatches(in: tweet, range: NSRange(location: 0, length: (tweet as NSString).length), withTemplate: "").trimmingCharacters(in: .whitespaces)
                }
                
                if !tweet.isEmpty {
                    return (tweet, author.isEmpty ? nil : author)
                } else if !author.isEmpty {
                    return (author, nil)
                }
            }
        }
        
        return (text, nil)
    }
    
    private static func cleanPrefix(_ title: String, prefix: String) -> String {
        if title.hasPrefix(prefix) {
            return String(title.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        }
        return title
    }
}
