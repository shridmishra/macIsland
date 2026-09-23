import AppKit
import SwiftUI

// MARK: - DashboardWindowController
// Coordinates the lifecycle, presentation, and activation of the Mac Island Desktop Companion window.
@MainActor
public final class DashboardWindowController: NSObject, NSWindowDelegate {
    public static let shared = DashboardWindowController()
    
    private var window: NSWindow?
    
    private override init() {
        super.init()
    }
    
    public func show() {
        let isAccessoryOnly = UserDefaults.standard.bool(forKey: "isAccessoryOnly")
        if !isAccessoryOnly {
            NSApp.setActivationPolicy(.regular)
        }
        
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let hostingView = NSHostingView(
            rootView: DesktopDashboardView()
        )
        
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        newWindow.title = "Mac Island"
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.isMovableByWindowBackground = true
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = true
        newWindow.minSize = NSSize(width: 820, height: 520)
        newWindow.contentView = hostingView
        newWindow.delegate = self
        newWindow.center()
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func toggle() {
        if let win = window, win.isVisible {
            close()
        } else {
            show()
        }
    }
    
    public func close() {
        window?.close()
        window = nil
        // Hide from Dock and Cmd+Tab when closed, keeping the notch alive in the background
        NSApp.setActivationPolicy(.accessory)
    }
    
    public func windowWillClose(_ notification: Notification) {
        window = nil
        // Hide from Dock and Cmd+Tab when closed, keeping the notch alive in the background
        NSApp.setActivationPolicy(.accessory)
    }
}
