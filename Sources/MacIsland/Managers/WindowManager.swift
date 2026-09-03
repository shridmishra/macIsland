import AppKit
import SwiftUI
import Combine

// MARK: - WindowManager
// Manages window geometry, screen metrics, notch adaptation, and hover transitions.
// Guarantees that on notched MacBooks, NO content is ever placed behind the physical camera cutout:
// - In collapsed mode: Information is placed strictly in the side "wings" (left & right of the cutout).
// - In expanded mode: All interactive UI sits completely below the cutout.
@MainActor
public final class WindowManager: ObservableObject {
    public static let shared = WindowManager()
    
    @Published public private(set) var islandState: IslandState = .collapsed
    @Published public private(set) var isHovered: Bool = false
    
    /// Target screen where Mac Island is currently docked
    public var targetScreen: NSScreen? {
        NSScreen.main ?? NSScreen.screens.first
    }
    
    public var hasNotch: Bool {
        targetScreen?.hasNotch ?? false
    }
    
    public var notchWidth: CGFloat {
        targetScreen?.notchWidth ?? 0
    }
    
    public var notchHeight: CGFloat {
        targetScreen?.notchHeight ?? 0
    }
    
    // MARK: - Notch-Safe Dimensions
    
    /// Dynamic collapsed width:
    /// On notched displays, spans across the notch so content sits in the side wings.
    public var collapsedWidth: CGFloat {
        let hasMedia = MediaManager.shared.currentItem != nil
        if let screen = targetScreen, screen.hasNotch {
            // Symmetrical wings on both sides of the hardware cutout:
            // ~120pt left wing + notchWidth + ~120pt right wing
            return hasMedia ? (screen.notchWidth + 240) : (screen.notchWidth + 60)
        }
        return hasMedia ? 240 : 180
    }
    
    /// Height of the collapsed pill (matches or slightly exceeds notch height)
    public var collapsedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return max(screen.notchHeight + 4, 34)
        }
        return 34
    }
    
    /// Width for the expanded card
    public let expandedWidth: CGFloat = 420
    
    /// Height for the expanded card:
    /// On notched displays, extends downward to provide ample room below the hardware notch.
    public var expandedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight + 156
        }
        return 152
    }
    
    /// Top padding for expanded content so everything is 100% outside and below the cutout
    public var expandedTopPadding: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight + 6
        }
        return 14
    }
    
    private var collapseDebounceTimer: Timer?
    public var onStateChanged: ((IslandState) -> Void)?
    
    public init() {}
    
    public func setHovered(_ hovered: Bool) {
        isHovered = hovered
        
        if hovered {
            collapseDebounceTimer?.invalidate()
            collapseDebounceTimer = nil
            
            if islandState != .expanded {
                expand()
            }
        } else {
            // 450ms debounce timer prevents accidental collapse when moving cursor
            collapseDebounceTimer?.invalidate()
            collapseDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, !self.isHovered else { return }
                    self.collapse()
                }
            }
        }
    }
    
    public func expand() {
        collapseDebounceTimer?.invalidate()
        collapseDebounceTimer = nil
        islandState = .expanded
        onStateChanged?(.expanded)
    }
    
    public func collapse() {
        islandState = .collapsed
        onStateChanged?(.collapsed)
    }
    
    public func toggle() {
        if islandState == .expanded {
            collapse()
        } else {
            expand()
        }
    }
    
    /// Computes the exact screen frame in AppKit coordinates (bottom-left origin).
    public func windowFrame(for state: IslandState, on screen: NSScreen) -> NSRect {
        let width = state.isExpanded ? expandedWidth : collapsedWidth
        let height = state.isExpanded ? expandedHeight : collapsedHeight
        
        // Center horizontally
        let x = screen.frame.origin.x + (screen.frame.width - width) / 2.0
        
        // Anchor to the top edge of the display
        let y = screen.frame.origin.y + screen.frame.height - height
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
