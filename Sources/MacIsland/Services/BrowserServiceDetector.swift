import Foundation
import AppKit

// MARK: - BrowserServiceDetector
// Automatically detects streaming services (YouTube, Netflix, Prime Video, Spotify, etc.)
// playing inside web browsers (Brave, Chrome, Safari, Edge, Arc, Opera) by querying
// the active/matching browser tab URL asynchronously on a background queue.
public final class BrowserServiceDetector: @unchecked Sendable {
    public static let shared = BrowserServiceDetector()
    
    // In-memory cache: track prefix -> detected MediaService
    private let cache = NSCache<NSString, NSString>()
    
    public init() {}
    
    /// Detects the media service for a browser track title.
    /// Runs asynchronously on a background thread so UI is never blocked.
    public func detectService(
        bundleId: String,
        appName: String,
        trackTitle: String
    ) async -> MediaService? {
        guard MediaService.browserBundleIds.contains(bundleId) else {
            return nil
        }
        
        let cacheKey = "\(bundleId):\(trackTitle)" as NSString
        if let cached = cache.object(forKey: cacheKey) as String? {
            return MediaService(rawValue: cached)
        }
        
        let cleanTitle = trackTitle.replacingOccurrences(of: "\"", with: "\\\"")
        let prefix = String(cleanTitle.prefix(12))
        
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
                                        return tURL
                                    end if
                                end repeat
                            end repeat
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
                                        return tURL
                                    end if
                                end repeat
                            end repeat
                        end if
                    end tell
                    return ""
                    """
                }
                
                var error: NSDictionary?
                if let ascript = NSAppleScript(source: script) {
                    let res = ascript.executeAndReturnError(&error).stringValue ?? ""
                    if !res.isEmpty {
                        let lower = res.lowercased()
                        let detected: MediaService?
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
                            detected = nil
                        }
                        
                        if let found = detected {
                            let key = "\(bundleId):\(trackTitle)" as NSString
                            self?.cache.setObject(found.rawValue as NSString, forKey: key)
                            continuation.resume(returning: found)
                            return
                        }
                    }
                }
                continuation.resume(returning: nil)
            }
        }
    }
}
