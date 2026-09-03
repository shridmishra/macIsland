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
    
    /// Vibrant brand colors matching the streaming service's official logo
    public var brandColor: Color {
        switch self {
        case .primeVideo:
            return Color(red: 0.0, green: 0.65, blue: 0.95) // Vibrant Prime Video Blue
        case .netflix:
            return Color(red: 0.90, green: 0.06, blue: 0.10) // Netflix Iconic Red
        case .youtube:
            return Color(red: 1.0, green: 0.0, blue: 0.0) // YouTube Bright Red
        case .spotify:
            return Color(red: 0.11, green: 0.84, blue: 0.38) // Spotify Electric Green
        case .appleMusic:
            return Color(red: 0.99, green: 0.24, blue: 0.36) // Apple Music Coral Red
        case .disneyPlus:
            return Color(red: 0.07, green: 0.39, blue: 0.90) // Disney+ Royal Blue
        case .soundcloud:
            return Color(red: 1.0, green: 0.35, blue: 0.0) // SoundCloud Orange
        case .twitch:
            return Color(red: 0.57, green: 0.27, blue: 1.0) // Twitch Purple
        case .appleTV:
            return Color.white
        case .generic:
            return Color(red: 0.40, green: 0.70, blue: 1.0) // Default Cool Cyan/Blue
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
    ) -> (service: MediaService, cleanedTitle: String) {
        let combined = "\(title) \(album) \(artist) \(appName)".lowercased()
        let isBrowser = bundleId.map { browserBundleIds.contains($0) } ?? false
        
        // 1. Prime Video
        if combined.contains("prime video") || combined.contains("amazon prime") || combined.contains("primevideo") {
            let clean = cleanPrefix(title, prefix: "Prime Video: ")
            return (.primeVideo, clean)
        }
        
        // 2. Netflix
        if combined.contains("netflix") {
            let clean = cleanPrefix(title, prefix: "Netflix: ")
            return (.netflix, clean)
        }
        
        // 3. YouTube
        if combined.contains("youtube") || combined.contains("youtu.be") {
            var clean = title
            if let range = clean.range(of: " - YouTube", options: .backwards) {
                clean.removeSubrange(range)
            }
            return (.youtube, clean)
        }
        
        // 4. Spotify
        if bundleId == "com.spotify.client" || (isBrowser && combined.contains("spotify")) {
            return (.spotify, title)
        }
        
        // 5. Apple Music
        if bundleId == "com.apple.Music" {
            return (.appleMusic, title)
        }
        
        // 6. Disney+ / Hotstar
        if combined.contains("disney+") || combined.contains("disney plus") || combined.contains("hotstar") {
            return (.disneyPlus, title)
        }
        
        // 7. SoundCloud
        if combined.contains("soundcloud") {
            return (.soundcloud, title)
        }
        
        // 8. Twitch
        if combined.contains("twitch") {
            return (.twitch, title)
        }
        
        // 9. Apple TV
        if bundleId == "com.apple.TV" {
            return (.appleTV, title)
        }
        
        return (.generic, title)
    }
    
    private static func cleanPrefix(_ string: String, prefix: String) -> String {
        if string.lowercased().hasPrefix(prefix.lowercased()) {
            return String(string.dropFirst(prefix.count))
        }
        return string
    }
}
