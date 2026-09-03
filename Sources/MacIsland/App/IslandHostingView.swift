import AppKit
import SwiftUI

// MARK: - IslandHostingView
// Custom NSHostingView subclass that attaches an active NSTrackingArea.
//
// Key macOS AppKit concept:
// On macOS, floating panels that do not take keyboard focus need an `NSTrackingArea`
// configured with `.activeAlways` to receive mouseEntered and mouseExited events reliably,
// even when other applications (like Xcode, Chrome, or Terminal) have active focus.
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
    
    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        Task { @MainActor in
            WindowManager.shared.setHovered(true)
        }
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        Task { @MainActor in
            WindowManager.shared.setHovered(false)
        }
    }
}
