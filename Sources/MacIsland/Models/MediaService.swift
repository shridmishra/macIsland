import SwiftUI

// MARK: - MediaService
// Identifies specific media streaming services (Netflix, Prime Video, YouTube, Spotify, etc.)
// even when playing inside browsers (Brave, Chrome, Safari, Edge, Arc, Firefox).
public enum MediaService: String, CaseIterable, Sendable {
    case primeVideo = "Prime Video"
    case netflix = "Netflix"
    case youtube = "YouTube"
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    case disneyPlus = "Disney+"
    case soundcloud = "SoundCloud"
    case twitch = "Twitch"
    case appleTV = "Apple TV"
    case generic = "Media"
    
    public var brandColor: Color {
        switch self {
        case .primeVideo:
            return Color(red: 0.0, green: 0.66, blue: 0.88) // #00A8E1 Prime Video Cyan Blue
        case .netflix:
            return Color(red: 0.89, green: 0.04, blue: 0.08) // #E50914 Netflix Red
        case .youtube:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // #FF0000 YouTube Red
        case .spotify:
            return Color(red: 0.11, green: 0.73, blue: 0.33) // #1DB954 Spotify Green
        case .appleMusic:
            return Color(red: 0.98, green: 0.14, blue: 0.24) // Apple Music Magenta
        case .disneyPlus:
            return Color(red: 0.07, green: 0.25, blue: 0.75) // Disney+ Blue
        case .soundcloud:
            return Color(red: 1.0, green: 0.33, blue: 0.0) // SoundCloud Orange
        case .twitch:
            return Color(red: 0.57, green: 0.27, blue: 1.0) // Twitch Purple
        case .appleTV:
            return Color.white
        case .generic:
            return Color.islandAccent
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
        bundleId: String? = nil
    ) -> (service: MediaService, cleanedTitle: String) {
        let combined = "\(title) \(album) \(artist)".lowercased()
        let bId = bundleId?.lowercased() ?? ""
        
        // 1. Prime Video
        if combined.contains("prime video") || combined.contains("amazon prime") || combined.contains("primevideo") {
            var cleaned = title
            let patterns = [
                "^Prime Video:\\s*",
                "^Watch\\s+",
                "\\s*-\\s*Prime Video.*$",
                "\\s*\\|\\s*Prime Video.*$"
            ]
            for pattern in patterns {
                cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }
            return (.primeVideo, cleaned.isEmpty ? title : cleaned)
        }
        
        // 2. Netflix
        if combined.contains("netflix") {
            var cleaned = title
            let patterns = [
                "^Netflix\\s*-\\s*",
                "^Netflix:\\s*",
                "\\s*\\|\\s*Netflix.*$",
                "\\s*-\\s*Netflix.*$"
            ]
            for pattern in patterns {
                cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }
            return (.netflix, cleaned.isEmpty ? title : cleaned)
        }
        
        // 3. YouTube / YouTube Music
        if combined.contains("youtube") || combined.contains("youtu.be") {
            var cleaned = title
            let patterns = [
                "\\s*-\\s*YouTube Music.*$",
                "\\s*-\\s*YouTube.*$",
                "\\s*\\|\\s*YouTube.*$"
            ]
            for pattern in patterns {
                cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }
            return (.youtube, cleaned.isEmpty ? title : cleaned)
        }
        
        // 4. Spotify
        if bId.contains("spotify") || combined.contains("spotify") {
            var cleaned = title
            let patterns = [
                "\\s*-\\s*Spotify.*$",
                "\\s*•\\s*Spotify.*$"
            ]
            for pattern in patterns {
                cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }
            return (.spotify, cleaned.isEmpty ? title : cleaned)
        }
        
        // 5. Apple Music
        if bId == "com.apple.music" || combined.contains("apple music") {
            return (.appleMusic, title)
        }
        
        // 6. Disney+ / Hotstar
        if combined.contains("disney+") || combined.contains("disney plus") || combined.contains("hotstar") {
            var cleaned = title
            let patterns = [
                "\\s*\\|\\s*Disney\\+.*$",
                "\\s*-\\s*Disney\\+.*$",
                "\\s*\\|\\s*Hotstar.*$"
            ]
            for pattern in patterns {
                cleaned = cleaned.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }
            return (.disneyPlus, cleaned.isEmpty ? title : cleaned)
        }
        
        // 7. SoundCloud
        if combined.contains("soundcloud") {
            var cleaned = title
            cleaned = cleaned.replacingOccurrences(of: "\\s*on SoundCloud.*$", with: "", options: .regularExpression)
            cleaned = cleaned.replacingOccurrences(of: "\\s*-\\s*SoundCloud.*$", with: "", options: .regularExpression)
            return (.soundcloud, cleaned.isEmpty ? title : cleaned)
        }
        
        // 8. Twitch
        if combined.contains("twitch") {
            var cleaned = title
            cleaned = cleaned.replacingOccurrences(of: "\\s*-\\s*Twitch.*$", with: "", options: .regularExpression)
            return (.twitch, cleaned.isEmpty ? title : cleaned)
        }
        
        // 9. Apple TV
        if bId == "com.apple.tv" || combined.contains("apple tv") {
            return (.appleTV, title)
        }
        
        return (.generic, title)
    }
}
