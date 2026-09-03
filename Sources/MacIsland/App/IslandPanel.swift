import AppKit
import SwiftUI

// MARK: - IslandPanel
// Custom NSPanel subclass providing the borderless, transparent floating window.
//
// Key macOS AppKit concepts:
// 1. `NSPanel`: Specialized lightweight window that supports `.nonactivatingPanel`.
//    This allows user interaction (clicking play/pause) WITHOUT deactivating or stealing
//    focus from the user's active code editor, terminal, or browser window.
// 2. `level = .statusBar`: Positions the panel at the menu-bar elevation, above normal windows.
// 3. `collectionBehavior`:
//    - `.canJoinAllSpaces`: Follows the user across all virtual desktops/Spaces.
//    - `.fullScreenAuxiliary`: Remains visible even when a fullscreen application is active.
//    - `.stationary`: Remains in place during Mission Control gestures.
//    - `.ignoresCycle`: Prevents Cmd+` from cycling keyboard focus into this utility.
public final class IslandPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [
                .borderless,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )
        
        // Transparent background
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        
        // Window level and space behavior
        self.level = .statusBar
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        
        // Interaction behavior
        self.acceptsMouseMovedEvents = true
        self.isMovableByWindowBackground = false
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
    }
    
    // Ensure the panel does not steal main/key window status from the active app
    public override var canBecomeKey: Bool {
        false
    }
    
    public override var canBecomeMain: Bool {
        false
    }
}
