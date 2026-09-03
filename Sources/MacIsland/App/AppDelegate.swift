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
    private var statusItem: NSStatusItem?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as accessory utility (no Dock icon)
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Start system HUD manager for volume and brightness indicators
        _ = SystemHUDManager.shared
        
        // Start battery HUD manager for real-time charging and power status notifications
        _ = BatteryHUDManager.shared
        
        // Launch and present the Island panel
        IslandWindowController.shared.showIsland()
        
        // Setup a minimal menu bar item for status and Quit option
        setupStatusItem()
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
        
        menu.addItem(NSMenuItem(title: "Mac Island", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(
            title: WindowManager.shared.islandState.isExpanded ? "Collapse Island" : "Expand Island",
            action: #selector(toggleIsland),
            keyEquivalent: "e"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Mac Island", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil // Clear so regular clicks work again
    }
    
    @objc private func toggleIsland() {
        WindowManager.shared.toggle()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        SystemHUDManager.shared.restoreNativeOSD()
    }
}
