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
            return super.hitTest(point) ?? self
        }
        // Mouse event is outside the active island shape — pass through to underlying windows!
        return nil
    }
    
    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
    }
    
    // MARK: - Mouse Tracking
    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        let point = convert(event.locationInWindow, from: nil)
        let isInside = isPointInIsland(point)
        
        if isInside && !WindowManager.shared.isHovered {
            WindowManager.shared.setHovered(true)
        } else if !isInside && WindowManager.shared.isHovered {
            WindowManager.shared.setHovered(false)
        }
    }
    
    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        let point = convert(event.locationInWindow, from: nil)
        if isPointInIsland(point) {
            WindowManager.shared.setHovered(true)
        }
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        WindowManager.shared.setHovered(false)
    }
    
    // MARK: - Trackpad Gestures (Swipe & Two-Finger Scroll)
    
    private var lastGestureTime = Date.distantPast
    private var accumulatedDeltaX: CGFloat = 0.0
    private var accumulatedDeltaY: CGFloat = 0.0
    
    public override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        
        let point = convert(event.locationInWindow, from: nil)
        guard isPointInIsland(point) else { return }
        
        let now = Date()
        guard now.timeIntervalSince(lastGestureTime) > 0.35 else { return }
        
        if event.phase == .began {
            accumulatedDeltaX = 0
            accumulatedDeltaY = 0
        }
        
        accumulatedDeltaX += event.scrollingDeltaX
        accumulatedDeltaY += event.scrollingDeltaY
        
        let isExpanded = WindowManager.shared.islandState.isExpanded
        
        if isExpanded {
            // Check for vertical swipe up to collapse ("upside")
            if accumulatedDeltaY > 24.0 {
                lastGestureTime = now
                accumulatedDeltaX = 0
                accumulatedDeltaY = 0
                Task { @MainActor in
                    WindowManager.shared.collapse()
                }
                return
            }
            
            // Check for horizontal two-finger swipe to change pages
            if accumulatedDeltaX < -28.0 {
                // Flicked left -> navigate forward (Media -> Timer)
                lastGestureTime = now
                accumulatedDeltaX = 0
                accumulatedDeltaY = 0
                Task { @MainActor in
                    WindowManager.shared.nextPage()
                }
                return
            } else if accumulatedDeltaX > 28.0 {
                // Flicked right -> navigate backward (Timer -> Media)
                lastGestureTime = now
                accumulatedDeltaX = 0
                accumulatedDeltaY = 0
                Task { @MainActor in
                    WindowManager.shared.previousPage()
                }
                return
            }
        } else {
            // Collapsed state: Two-finger swipe down to expand
            if accumulatedDeltaY < -24.0 {
                lastGestureTime = now
                accumulatedDeltaX = 0
                accumulatedDeltaY = 0
                Task { @MainActor in
                    WindowManager.shared.expand()
                }
                return
            }
        }
        
        if event.phase == .ended || event.phase == .cancelled {
            accumulatedDeltaX = 0
            accumulatedDeltaY = 0
        }
    }
    
    public override func swipe(with event: NSEvent) {
        super.swipe(with: event)
        let point = convert(event.locationInWindow, from: nil)
        guard isPointInIsland(point) else { return }
        
        let isExpanded = WindowManager.shared.islandState.isExpanded
        if isExpanded {
            if event.deltaY > 0 {
                // Swipe up -> collapse
                Task { @MainActor in
                    WindowManager.shared.collapse()
                }
            } else if event.deltaX < 0 {
                // Swipe left -> next page
                Task { @MainActor in
                    WindowManager.shared.nextPage()
                }
            } else if event.deltaX > 0 {
                // Swipe right -> previous page
                Task { @MainActor in
                    WindowManager.shared.previousPage()
                }
            }
        } else {
            if event.deltaY < 0 {
                Task { @MainActor in
                    WindowManager.shared.expand()
                }
            }
        }
    }
    
    // MARK: - Geometry Helper
    private func isPointInIsland(_ point: NSPoint) -> Bool {
        let isExpanded = WindowManager.shared.islandState.isExpanded
        let h = isExpanded ? WindowManager.shared.expandedHeight : WindowManager.shared.collapsedHeight
        
        // Strict boundary protection: When collapsed, any point at or below the physical notch height
        // is strictly in the underlying window's domain (e.g. Chrome tab strip). It must NEVER be captured.
        if !isExpanded {
            let effectiveMaxY = h - 1.0
            if isFlipped {
                if point.y >= effectiveMaxY {
                    return false
                }
            } else {
                if point.y <= (bounds.height - effectiveMaxY) {
                    return false
                }
            }
        }
        
        let centerX = bounds.width / 2.0
        let islandRect: NSRect
        
        if isExpanded {
            let w = WindowManager.shared.expandedWidth
            let x = centerX - w / 2.0
            let y: CGFloat = isFlipped ? -2 : (bounds.height - h - 2)
            islandRect = NSRect(x: x, y: y, width: w, height: h + 2)
        } else if WindowManager.shared.hasNotch {
            let effectiveH = max(0, h - 1.0)
            if WindowManager.shared.hasActiveWings {
                let leftW = WindowManager.shared.currentLeftWingWidth
                let notchW = WindowManager.shared.notchWidth
                let rightW = WindowManager.shared.currentRightWingWidth
                
                // Pinned precisely to the left of the physical camera notch:
                let x = centerX - notchW / 2.0 - leftW
                let totalW = leftW + notchW + rightW
                let y: CGFloat = isFlipped ? -2 : (bounds.height - effectiveH)
                islandRect = NSRect(x: x, y: y, width: totalW, height: isFlipped ? (effectiveH + 2) : effectiveH)
            } else {
                // When idle / hidden in fullscreen:
                // Camera notch target exactly matching physical notch, strictly clamped vertically
                // to prevent any bleed into Chrome tabs or underlying application windows!
                let notchW = WindowManager.shared.notchWidth
                let totalW = notchW
                let x = centerX - totalW / 2.0
                let y: CGFloat = isFlipped ? -2 : (bounds.height - effectiveH)
                islandRect = NSRect(x: x, y: y, width: totalW, height: isFlipped ? (effectiveH + 2) : effectiveH)
            }
        } else {
            let effectiveH = max(0, h - 1.0)
            let w = WindowManager.shared.hasActiveWings ? WindowManager.shared.collapsedWidth : 160.0
            let x = centerX - w / 2.0
            let y: CGFloat = isFlipped ? -2 : (bounds.height - effectiveH)
            islandRect = NSRect(x: x, y: y, width: w, height: isFlipped ? (effectiveH + 2) : effectiveH)
        }
        
        return islandRect.contains(point)
    }
}
