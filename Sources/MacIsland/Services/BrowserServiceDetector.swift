import Foundation
import AppKit

// MARK: - BrowserMediaDetection
public struct BrowserMediaDetection: Sendable {
    public let service: MediaService
    public let currentTime: Double?
    public let duration: Double?
    public let url: String?
    public let tabTitle: String?
    public let isMusic: Bool
    public let isPlaying: Bool
    public let rawTitle: String?
    public let rawArtist: String?
    public let rawAlbum: String?
    public let artworkUrl: String?
    public let bundleIdentifier: String?
    public let appName: String?
    
    public init(
        service: MediaService,
        currentTime: Double?,
        duration: Double?,
        url: String?,
        tabTitle: String?,
        isMusic: Bool = false,
        isPlaying: Bool = false,
        rawTitle: String? = nil,
        rawArtist: String? = nil,
        rawAlbum: String? = nil,
        artworkUrl: String? = nil,
        bundleIdentifier: String? = nil,
        appName: String? = nil
    ) {
        self.service = service
        self.currentTime = currentTime
        self.duration = duration
        self.url = url
        self.tabTitle = tabTitle
        self.isMusic = isMusic
        self.isPlaying = isPlaying
        self.rawTitle = rawTitle
        self.rawArtist = rawArtist
        self.rawAlbum = rawAlbum
        self.artworkUrl = artworkUrl
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
    }
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
    private let lock = NSLock()
    
    // Throttle: minimum 2 seconds between full tab scans per bundle ID
    private var lastDetectionTime: [String: Date] = [:]
    private let throttleInterval: TimeInterval = 2.0
    
    public init() {
        // Run initial pre-scan for open browsers
        preScanOpenBrowsers()
    }
    
    /// Synchronously returns cached service if previously detected for this specific track title
    public func cachedService(bundleId: String, trackTitle: String = "") -> MediaService? {
        guard !trackTitle.isEmpty else { return nil }
        let cacheKey = "\(bundleId):\(trackTitle)" as NSString
        if let cached = cache.object(forKey: cacheKey) as String? {
            return MediaService(rawValue: cached)
        }
        return nil
    }
    
    /// Check if this bundleId was scanned recently (within throttleInterval).
    /// Called synchronously to avoid NSLock usage in async contexts.
    private func isThrottled(bundleId: String, force: Bool = false) -> Bool {
        if force { return false }
        lock.lock()
        defer { lock.unlock() }
        let now = Date()
        if let lastTime = lastDetectionTime[bundleId], now.timeIntervalSince(lastTime) < throttleInterval {
            return true
        }
        lastDetectionTime[bundleId] = now
        return false
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
    /// Detects the media service and playback timeline for a browser track title,
    /// giving strict priority to music streaming services (YouTube Music, Spotify, Apple Music, etc.)
    /// over non-music media (YouTube videos, Twitter, Netflix, etc.).
    /// Runs asynchronously on a background thread so UI is never blocked.
    public func detectService(
        bundleId: String,
        appName: String,
        trackTitle: String,
        force: Bool = false
    ) async -> BrowserMediaDetection? {
        let isBrowser = MediaService.browserBundleIds.contains(bundleId) ||
            bundleId.contains("brave") || bundleId.contains("chrome") || bundleId.contains("safari") || bundleId.contains("edge") || bundleId.contains("arc") ||
            appName.lowercased().contains("brave") || appName.lowercased().contains("chrome") || appName.lowercased().contains("safari") || appName.lowercased().contains("edge") || appName.lowercased().contains("arc")
        guard isBrowser else {
            return nil
        }
        
        // Throttle: skip if we scanned this bundleId recently
        let shouldSkip = isThrottled(bundleId: bundleId, force: force)
        if shouldSkip {
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
                
                let jsPayload = """
                (() => {
                    const u = window.location.href;
                    const ms = navigator.mediaSession ? navigator.mediaSession.metadata : null;
                    const all = Array.from(document.querySelectorAll('video, audio'));
                    let m = all.find(el => !el.paused && !el.ended && el.currentTime > 0) ||
                            all.find(el => !el.paused && !el.ended) ||
                            all.find(el => el.currentTime > 0 && !el.ended) ||
                            all[0];
                    if (!m && !ms && !u.includes('music.youtube.com') && !u.includes('spotify.com') && !u.includes('apple.com')) return '0^^^';
                    const timeInfo = m ? (m.currentTime + ',' + m.duration) : '';
                    const isPlaying = m ? !m.paused : false;
                    const rawTitle = (ms && ms.title) ? ms.title : document.title;
                    const rawArtist = (ms && ms.artist) ? ms.artist : '';
                    const rawAlbum = (ms && ms.album) ? ms.album : '';
                    const msTitle = rawTitle.toLowerCase();
                    const msArtist = rawArtist.toLowerCase();
                    const tabTitle = document.title.toLowerCase();
                    const uLower = u.toLowerCase();
                    const isMusic = uLower.includes('music.youtube.com') ||
                                    uLower.includes('open.spotify.com') ||
                                    uLower.includes('spotify.com') ||
                                    uLower.includes('music.apple.com') ||
                                    uLower.includes('music.amazon') ||
                                    uLower.includes('soundcloud.com') ||
                                    uLower.includes('jiosaavn.com') ||
                                    uLower.includes('gaana.com') ||
                                    uLower.includes('tidal.com') ||
                                    uLower.includes('deezer.com') ||
                                    uLower.includes('bandcamp.com') ||
                                    uLower.includes('qobuz.com');
                    let artworkUrl = '';
                    if (ms && ms.artwork && ms.artwork.length > 0) {
                        artworkUrl = ms.artwork[ms.artwork.length - 1].src || '';
                    }
                    const hasPrefix = ('\(lowerPrefix)' !== '' && (tabTitle.includes('\(lowerPrefix)') || msTitle.includes('\(lowerPrefix)')));
                    
                    let score = 0;
                    if (isMusic && isPlaying) {
                        score = 100;
                    } else if (hasPrefix && isPlaying) {
                        score = 60;
                    } else if (isPlaying) {
                        score = 40;
                    } else if (isMusic) {
                        score = 20;
                    } else if (hasPrefix) {
                        score = 10;
                    } else if (m && m.currentTime > 0) {
                        score = 5;
                    }
                    
                    const cleanUrl = u.split('|||').join('').split('^^^').join('');
                    const cleanTime = timeInfo.split('|||').join('').split('^^^').join('');
                    const cleanTitle = rawTitle.split('|||').join('').split('^^^').join('');
                    const cleanArtist = rawArtist.split('|||').join('').split('^^^').join('');
                    const cleanAlbum = rawAlbum.split('|||').join('').split('^^^').join('');
                    const cleanArt = artworkUrl.split('|||').join('').split('^^^').join('');
                    const cleanTab = document.title.split('|||').join('').split('^^^').join('');
                    
                    const payload = cleanUrl + '|||' + cleanTime + '|||' + msTitle + '|||' + cleanTab + '|||' + isPlaying + '|||' + msArtist + '|||' + (isMusic ? '1' : '0') + '|||' + cleanTitle + '|||' + cleanArtist + '|||' + cleanAlbum + '|||' + cleanArt;
                    return score + '^^^' + payload;
                })()
                """
                
                let escapedJs = jsPayload.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
                
                let script: String
                if bundleId == "com.apple.Safari" {
                    script = """
                    tell application "Safari"
                        if running then
                            set bestScore to -1
                            set bestPayload to ""
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        set res to do JavaScript "\(escapedJs)" in t
                                        if res contains "^^^" then
                                            set oldDelims to AppleScript's text item delimiters
                                            set AppleScript's text item delimiters to "^^^"
                                            set parts to text items of res
                                            set curScore to (item 1 of parts) as integer
                                            if curScore > bestScore then
                                                set bestScore to curScore
                                                set bestPayload to (item 2 of parts)
                                            end if
                                            set AppleScript's text item delimiters to oldDelims
                                        end if
                                    end try
                                end repeat
                            end repeat
                            return bestPayload
                        end if
                    end tell
                    return ""
                    """
                } else {
                    script = """
                    tell application "\(targetAppName)"
                        if running then
                            set bestScore to -1
                            set bestPayload to ""
                            repeat with w in windows
                                repeat with t in tabs of w
                                    try
                                        tell t
                                            set res to execute javascript "\(escapedJs)"
                                            if res contains "^^^" then
                                                set oldDelims to AppleScript's text item delimiters
                                                set AppleScript's text item delimiters to "^^^"
                                                set parts to text items of res
                                                set curScore to (item 1 of parts) as integer
                                                if curScore > bestScore then
                                                    set bestScore to curScore
                                                    set bestPayload to (item 2 of parts)
                                                end if
                                                set AppleScript's text item delimiters to oldDelims
                                            end if
                                        end tell
                                    end try
                                end repeat
                            end repeat
                            return bestPayload
                        end if
                    end tell
                    return ""
                    """
                }
                
                // Execute AppleScript in-process via NSAppleScript
                var error: NSDictionary?
                let appleScript = NSAppleScript(source: script)
                let result = appleScript?.executeAndReturnError(&error)
                let res = result?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                if !res.isEmpty {
                    let parts = res.components(separatedBy: "|||")
                    let urlStr = parts.first ?? ""
                    let urlLower = urlStr.lowercased()
                    let timeInfoStr = parts.count > 1 ? parts[1] : ""
                    let msTitleLower = (parts.count > 2 ? parts[2] : "").lowercased()
                    let tabTitleLower = (parts.count > 3 ? parts[3] : "").lowercased()
                    let isPlayingTab = (parts.count > 4 ? parts[4] : "false") == "true"
                    let msArtistLower = (parts.count > 5 ? parts[5] : "").lowercased()
                    let isMusicTab = (parts.count > 6 ? parts[6] : "0") == "1"
                    let rawTitle = parts.count > 7 && !parts[7].isEmpty ? parts[7] : nil
                    let rawArtist = parts.count > 8 && !parts[8].isEmpty ? parts[8] : nil
                    let rawAlbum = parts.count > 9 && !parts[9].isEmpty ? parts[9] : nil
                    let artworkUrl = parts.count > 10 && !parts[10].isEmpty ? parts[10] : nil
                    
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
                    if !timeInfoStr.isEmpty {
                        let timeInfo = timeInfoStr.components(separatedBy: ",")
                        if timeInfo.count >= 2 {
                            extractedTime = Double(timeInfo[0].trimmingCharacters(in: .whitespaces))
                            extractedDuration = Double(timeInfo[1].trimmingCharacters(in: .whitespaces))
                        }
                    }
                    
                    if detected != .generic, !trackTitle.isEmpty {
                        let key = "\(bundleId):\(trackTitle)" as NSString
                        self?.cache.setObject(detected.rawValue as NSString, forKey: key)
                    }
                    
                    let extractedTabTitle = parts.count > 3 ? parts[3] : nil
                    
                    continuation.resume(returning: BrowserMediaDetection(
                        service: detected,
                        currentTime: extractedTime,
                        duration: extractedDuration,
                        url: urlStr.isEmpty ? nil : urlStr,
                        tabTitle: extractedTabTitle?.isEmpty == false ? extractedTabTitle : nil,
                        isMusic: isMusicTab || detected.isMusicService,
                        isPlaying: isPlayingTab,
                        rawTitle: rawTitle,
                        rawArtist: rawArtist,
                        rawAlbum: rawAlbum,
                        artworkUrl: artworkUrl,
                        bundleIdentifier: bundleId,
                        appName: appName
                    ))
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }
    
    /// Checks whether a specific browser currently has a playing music tab
    public func isMusicTabPlaying(bundleId: String) async -> Bool {
        let isBrowser = MediaService.browserBundleIds.contains(bundleId) ||
            bundleId.contains("brave") || bundleId.contains("chrome") || bundleId.contains("safari") || bundleId.contains("edge") || bundleId.contains("arc")
        guard isBrowser else { return false }
        
        let appName: String
        let lower = bundleId.lowercased()
        if lower.contains("brave") { appName = "Brave Browser" }
        else if lower.contains("chrome") { appName = "Google Chrome" }
        else if lower.contains("safari") { appName = "Safari" }
        else if lower.contains("edge") { appName = "Microsoft Edge" }
        else if lower.contains("arc") { appName = "Arc" }
        else { appName = "Brave Browser" }
        
        if let detected = await detectService(bundleId: bundleId, appName: appName, trackTitle: "", force: true) {
            return detected.isMusic && detected.isPlaying
        }
        return false
    }
    
    /// Scans all running web browsers to see if any browser currently has an active playing music tab.
    public func detectActiveMusicTab() async -> BrowserMediaDetection? {
        return queryActiveMusicTab()
    }
    
    /// Synchronously or asynchronously queries open browsers for any active or playing music tab
    /// (e.g. YouTube Music, Spotify Web, Apple Music Web, etc.) with authoritative track metadata.
    public func queryActiveMusicTab() -> BrowserMediaDetection? {
        for app in NSWorkspace.shared.runningApplications {
            guard let name = app.localizedName, let bId = app.bundleIdentifier else { continue }
            let lower = (name + " " + bId).lowercased()
            let isBrowser = lower.contains("brave") || lower.contains("chrome") || lower.contains("safari") || lower.contains("edge") || lower.contains("arc")
            guard isBrowser else { continue }
            
            let targetAppName: String
            if lower.contains("brave") { targetAppName = "Brave Browser" }
            else if lower.contains("chrome") { targetAppName = "Google Chrome" }
            else if lower.contains("safari") { targetAppName = "Safari" }
            else if lower.contains("edge") { targetAppName = "Microsoft Edge" }
            else if lower.contains("arc") { targetAppName = "Arc" }
            else { targetAppName = name }
            
            let script: String
            if bId == "com.apple.Safari" {
                script = """
                tell application "Safari"
                    if running then
                        repeat with w in windows
                            repeat with t in tabs of w
                                try
                                    set res to do JavaScript "(() => {
                                        const u = window.location.href;
                                        const uLower = u.toLowerCase();
                                        const isM = uLower.includes('music.youtube.com') || uLower.includes('open.spotify.com') || uLower.includes('spotify.com') || uLower.includes('music.apple.com') || uLower.includes('music.amazon') || uLower.includes('soundcloud.com') || uLower.includes('jiosaavn.com') || uLower.includes('gaana.com') || uLower.includes('tidal.com') || uLower.includes('deezer.com');
                                        if (!isM) return '';
                                        const media = Array.from(document.querySelectorAll('video, audio'));
                                        const isPlaying = media.some(m => !m.paused && !m.ended);
                                        const m = media[0];
                                        const ms = navigator.mediaSession ? navigator.mediaSession.metadata : null;
                                        let art = '';
                                        if (ms && ms.artwork && ms.artwork.length > 0) art = ms.artwork[ms.artwork.length - 1].src || '';
                                        const cleanTitle = (ms && ms.title ? ms.title : document.title).split('|||').join('');
                                        const cleanArtist = (ms && ms.artist ? ms.artist : '').split('|||').join('');
                                        const cleanAlbum = (ms && ms.album ? ms.album : '').split('|||').join('');
                                        const cleanUrl = u.split('|||').join('');
                                        const cleanArt = art.split('|||').join('');
                                        return (isPlaying ? '1' : '0') + '|||' + cleanTitle + '|||' + cleanArtist + '|||' + cleanAlbum + '|||' + (m ? m.currentTime : 0) + '|||' + (m ? m.duration : 0) + '|||' + cleanArt + '|||' + cleanUrl;
                                    })()" in t
                                    if res is not "" then return res
                                end try
                            end repeat
                        end repeat
                    end if
                end tell
                return ""
                """
            } else {
                script = """
                tell application "\(targetAppName)"
                    if running then
                        repeat with w in windows
                            repeat with t in tabs of w
                                try
                                    tell t
                                        set res to execute javascript "(() => {
                                            const u = window.location.href;
                                            const uLower = u.toLowerCase();
                                            const isM = uLower.includes('music.youtube.com') || uLower.includes('open.spotify.com') || uLower.includes('spotify.com') || uLower.includes('music.apple.com') || uLower.includes('music.amazon') || uLower.includes('soundcloud.com') || uLower.includes('jiosaavn.com') || uLower.includes('gaana.com') || uLower.includes('tidal.com') || uLower.includes('deezer.com');
                                            if (!isM) return '';
                                            const media = Array.from(document.querySelectorAll('video, audio'));
                                            const isPlaying = media.some(m => !m.paused && !m.ended);
                                            const m = media[0];
                                            const ms = navigator.mediaSession ? navigator.mediaSession.metadata : null;
                                            let art = '';
                                            if (ms && ms.artwork && ms.artwork.length > 0) art = ms.artwork[ms.artwork.length - 1].src || '';
                                            const cleanTitle = (ms && ms.title ? ms.title : document.title).split('|||').join('');
                                            const cleanArtist = (ms && ms.artist ? ms.artist : '').split('|||').join('');
                                            const cleanAlbum = (ms && ms.album ? ms.album : '').split('|||').join('');
                                            const cleanUrl = u.split('|||').join('');
                                            const cleanArt = art.split('|||').join('');
                                            return (isPlaying ? '1' : '0') + '|||' + cleanTitle + '|||' + cleanArtist + '|||' + cleanAlbum + '|||' + (m ? m.currentTime : 0) + '|||' + (m ? m.duration : 0) + '|||' + cleanArt + '|||' + cleanUrl;
                                        })()"
                                        if res is not "" then return res
                                    end tell
                                end try
                            end repeat
                        end repeat
                    end if
                end tell
                return ""
                """
            }
            
            var error: NSDictionary?
            if let res = NSAppleScript(source: script)?.executeAndReturnError(&error).stringValue, !res.isEmpty {
                let parts = res.components(separatedBy: "|||")
                if parts.count >= 8 {
                    let isPlaying = parts[0] == "1"
                    let title = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let artist = parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let album = parts[3].trimmingCharacters(in: .whitespacesAndNewlines)
                    let currentTime = Double(parts[4]) ?? 0
                    let duration = Double(parts[5]) ?? 0
                    let artUrl = parts[6].isEmpty ? nil : parts[6]
                    let urlStr = parts[7]
                    
                    let svc: MediaService
                    let urlLower = urlStr.lowercased()
                    if urlLower.contains("music.youtube.com") { svc = .youtubeMusic }
                    else if urlLower.contains("spotify.com") { svc = .spotify }
                    else if urlLower.contains("music.apple.com") { svc = .appleMusic }
                    else if urlLower.contains("music.amazon") { svc = .amazonMusic }
                    else if urlLower.contains("soundcloud.com") { svc = .soundcloud }
                    else if urlLower.contains("jiosaavn.com") { svc = .jioSaavn }
                    else if urlLower.contains("gaana.com") { svc = .gaana }
                    else { svc = .youtubeMusic }
                    
                    let cleanT = (svc != .generic) ? MediaService.cleanServiceTitle(title) : title
                    
                    return BrowserMediaDetection(
                        service: svc,
                        currentTime: currentTime,
                        duration: duration,
                        url: urlStr,
                        tabTitle: cleanT,
                        isMusic: true,
                        isPlaying: isPlaying,
                        rawTitle: cleanT,
                        rawArtist: artist.isEmpty ? nil : artist,
                        rawAlbum: album.isEmpty ? nil : album,
                        artworkUrl: artUrl,
                        bundleIdentifier: bId,
                        appName: name
                    )
                }
            }
        }
        return nil
    }
}
