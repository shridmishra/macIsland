import AppKit
import SwiftUI

// MARK: - AppDelegate
// Manages the application lifecycle, menu-bar status icon, and system integration.
//
// Key macOS AppKit concept:
// `NSApplication.ActivationPolicy.accessory`:
// Configures the app to run as an accessory (background utility).
// It does NOT clutter the macOS Dock, but stays running continuously in the menu bar/top screen.
@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?
    private var statusItem: NSStatusItem?
    
    public override init() {
        super.init()
        AppDelegate.shared = self
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Read user preference: defaults to Desktop App mode (.regular with Dock icon)
        let isAccessory = UserDefaults.standard.bool(forKey: "isAccessoryOnly")
        let policy: NSApplication.ActivationPolicy = isAccessory ? .accessory : .regular
        NSApplication.shared.setActivationPolicy(policy)
        
        // Start system HUD manager for volume and brightness indicators
        _ = SystemHUDManager.shared
        
        // Start battery HUD manager for real-time charging and power status notifications
        _ = BatteryHUDManager.shared
        
        // Launch and present the Island panel (pass-through transparent canvas)
        IslandWindowController.shared.showIsland()
        
        // Present Desktop Dashboard on initial launch if in regular desktop mode
        if !isAccessory {
            DashboardWindowController.shared.show()
        }
        
        // Setup a minimal menu bar item for status and Quit option
        setupStatusItem()
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Re-open/focus the Desktop Companion window when user clicks Dock icon or launches from Finder
        DashboardWindowController.shared.show()
        return true
    }
    
    public func updateActivationPolicy(isAccessory: Bool) {
        let policy: NSApplication.ActivationPolicy = isAccessory ? .accessory : .regular
        NSApplication.shared.setActivationPolicy(policy)
        if !isAccessory {
            DashboardWindowController.shared.show()
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem?.button else { return }
        
        button.image = NSImage(systemSymbolName: "circle.circle", accessibilityDescription: "Mac Island")
        button.action = #selector(statusItemClicked)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    
    @objc private func statusItemClicked() {
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "Mac Island", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        let dashboardItem = NSMenuItem(
            title: "Open Mac Island Dashboard...",
            action: #selector(openDashboard),
            keyEquivalent: "d"
        )
        dashboardItem.target = self
        menu.addItem(dashboardItem)
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(
            title: WindowManager.shared.islandState.isExpanded ? "Collapse Island" : "Expand Island",
            action: #selector(toggleIsland),
            keyEquivalent: "e"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let timerItem = NSMenuItem(
            title: PomodoroManager.shared.isTimerInNotchEnabled ? "Hide Timer in Notch" : "Show Timer in Notch",
            action: #selector(toggleTimerInNotch),
            keyEquivalent: "t"
        )
        timerItem.target = self
        menu.addItem(timerItem)
        
        let lyricsItem = NSMenuItem(
            title: LyricsManager.shared.isLyricsEnabled ? "Hide Lyrics in Notch" : "Show Lyrics in Notch",
            action: #selector(toggleLyrics),
            keyEquivalent: "l"
        )
        lyricsItem.target = self
        menu.addItem(lyricsItem)
        
        let romanizeItem = NSMenuItem(
            title: LyricsManager.shared.isRomanizationEnabled ? "✓ Romanize Non-Latin Lyrics" : "Romanize Non-Latin Lyrics",
            action: #selector(toggleRomanization),
            keyEquivalent: "r"
        )
        romanizeItem.target = self
        menu.addItem(romanizeItem)
        
        // Lyrics Timing / Anticipation offset submenu
        let timingMenu = NSMenu(title: "Lyrics Timing")
        let currentOffset = LyricsManager.shared.syncOffset
        
        let presets: [(title: String, offset: Double)] = [
            ("Exact on Beat (0.0s)", 0.0),
            ("A Bit Ahead (0.6s)", 0.6),
            ("Standard Lead (1.0s)", 1.0),
            ("Early Preview (1.5s)", 1.5)
        ]
        for preset in presets {
            let item = NSMenuItem(
                title: (abs(currentOffset - preset.offset) < 0.05) ? "✓ \(preset.title)" : preset.title,
                action: #selector(setLyricsTimingPreset(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = preset.offset
            timingMenu.addItem(item)
        }
        
        timingMenu.addItem(NSMenuItem.separator())
        
        let nudgeEarlier = NSMenuItem(title: "Nudge Earlier (+0.2s)", action: #selector(nudgeLyricsEarlier), keyEquivalent: "")
        nudgeEarlier.target = self
        timingMenu.addItem(nudgeEarlier)
        
        let nudgeLater = NSMenuItem(title: "Nudge Later (-0.2s)", action: #selector(nudgeLyricsLater), keyEquivalent: "")
        nudgeLater.target = self
        timingMenu.addItem(nudgeLater)
        
        let timingParent = NSMenuItem(title: "Lyrics Timing (\(String(format: "%.1fs", currentOffset)))", action: nil, keyEquivalent: "")
        timingParent.submenu = timingMenu
        menu.addItem(timingParent)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Mac Island", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // Clear so regular clicks work again
    }
    
    @objc private func openDashboard() {
        DashboardWindowController.shared.show()
    }
    
    @objc private func toggleIsland() {
        WindowManager.shared.toggle()
    }
    
    @objc private func toggleTimerInNotch() {
        PomodoroManager.shared.toggleTimerInNotch()
    }
    
    @objc private func toggleLyrics() {
        LyricsManager.shared.toggleLyrics()
    }
    
    @objc private func toggleRomanization() {
        LyricsManager.shared.toggleRomanization()
    }
    
    @objc private func setLyricsTimingPreset(_ sender: NSMenuItem) {
        if let offset = sender.representedObject as? Double {
            LyricsManager.shared.setSyncOffset(offset)
        }
    }
    
    @objc private func nudgeLyricsEarlier() {
        LyricsManager.shared.nudgeSyncOffset(by: 0.2)
    }
    
    @objc private func nudgeLyricsLater() {
        LyricsManager.shared.nudgeSyncOffset(by: -0.2)
    }
    
    @objc public func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        SystemHUDManager.shared.restoreNativeOSD()
    }
}

