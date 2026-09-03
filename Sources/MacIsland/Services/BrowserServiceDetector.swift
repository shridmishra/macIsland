import Foundation
import AppKit

// MARK: - BrowserMediaDetection
public struct BrowserMediaDetection: Sendable {
    public let service: MediaService
    public let currentTime: Double?
    public let duration: Double?
}

// MARK: - BrowserServiceDetector
// Automatically detects streaming services (YouTube Music, YouTube, Netflix, Prime Video, Spotify, etc.)
// and real-time playback position (currentTime, duration) playing inside web browsers
// (Brave, Chrome, Safari, Edge, Arc, Opera) by querying active and background media tabs
// through the W3C MediaSession and HTML5 Media APIs.
public final class BrowserServiceDetector: @unchecked Sendable {
    public static let shared = BrowserServiceDetector()
    
    // In-memory cache: track prefix -> detected MediaService
    private let cache = NSCache<NSString, NSString>()
    
    public init() {}
    
    /// Synchronously returns cached service if previously detected
    public func cachedService(bundleId: String, trackTitle: String) -> MediaService? {
        let cacheKey = "\(bundleId):\(trackTitle)" as NSString
        if let cached = cache.object(forKey: cacheKey) as String? {
            return MediaService(rawValue: cached)
        }
        return nil
    }
    
    /// Detects the media service and playback timeline for a browser track title.
    /// Runs asynchronously on a background thread so UI is never blocked.
    public func detectService(
        bundleId: String,
        appName: String,
        trackTitle: String
    ) async -> BrowserMediaDetection? {
        guard MediaService.browserBundleIds.contains(bundleId) else {
            return nil
        }
        
        // Clean title: extract search terms to match against navigator.mediaSession.metadata.title
        let stripped = trackTitle
            .replacingOccurrences(of: "\"", with: "\\\"")
            .filter { $0.isASCII || $0.isLetter || $0.isNumber || $0.isWhitespace }
        let cleanWords = stripped.split(separator: " ").prefix(2).joined(separator: " ")
        let prefix = cleanWords.isEmpty ? String(trackTitle.prefix(8)) : cleanWords
        let lowerPrefix = prefix.lowercased()
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let script: String
                if bundleId == "com.apple.Safari" {
                    script = """
                    tell application "Safari"
                        if running then
                            set match to ""
                            set playingMatch to ""
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        set js to do JavaScript "(() => {
                                            const u = window.location.href;
                                            const ms = navigator.mediaSession?.metadata;
                                            const m = document.querySelector('video, audio');
                                            const timeInfo = m ? (m.currentTime + ',' + m.duration) : '';
                                            const isPlaying = m ? !m.paused : false;
                                            const msTitle = (ms?.title || '').toLowerCase();
                                            const tabTitle = document.title.toLowerCase();
                                            return u + '|||' + timeInfo + '|||' + msTitle + '|||' + tabTitle + '|||' + isPlaying;
                                        })()" in t
                                        if js contains "\(lowerPrefix)" then
                                            set match to js
                                            exit repeat
                                        else if js contains "|||true" and playingMatch is "" then
                                            set playingMatch to js
                                        end if
                                    end try
                                end repeat
                                if match is not "" then exit repeat
                            end repeat
                            if match is not "" then
                                return match
                            else if playingMatch is not "" then
                                return playingMatch
                            end if
                        end if
                    end tell
                    return ""
                    """
                } else {
                    script = """
                    tell application "\(appName)"
                        if running then
                            set match to ""
                            set playingMatch to ""
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        set js to execute t javascript "(() => {
                                            const u = window.location.href;
                                            const ms = navigator.mediaSession?.metadata;
                                            const m = document.querySelector('video, audio');
                                            const timeInfo = m ? (m.currentTime + ',' + m.duration) : '';
                                            const isPlaying = m ? !m.paused : false;
                                            const msTitle = (ms?.title || '').toLowerCase();
                                            const tabTitle = document.title.toLowerCase();
                                            return u + '|||' + timeInfo + '|||' + msTitle + '|||' + tabTitle + '|||' + isPlaying;
                                        })()"
                                        if js contains "\(lowerPrefix)" then
                                            set match to js
                                            exit repeat
                                        else if js contains "|||true" and playingMatch is "" then
                                            set playingMatch to js
                                        end if
                                    end try
                                end repeat
                                if match is not "" then exit repeat
                            end repeat
                            if match is not "" then
                                return match
                            else if playingMatch is not "" then
                                return playingMatch
                            end if
                            try
                                tell active tab of window 1
                                    set u to URL
                                    set js to execute javascript "(() => {
                                        const m = document.querySelector('video, audio');
                                        return m ? (m.currentTime + ',' + m.duration) : '';
                                    })()"
                                    return u + "|||" + js
                                end tell
                            end try
                        end if
                    end tell
                    return ""
                    """
                }
                
                var error: NSDictionary?
                if let ascript = NSAppleScript(source: script) {
                    let res = ascript.executeAndReturnError(&error).stringValue ?? ""
                    if !res.isEmpty {
                        let parts = res.components(separatedBy: "|||")
                        let urlStr = parts.first ?? ""
                        let lower = urlStr.lowercased()
                        
                        let detected: MediaService
                        if lower.contains("music.youtube.com") {
                            detected = .youtubeMusic
                        } else if lower.contains("youtube.com") || lower.contains("youtu.be") {
                            detected = .youtube
                        } else if lower.contains("spotify.com") {
                            detected = .spotify
                        } else if lower.contains("netflix.com") {
                            detected = .netflix
                        } else if lower.contains("primevideo.com") || lower.contains("amazon.com/gp/video") {
                            detected = .primeVideo
                        } else if lower.contains("music.amazon.") {
                            detected = .amazonMusic
                        } else if lower.contains("music.apple.com") {
                            detected = .appleMusic
                        } else if lower.contains("jiosaavn.com") {
                            detected = .jioSaavn
                        } else if lower.contains("gaana.com") {
                            detected = .gaana
                        } else if lower.contains("soundcloud.com") {
                            detected = .soundcloud
                        } else if lower.contains("disneyplus.com") || lower.contains("hotstar.com") {
                            detected = .disneyPlus
                        } else if lower.contains("twitch.tv") {
                            detected = .twitch
                        } else {
                            detected = .generic
                        }
                        
                        var extractedTime: Double? = nil
                        var extractedDuration: Double? = nil
                        if parts.count > 1 {
                            let timeInfo = parts[1].components(separatedBy: ",")
                            if timeInfo.count >= 2 {
                                extractedTime = Double(timeInfo[0].trimmingCharacters(in: .whitespaces))
                                extractedDuration = Double(timeInfo[1].trimmingCharacters(in: .whitespaces))
                            }
                        }
                        
                        if detected != .generic {
                            let key = "\(bundleId):\(trackTitle)" as NSString
                            self?.cache.setObject(detected.rawValue as NSString, forKey: key)
                        }
                        
                        continuation.resume(returning: BrowserMediaDetection(
                            service: detected,
                            currentTime: extractedTime,
                            duration: extractedDuration
                        ))
                        return
                    }
                }
                continuation.resume(returning: nil)
            }
        }
    }
}
