import AppKit
import SwiftUI

// MARK: - IslandHostingView
// High-performance NSHostingView subclass that hosts the fluid Dynamic Island.
//
// Key architectural innovations:
// 1. Fixed Transparent Canvas: The window remains stable at maximum dimensions,
//    eliminating all AppKit WindowServer frame resize lag, desynchronization, and clipping.
// 2. Intelligent Hit-Testing Pass-Through: hitTest(_:) only captures mouse events
//    when the cursor is physically within the current animated island bounds.
//    Clicks and hovers outside the active island pass directly through to background apps.
// 3. Continuous Mouse Tracking: Drives instant 120Hz SwiftUI hover transitions.
public final class IslandHostingView<Content: View>: NSHostingView<Content> {
    private var trackingArea: NSTrackingArea?
    
    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        
        let newArea = NSTrackingArea(
            rect: bounds,
            options: [
                .mouseEnteredAndExited,
                .mouseMoved,
                .activeAlways,
                .inVisibleRect
            ],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(newArea)
        trackingArea = newArea
    }
    
    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    // MARK: - Precise Pass-Through Hit-Testing
    public override func hitTest(_ point: NSPoint) -> NSView? {
        if isPointInIsland(point) {
            return super.hitTest(point)
        }
        // Mouse event is outside the active island shape — pass through to underlying windows!
        return nil
    }
    
    // MARK: - Mouse Tracking
    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let point = convert(event.locationInWindow, from: nil)
        let isInside = isPointInIsland(point)
        
        if isInside && !WindowManager.shared.isHovered {
            Task { @MainActor in
                WindowManager.shared.setHovered(true)
            }
        } else if !isInside && WindowManager.shared.isHovered {
            Task { @MainActor in
                WindowManager.shared.setHovered(false)
            }
        }
    }
    
    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        let point = convert(event.locationInWindow, from: nil)
        if isPointInIsland(point) {
            Task { @MainActor in
                WindowManager.shared.setHovered(true)
            }
        }
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        Task { @MainActor in
            WindowManager.shared.setHovered(false)
        }
    }
    
    // MARK: - Geometry Helper
    private func isPointInIsland(_ point: NSPoint) -> Bool {
        let isExpanded = WindowManager.shared.islandState.isExpanded
        let w = isExpanded ? WindowManager.shared.expandedWidth : WindowManager.shared.collapsedWidth
        let h = isExpanded ? WindowManager.shared.expandedHeight : WindowManager.shared.collapsedHeight
        
        // In AppKit coordinate system, (0, 0) is bottom-left.
        // The island is anchored to the top of the hosting view bounds:
        let x = (bounds.width - w) / 2.0
        let y = bounds.height - h
        let islandRect = NSRect(x: x, y: y, width: w, height: h)
        
        return islandRect.contains(point)
    }
}
