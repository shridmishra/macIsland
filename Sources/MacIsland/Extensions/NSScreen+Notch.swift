import AppKit

// MARK: - NSScreen Notch & Geometry Extensions
// In macOS, coordinate systems originate from the bottom-left corner of the primary display (0, 0),
// unlike web/iOS where (0, 0) is top-left.
// Modern MacBooks have a hardware camera notch. AppKit exposes this via `safeAreaInsets` and
// `auxiliaryTopLeftArea` / `auxiliaryTopRightArea`.
extension NSScreen {
    /// Returns true if this screen has a physical camera notch at the top.
    public var hasNotch: Bool {
        if #available(macOS 12.0, *) {
            return safeAreaInsets.top > 0
        }
        return false
    }
    
    /// Estimated notch height in points (typically ~32pt on 14" and 16" MacBook Pros).
    public var notchHeight: CGFloat {
        if #available(macOS 12.0, *), hasNotch {
            return safeAreaInsets.top
        }
        return 0
    }
    
    /// Estimated notch width in points.
    /// When a notch is present, the space between the left and right auxiliary menu bar areas
    /// represents the exact hardware notch.
    public var notchWidth: CGFloat {
        if #available(macOS 12.0, *), hasNotch {
            if let left = auxiliaryTopLeftArea, let right = auxiliaryTopRightArea {
                let calculatedWidth = frame.width - (left.width + right.width)
                if calculatedWidth > 0 {
                    return calculatedWidth
                }
            }
            // Sensible fallback for MacBook Pro hardware notch
            return 180.0
        }
        return 0
    }
    
    /// Standard menu bar height on this screen.
    public var menuBarHeight: CGFloat {
        let fullHeight = frame.height
        let visibleHeight = visibleFrame.height
        let topBar = fullHeight - (visibleFrame.origin.y - frame.origin.y + visibleHeight)
        return topBar > 0 ? topBar : 24.0
    }
}
