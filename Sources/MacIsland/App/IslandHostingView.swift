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
        // AppKit supplies `point` in the coordinate system of the view's superview (the window).
        // Convert to local view coordinates before checking against island geometry.
        let localPoint = convert(point, from: nil)
        if isPointInIsland(localPoint) {
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
        let h = isExpanded ? WindowManager.shared.expandedHeight : WindowManager.shared.collapsedHeight
        
        let centerX = bounds.width / 2.0
        let islandRect: NSRect
        
        if isExpanded {
            let w = WindowManager.shared.expandedWidth
            let x = centerX - w / 2.0
            let y: CGFloat = isFlipped ? -2 : (bounds.height - h - 2)
            islandRect = NSRect(x: x, y: y, width: w, height: h + 2)
        } else if WindowManager.shared.hasNotch {
            let isPlaying = MediaManager.shared.playbackState.isPlaying
            let isHUD = SystemHUDManager.shared.isHUDActive
            if isPlaying || isHUD {
                let leftW: CGFloat = 44.0
                let notchW = WindowManager.shared.notchWidth
                let rightW = WindowManager.shared.currentRightWingWidth
                
                // Pinned precisely to the left of the physical camera notch:
                let x = centerX - notchW / 2.0 - leftW
                let totalW = leftW + notchW + rightW
                let y: CGFloat = isFlipped ? -2 : (bounds.height - h - 2)
                islandRect = NSRect(x: x, y: y, width: totalW, height: h + 2)
            } else {
                // When idle / nothing playing:
                // Generous hover target over the camera notch so moving cursor towards notch effortlessly triggers expansion!
                let notchW = WindowManager.shared.notchWidth
                let hoverPad: CGFloat = 16.0
                let totalW = notchW + hoverPad * 2
                let x = centerX - totalW / 2.0
                let y: CGFloat = isFlipped ? -2 : (bounds.height - h - 8)
                islandRect = NSRect(x: x, y: y, width: totalW, height: h + 10)
            }
        } else {
            let w = WindowManager.shared.collapsedWidth
            let x = centerX - w / 2.0
            let y: CGFloat = isFlipped ? -2 : (bounds.height - h - 2)
            islandRect = NSRect(x: x, y: y, width: w, height: h + 2)
        }
        
        return islandRect.contains(point)
    }
}
