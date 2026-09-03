import Foundation
import AppKit
import os.log

// MARK: - MediaSourceNavigator
// Directs the user immediately to the active browser tab or native media application
// where audio/video is currently playing.
//
// Key capabilities:
// 1. Web Browsers (Brave, Chrome, Safari, Edge, Arc, Opera, Vivaldi):
//    - Scans open windows and tabs across all browser instances
//    - Matches via a priority scoring system:
//      * Exact URL / Tab URL match (+150)
//      * Track title / clean title keyword match (+100)
//      * Streaming service domain match (+50, e.g. music.youtube.com, netflix.com)
//      * Artist name keyword match (+25)
//    - Un-minimizes the target window if minimized
//    - Sets the target tab as the active tab
//    - Raises the target window to index 1
//    - Activates the browser and brings it to frontmost focus
// 2. Native Applications (Spotify, Apple Music, QuickTime Player, TV, Podcasts, etc.):
//    - Activates the process directly via NSRunningApplication
//    - Reopens and raises the window via AppleScript
// 3. Thread safety: All AppleScript and process executions execute asynchronously on
//    background queues to keep the SwiftUI 120Hz display pipeline completely stutter-free.
public final class MediaSourceNavigator: @unchecked Sendable {
    public static let shared = MediaSourceNavigator()
    
    private let logger = Logger(subsystem: "com.macisland.app", category: "MediaSourceNavigator")
    private let executionQueue = DispatchQueue(label: "com.macisland.source.navigator", qos: .userInitiated)
    
    private init() {}
    
    /// Navigates to the active media source (browser tab or native app) for the provided MediaItem.
    public func openSource(for item: MediaItem) {
        executionQueue.async { [weak self] in
            guard let self = self else { return }
            self.logger.info("🚀 Navigating to source for track: '\(item.title, privacy: .public)' (app: \(item.application, privacy: .public), service: \(item.service.rawValue, privacy: .public))")
            
            if item.isBrowserMedia {
                self.navigateToBrowserTab(for: item)
            } else {
                self.navigateToNativeApp(for: item)
            }
        }
    }
    
    // MARK: - Web Browser Tab Navigation
    private func navigateToBrowserTab(for item: MediaItem) {
        let (targetAppName, bundleId) = resolveBrowserIdentity(for: item)
        
        // Clean words for robust substring matching in AppleScript
        let cleanedTitle = cleanSearchKeyword(item.displayTitle.isEmpty ? item.title : item.displayTitle)
        let cleanedArtist = cleanSearchKeyword(item.artist)
        let serviceKeywords = item.service.domainKeywords
        let primaryServiceDomain = serviceKeywords.first ?? ""
        let directUrl = item.url ?? ""
        
        logger.info("🔍 Browser search: app='\(targetAppName)', title='\(cleanedTitle)', service='\(primaryServiceDomain)', bundleId='\(bundleId ?? "nil")'")
        
        if bundleId == "com.apple.Safari" || targetAppName.lowercased() == "safari" {
            navigateSafari(
                cleanedTitle: cleanedTitle,
                cleanedArtist: cleanedArtist,
                serviceDomain: primaryServiceDomain,
                directUrl: directUrl
            )
        } else {
            // Chromium-based browsers: Brave, Google Chrome, Microsoft Edge, Opera, Vivaldi, Arc
            navigateChromiumBrowser(
                appName: targetAppName,
                bundleId: bundleId,
                cleanedTitle: cleanedTitle,
                cleanedArtist: cleanedArtist,
                serviceDomain: primaryServiceDomain,
                directUrl: directUrl
            )
        }
    }
    
    private func resolveBrowserIdentity(for item: MediaItem) -> (appName: String, bundleId: String?) {
        var bundleId = item.bundleIdentifier
        var appName = item.application
        
        if bundleId == nil || bundleId?.contains("helper") == true || bundleId?.contains("Media Player") == true {
            let lower = (item.application + " " + (bundleId ?? "")).lowercased()
            if lower.contains("brave") {
                bundleId = "com.brave.Browser"
                appName = "Brave Browser"
            } else if lower.contains("chrome") {
                bundleId = "com.google.Chrome"
                appName = "Google Chrome"
            } else if lower.contains("safari") {
                bundleId = "com.apple.Safari"
                appName = "Safari"
            } else if lower.contains("edge") {
                bundleId = "com.microsoft.edgemac"
                appName = "Microsoft Edge"
            } else if lower.contains("arc") {
                bundleId = "company.thebrowser.Arc"
                appName = "Arc"
            } else if lower.contains("opera") {
                bundleId = "com.operasoftware.Opera"
                appName = "Opera"
            } else if lower.contains("vivaldi") {
                bundleId = "com.vivaldi.Vivaldi"
                appName = "Vivaldi"
            } else if lower.contains("firefox") {
                bundleId = "org.mozilla.firefox"
                appName = "Firefox"
            }
        }
        
        // If still unresolved, scan running applications to find which browser is running
        if bundleId == nil || appName == "Media Player" || appName.isEmpty {
            for app in NSWorkspace.shared.runningApplications {
                guard let bId = app.bundleIdentifier, let name = app.localizedName else { continue }
                if MediaService.browserBundleIds.contains(bId) {
                    bundleId = bId
                    appName = name
                    break
                }
            }
        }
        
        if appName == "Media Player" {
            appName = "Brave Browser"
        }
        
        return (appName, bundleId)
    }
    
    // MARK: - Chromium-Based Browsers Navigation
    private func navigateChromiumBrowser(
        appName: String,
        bundleId: String?,
        cleanedTitle: String,
        cleanedArtist: String,
        serviceDomain: String,
        directUrl: String
    ) {
        let script = """
        tell application "\(appName)"
            if not running then
                activate
                return "not_running"
            end if
            
            set bestW to missing value
            set bestT to 0
            set bestScore to 0
            
            repeat with w in windows
                set tIdx to 0
                repeat with t in tabs of w
                    set tIdx to tIdx + 1
                    set tUrl to ""
                    set tTitle to ""
                    try
                        set tUrl to (URL of t) as text
                    end try
                    try
                        set tTitle to (title of t) as text
                    end try
                    
                    set currentScore to 0
                    
                    -- Tier 1: Direct URL exact or prefix match (+150)
                    if "\(directUrl)" is not "" and (tUrl contains "\(directUrl)" or "\(directUrl)" contains tUrl) then
                        set currentScore to currentScore + 150
                    end if
                    
                    -- Tier 2: Clean title word match (+100)
                    if "\(cleanedTitle)" is not "" and tTitle contains "\(cleanedTitle)" then
                        set currentScore to currentScore + 100
                    end if
                    
                    -- Tier 3: Service domain match (+50)
                    if "\(serviceDomain)" is not "" and tUrl contains "\(serviceDomain)" then
                        set currentScore to currentScore + 50
                    end if
                    
                    -- Tier 4: Artist match (+25)
                    if "\(cleanedArtist)" is not "" and (tTitle contains "\(cleanedArtist)" or tUrl contains "\(cleanedArtist)") then
                        set currentScore to currentScore + 25
                    end if
                    
                    if currentScore > bestScore then
                        set bestScore to currentScore
                        set bestW to w
                        set bestT to tIdx
                    end if
                end repeat
            end repeat
            
            if bestScore > 0 and bestW is not missing value then
                try
                    if minimized of bestW is true then set minimized of bestW to false
                end try
                set active tab index of bestW to bestT
                set index of bestW to 1
                activate
                return "focused_tab score " & bestScore & " tab " & bestT
            else
                activate
                return "focused_app"
            end if
        end tell
        """
        
        runAppleScript(script)
        
        // Ensure application focus via AppKit
        if let bId = bundleId, let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bId).first {
            DispatchQueue.main.async {
                runningApp.activate(options: [.activateAllWindows])
            }
        }
    }
    
    // MARK: - Safari Navigation
    private func navigateSafari(
        cleanedTitle: String,
        cleanedArtist: String,
        serviceDomain: String,
        directUrl: String
    ) {
        let script = """
        tell application "Safari"
            if not running then
                activate
                return "not_running"
            end if
            
            set bestW to missing value
            set bestT to missing value
            set bestScore to 0
            
            repeat with w in windows
                repeat with t in tabs of w
                    set tUrl to ""
                    set tTitle to ""
                    try
                        set tUrl to (URL of t) as text
                    end try
                    try
                        set tTitle to (name of t) as text
                    end try
                    
                    set currentScore to 0
                    
                    if "\(directUrl)" is not "" and (tUrl contains "\(directUrl)" or "\(directUrl)" contains tUrl) then
                        set currentScore to currentScore + 150
                    end if
                    
                    if "\(cleanedTitle)" is not "" and tTitle contains "\(cleanedTitle)" then
                        set currentScore to currentScore + 100
                    end if
                    
                    if "\(serviceDomain)" is not "" and tUrl contains "\(serviceDomain)" then
                        set currentScore to currentScore + 50
                    end if
                    
                    if "\(cleanedArtist)" is not "" and (tTitle contains "\(cleanedArtist)" or tUrl contains "\(cleanedArtist)") then
                        set currentScore to currentScore + 25
                    end if
                    
                    if currentScore > bestScore then
                        set bestScore to currentScore
                        set bestW to w
                        set bestT to t
                    end if
                end repeat
            end repeat
            
            if bestScore > 0 and bestW is not missing value and bestT is not missing value then
                try
                    if miniaturized of bestW is true then set miniaturized of bestW to false
                end try
                set current tab of bestW to bestT
                set index of bestW to 1
                activate
                return "focused_safari_tab"
            else
                activate
                return "focused_safari_app"
            end if
        end tell
        """
        
        runAppleScript(script)
        
        if let safariApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Safari").first {
            DispatchQueue.main.async {
                safariApp.activate(options: [.activateAllWindows])
            }
        }
    }
    
    // MARK: - Native Desktop App Navigation
    private func navigateToNativeApp(for item: MediaItem) {
        let appName = item.application
        let bundleId = item.bundleIdentifier
        
        // 1. AppKit activation
        if let bId = bundleId, let app = NSRunningApplication.runningApplications(withBundleIdentifier: bId).first {
            DispatchQueue.main.async {
                app.activate(options: [.activateAllWindows])
            }
        } else {
            for app in NSWorkspace.shared.runningApplications {
                if let name = app.localizedName,
                   name.localizedCaseInsensitiveContains(appName) || appName.localizedCaseInsensitiveContains(name) {
                    DispatchQueue.main.async {
                        app.activate(options: [.activateAllWindows])
                    }
                    break
                }
            }
        }
        
        // 2. AppleScript activation with window reopen to restore un-minimized window
        let targetName = resolveNativeAppName(appName: appName, bundleId: bundleId)
        let script = """
        tell application "\(targetName)"
            reopen
            activate
        end tell
        tell application "System Events"
            try
                tell process "\(targetName)"
                    set frontmost to true
                end tell
            end try
        end tell
        """
        runAppleScript(script)
    }
    
    private func resolveNativeAppName(appName: String, bundleId: String?) -> String {
        if let bId = bundleId {
            if bId == "com.apple.Music" { return "Music" }
            if bId == "com.spotify.client" { return "Spotify" }
            if bId == "com.apple.QuickTimePlayerX" { return "QuickTime Player" }
            if bId == "com.apple.tv" { return "TV" }
            if bId == "com.apple.podcasts" { return "Podcasts" }
        }
        if appName.contains("Music") { return "Music" }
        if appName.contains("Spotify") { return "Spotify" }
        if appName.contains("QuickTime") { return "QuickTime Player" }
        return appName
    }
    
    // MARK: - Helper Methods
    private func cleanSearchKeyword(_ input: String) -> String {
        let stripped = input
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "\\", with: "")
            .filter { $0.isLetter || $0.isNumber || $0.isWhitespace }
        let words = stripped.split(separator: " ").prefix(2).joined(separator: " ")
        return words.isEmpty ? String(stripped.prefix(8)) : words
    }
    
    private func runAppleScript(_ source: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            logger.error("❌ AppleScript execution error: \(error.localizedDescription, privacy: .public)")
        }
    }
}
