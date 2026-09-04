import Foundation
import AppKit

// MARK: - BrowserMediaDetection
public struct BrowserMediaDetection: Sendable {
    public let service: MediaService
    public let currentTime: Double?
    public let duration: Double?
    public let url: String?
    public let tabTitle: String?
}

// MARK: - BrowserServiceDetector
// Automatically detects streaming services (YouTube Music, YouTube, Netflix, Prime Video, Spotify, etc.)
// and real-time playback position (currentTime, duration) playing inside web browsers
// (Brave, Chrome, Safari, Edge, Arc, Opera) by querying active and background media tabs
// through the W3C MediaSession and HTML5 Media APIs.
public final class BrowserServiceDetector: @unchecked Sendable {
    public static let shared = BrowserServiceDetector()
    
    // In-memory cache: bundleId:trackTitle -> detected MediaService
    private let cache = NSCache<NSString, NSString>()
    private var browserActiveServices: [String: MediaService] = [:]
    private let lock = NSLock()
    
    public init() {
        // Run initial pre-scan for open browsers
        preScanOpenBrowsers()
    }
    
    public func activeService(for identifier: String) -> MediaService? {
        lock.lock()
        defer { lock.unlock() }
        let lower = identifier.lowercased()
        for (key, service) in browserActiveServices {
            if lower.contains(key.lowercased()) || key.lowercased().contains(lower) {
                return service
            }
        }
        return nil
    }
    
    public func setActiveService(_ service: MediaService, for identifiers: [String]) {
        lock.lock()
        defer { lock.unlock() }
        for id in identifiers {
            browserActiveServices[id] = service
        }
    }
    
    /// Synchronously returns cached service if previously detected
    public func cachedService(bundleId: String, trackTitle: String = "") -> MediaService? {
        if !trackTitle.isEmpty {
            let cacheKey = "\(bundleId):\(trackTitle)" as NSString
            if let cached = cache.object(forKey: cacheKey) as String? {
                return MediaService(rawValue: cached)
            }
        }
        if let active = activeService(for: bundleId) {
            return active
        }
        return nil
    }
    
    private func preScanOpenBrowsers() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for app in NSWorkspace.shared.runningApplications {
                guard let name = app.localizedName, let bId = app.bundleIdentifier else { continue }
                let lower = name.lowercased()
                if lower.contains("brave") || lower.contains("chrome") || lower.contains("safari") || lower.contains("edge") || lower.contains("arc") {
                    Task {
                        _ = await self?.detectService(bundleId: bId, appName: name, trackTitle: "")
                    }
                }
            }
        }
    }
    
    /// Detects the media service and playback timeline for a browser track title.
    /// Runs asynchronously on a background thread so UI is never blocked.
    public func detectService(
        bundleId: String,
        appName: String,
        trackTitle: String
    ) async -> BrowserMediaDetection? {
        let isBrowser = MediaService.browserBundleIds.contains(bundleId) ||
            bundleId.contains("brave") || bundleId.contains("chrome") || bundleId.contains("safari") ||
            appName.lowercased().contains("brave") || appName.lowercased().contains("chrome") || appName.lowercased().contains("safari")
        guard isBrowser else {
            return nil
        }
        
        let stripped = trackTitle
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\\", with: "")
            .filter { $0.isASCII || $0.isLetter || $0.isNumber || $0.isWhitespace }
        let cleanWords = stripped.split(separator: " ").prefix(2).joined(separator: " ")
        let prefix = cleanWords.isEmpty ? String(trackTitle.prefix(6)) : cleanWords
        let lowerPrefix = prefix.lowercased()
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let targetAppName = appName.contains("Media Player") ? "Brave Browser" : appName
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
                                        set js to do JavaScript "(() => { const u = window.location.href; const ms = navigator.mediaSession ? navigator.mediaSession.metadata : null; const all = Array.from(document.querySelectorAll('video, audio')); let m = all.find(el => !el.paused && !el.ended && el.currentTime > 0) || all.find(el => !el.paused && !el.ended) || all.find(el => el.currentTime > 0 && !el.ended) || all[0]; const timeInfo = m ? (m.currentTime + ',' + m.duration) : ''; const isPlaying = m ? !m.paused : false; const msTitle = (ms && ms.title ? ms.title : '').toLowerCase(); const msArtist = (ms && ms.artist ? ms.artist : '').toLowerCase(); const tabTitle = document.title.toLowerCase(); return u + '|||' + timeInfo + '|||' + msTitle + '|||' + tabTitle + '|||' + isPlaying + '|||' + msArtist; })()" in t
                                        if "\(lowerPrefix)" is not "" and js contains "\(lowerPrefix)" then
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
                    tell application "\(targetAppName)"
                        if running then
                            set match to ""
                            set playingMatch to ""
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        tell t
                                            set js to execute javascript "(() => { const u = window.location.href; const ms = navigator.mediaSession ? navigator.mediaSession.metadata : null; const all = Array.from(document.querySelectorAll('video, audio')); let m = all.find(el => !el.paused && !el.ended && el.currentTime > 0) || all.find(el => !el.paused && !el.ended) || all.find(el => el.currentTime > 0 && !el.ended) || all[0]; const timeInfo = m ? (m.currentTime + ',' + m.duration) : ''; const isPlaying = m ? !m.paused : false; const msTitle = (ms && ms.title ? ms.title : '').toLowerCase(); const msArtist = (ms && ms.artist ? ms.artist : '').toLowerCase(); const tabTitle = document.title.toLowerCase(); return u + '|||' + timeInfo + '|||' + msTitle + '|||' + tabTitle + '|||' + isPlaying + '|||' + msArtist; })()"
                                        end tell
                                        if "\(lowerPrefix)" is not "" and js contains "\(lowerPrefix)" then
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
                }
                
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]
                let stdoutPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = Pipe()
                
                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let res = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    
                    if !res.isEmpty {
                        let parts = res.components(separatedBy: "|||")
                        let urlStr = parts.first ?? ""
                        let urlLower = urlStr.lowercased()
                        let msTitleLower = (parts.count > 2 ? parts[2] : "").lowercased()
                        let tabTitleLower = (parts.count > 3 ? parts[3] : "").lowercased()
                        let msArtistLower = (parts.count > 5 ? parts[5] : "").lowercased()
                        
                        let detected: MediaService
                        if urlLower.contains("music.youtube.com") || tabTitleLower.contains("youtube music") || msTitleLower.contains("youtube music") {
                            detected = .youtubeMusic
                        } else if urlLower.contains("youtube.com") || urlLower.contains("youtu.be") || tabTitleLower.contains("youtube") {
                            detected = .youtube
                        } else if urlLower.contains("x.com") || urlLower.contains("twitter.com") {
                            detected = .x
                        } else if urlLower.contains("spotify.com") || tabTitleLower.contains("spotify") {
                            detected = .spotify
                        } else if urlLower.contains("netflix.com") || tabTitleLower.contains("netflix") || msTitleLower.contains("netflix") {
                            detected = .netflix
                        } else if urlLower.contains("primevideo.com") || urlLower.contains("primevideo") || urlLower.contains("prime-video") ||
                                  (urlLower.contains("amazon.") && (urlLower.contains("/video") || urlLower.contains("/gp/video") || urlLower.contains("prime") || urlLower.contains("minitv") || urlLower.contains("/pv/"))) ||
                                  tabTitleLower.contains("prime video") || tabTitleLower.contains("amazon prime") || tabTitleLower.contains("primevideo") ||
                                  msTitleLower.contains("prime video") || msArtistLower.contains("prime video") {
                            detected = .primeVideo
                        } else if urlLower.contains("music.amazon.") {
                            detected = .amazonMusic
                        } else if urlLower.contains("music.apple.com") {
                            detected = .appleMusic
                        } else if urlLower.contains("jiosaavn.com") {
                            detected = .jioSaavn
                        } else if urlLower.contains("gaana.com") {
                            detected = .gaana
                        } else if urlLower.contains("soundcloud.com") {
                            detected = .soundcloud
                        } else if urlLower.contains("disneyplus.com") || urlLower.contains("hotstar.com") ||
                                  tabTitleLower.contains("disney+") || tabTitleLower.contains("disneyplus") || tabTitleLower.contains("hotstar") || tabTitleLower.contains("disney plus") {
                            detected = .disneyPlus
                        } else if urlLower.contains("twitch.tv") {
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
                            self?.setActiveService(detected, for: [bundleId, appName])
                            let key = "\(bundleId):\(trackTitle)" as NSString
                            self?.cache.setObject(detected.rawValue as NSString, forKey: key)
                        }
                        
                        let extractedTabTitle = parts.count > 3 ? parts[3] : nil
                        
                        continuation.resume(returning: BrowserMediaDetection(
                            service: detected,
                            currentTime: extractedTime,
                            duration: extractedDuration,
                            url: urlStr.isEmpty ? nil : urlStr,
                            tabTitle: extractedTabTitle?.isEmpty == false ? extractedTabTitle : nil
                        ))
                        return
                    }
                } catch {
                    // Ignore and return nil
                }
                continuation.resume(returning: nil)
            }
        }
    }
}
