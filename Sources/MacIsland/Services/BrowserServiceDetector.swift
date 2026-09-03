import Foundation
import AppKit

// MARK: - BrowserMediaDetection
public struct BrowserMediaDetection: Sendable {
    public let service: MediaService
    public let currentTime: Double?
    public let duration: Double?
}

// MARK: - BrowserServiceDetector
// Automatically detects streaming services (YouTube, Netflix, Prime Video, Spotify, etc.)
// and real-time playback position (currentTime, duration) playing inside web browsers
// (Brave, Chrome, Safari, Edge, Arc, Opera) by querying the active browser tab.
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
        
        // Clean title: remove directional isolates, quotes, and extract clean search prefix
        let stripped = trackTitle
            .replacingOccurrences(of: "\"", with: "\\\"")
            .filter { $0.isASCII || $0.isLetter || $0.isNumber || $0.isWhitespace }
        let cleanWords = stripped.split(separator: " ").prefix(3).joined(separator: " ")
        let prefix = cleanWords.isEmpty ? String(trackTitle.prefix(10)) : cleanWords
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let script: String
                if bundleId == "com.apple.Safari" {
                    script = """
                    tell application "Safari"
                        if running then
                            repeat with w in windows
                                repeat with t in tabs of w
                                    set tURL to URL of t
                                    set tName to name of t
                                    if tName contains "\(prefix)" then
                                        try
                                            set js to do JavaScript "(() => { const v = document.querySelector('video'); return v ? (v.currentTime + ',' + v.duration) : ''; })()" in t
                                            return tURL & "|||" & js
                                        on error
                                            return tURL
                                        end try
                                    end if
                                end repeat
                            end repeat
                            try
                                set u to URL of current tab of window 1
                                try
                                    set js to do JavaScript "(() => { const v = document.querySelector('video'); return v ? (v.currentTime + ',' + v.duration) : ''; })()" in current tab of window 1
                                    return u & "|||" & js
                                on error
                                    return u
                                end try
                            end try
                        end if
                    end tell
                    return ""
                    """
                } else {
                    script = """
                    tell application "\(appName)"
                        if running then
                            repeat with w in windows
                                repeat with t in tabs of w
                                    set tURL to URL of t
                                    set tTitle to title of t
                                    if tTitle contains "\(prefix)" then
                                        try
                                            set js to execute t javascript "(() => { const v = document.querySelector('video'); return v ? (v.currentTime + ',' + v.duration) : ''; })()"
                                            return tURL & "|||" & js
                                        on error
                                            return tURL
                                        end try
                                    end if
                                end repeat
                            end repeat
                            try
                                tell active tab of window 1
                                    set u to URL
                                    try
                                        set js to execute javascript "(() => { const v = document.querySelector('video'); return v ? (v.currentTime + ',' + v.duration) : ''; })()"
                                        return u & "|||" & js
                                    on error
                                        return u
                                    end try
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
                        if lower.contains("youtube.com") || lower.contains("youtu.be") {
                            detected = .youtube
                        } else if lower.contains("netflix.com") {
                            detected = .netflix
                        } else if lower.contains("primevideo.com") || lower.contains("amazon.com/gp/video") {
                            detected = .primeVideo
                        } else if lower.contains("spotify.com") {
                            detected = .spotify
                        } else if lower.contains("disneyplus.com") || lower.contains("hotstar.com") {
                            detected = .disneyPlus
                        } else if lower.contains("soundcloud.com") {
                            detected = .soundcloud
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
