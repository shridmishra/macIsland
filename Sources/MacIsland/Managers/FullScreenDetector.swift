import Foundation
import AppKit
import ApplicationServices
import Combine
import SwiftUI

// MARK: - FullScreenDetector
// Monitors the active macOS Space and frontmost application in real time
// to accurately determine if the user is in full screen mode.
// Combines instantaneous system workspace notifications, low-overhead accessibility (AXUIElement)
// checks, and a lightweight safety-net heartbeat timer.
@MainActor
public final class FullScreenDetector: ObservableObject {
    public static let shared = FullScreenDetector()
    
    @Published public private(set) var isFullScreen: Bool = false
    
    private var heartbeatTimer: Timer?
    private var notificationObservers: [NSObjectProtocol] = []
    
    private init() {
        // Initial detection
        self.isFullScreen = Self.isFrontmostAppFullScreen()
        
        setupWorkspaceObservers()
        startHeartbeat()
    }
    
    deinit {
        notificationObservers.forEach {
            NSWorkspace.shared.notificationCenter.removeObserver($0)
            NotificationCenter.default.removeObserver($0)
        }
        heartbeatTimer?.invalidate()
    }
    
    // MARK: - Notification Observers
    private func setupWorkspaceObservers() {
        let workspaceNC = NSWorkspace.shared.notificationCenter
        
        // 1. Active Space changed (e.g. user swiped to/from a fullscreen space or app toggled fullscreen)
        let spaceObs = workspaceNC.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkFullScreenState()
                self?.scheduleDelayedRecheck()
            }
        }
        notificationObservers.append(spaceObs)
        
        // 2. Frontmost application changed (e.g. Cmd+Tab or clicking an app)
        let appObs = workspaceNC.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkFullScreenState()
                self?.scheduleDelayedRecheck()
            }
        }
        notificationObservers.append(appObs)
        
        // 3. Screen parameters changed (e.g. resolution change or display disconnect)
        let screenObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkFullScreenState()
                self?.scheduleDelayedRecheck()
            }
        }
        notificationObservers.append(screenObs)
    }
    
    // MARK: - Delayed Recheck After Notification
    // Instead of a continuous 0.5s heartbeat, perform a single delayed recheck
    // after each notification to catch edge cases where fullscreen transitions
    // aren't fully reported by the initial notification.
    private func startHeartbeat() {
        // No-op: replaced by scheduleDelayedRecheck() called from notification handlers
    }
    
    private func scheduleDelayedRecheck() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkFullScreenState()
            }
        }
    }
    
    // MARK: - State Check
    public func checkFullScreenState() {
        let currentStatus = Self.isFrontmostAppFullScreen()
        if self.isFullScreen != currentStatus {
            withAnimation(IslandAnimation.notchSpring) {
                self.isFullScreen = currentStatus
            }
        }
    }
    
    // MARK: - Fullscreen Detection Logic
    public static func isFrontmostAppFullScreen() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return false }
        
        // Ignore Mac Island itself if it ever reports as frontmost
        if frontApp.bundleIdentifier == Bundle.main.bundleIdentifier {
            return false
        }
        
        // Strategy 1: Check focused window of frontmost app (authoritative for active space)
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        var focusedWindow: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
           let window = focusedWindow {
            var isFS: AnyObject?
            if AXUIElementCopyAttributeValue(window as! AXUIElement, "AXFullScreen" as CFString, &isFS) == .success,
               let num = isFS as? NSNumber {
                // If the active focused window has the AXFullScreen attribute, its boolean value
                // definitively tells us whether the user is in full screen mode on this screen/space.
                // We MUST return this immediately to prevent windows on other Spaces from leaking through!
                return num.boolValue
            }
        }
        
        // Strategy 2: Window list geometry fallback (for apps with custom window servers or without AX)
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        if let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] {
            let screen = NSScreen.main ?? NSScreen.screens.first
            let screenFrame = screen?.frame ?? .zero
            if screenFrame.width > 0 && screenFrame.height > 0 {
                for win in windowList {
                    let pid = win[kCGWindowOwnerPID as String] as? pid_t
                    if pid == frontApp.processIdentifier {
                        let layer = win[kCGWindowLayer as String] as? Int ?? -1
                        if layer == 0,
                           let boundsDict = win[kCGWindowBounds as String] as? [String: Any],
                           let w = boundsDict["Width"] as? CGFloat,
                           let h = boundsDict["Height"] as? CGFloat {
                            // On macOS, a native fullscreen window spans the full screen width and essentially full screen height
                            if abs(w - screenFrame.width) < 4.0 && h >= (screenFrame.height - 40.0) {
                                return true
                            }
                        }
                    }
                }
            }
        }
        
        return false
    }
}
