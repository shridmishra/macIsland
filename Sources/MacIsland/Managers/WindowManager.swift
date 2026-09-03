import AppKit
import SwiftUI
import Combine

// MARK: - WindowManager
// Manages window geometry, screen metrics, notch adaptation, and hover transitions.
// - Collapsed: Sits flush in the menu bar as two independent transparent glass wings flanking the notch.
// - Expanded: Floats elegantly directly below the notch/menu bar as a compact, translucent liquid glass card.
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
    
    // MARK: - Precision Hardware & Popover Dimensions
    
    /// Dynamic collapsed width:
    /// Hugs the hardware notch closely with compact, subtle wings.
    public var collapsedWidth: CGFloat {
        let hasMedia = MediaManager.shared.currentItem != nil
        if let screen = targetScreen, screen.hasNotch {
            // Left wing (36pt) + notchWidth (156pt) + Right wing (36pt) = 228pt
            return hasMedia ? (screen.notchWidth + 72) : (screen.notchWidth + 24)
        }
        return hasMedia ? 180 : 130
    }
    
    /// Height of the collapsed pill:
    /// Precision-matched to the exact hardware cutout height (28pt) so it sits flush in the menu bar.
    public var collapsedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight
        }
        return 28.0
    }
    
    /// Compact expanded width for sleek floating card (room for titles without truncation)
    public let expandedWidth: CGFloat = 390
    
    /// Compact expanded height (tight vertical rhythm without empty voids)
    public let expandedHeight: CGFloat = 140
    
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
    /// - Collapsed: Pinned flush to the top edge (Y = top - collapsedHeight) inside the menu bar.
    /// - Expanded: Floats directly below the menu bar / notch (Y = top - menuBarHeight - expandedHeight - 4).
    public func windowFrame(for state: IslandState, on screen: NSScreen) -> NSRect {
        let width = state.isExpanded ? expandedWidth : collapsedWidth
        let height = state.isExpanded ? expandedHeight : collapsedHeight
        
        // Center horizontally
        let x = screen.frame.origin.x + (screen.frame.width - width) / 2.0
        
        let y: CGFloat
        if state.isExpanded {
            // Float smoothly 4pt below the menu bar / notch so all 4 glass corners are rounded
            // and the menu bar is 100% uncovered!
            let menuHeight = screen.hasNotch ? screen.notchHeight : screen.menuBarHeight
            y = screen.frame.origin.y + screen.frame.height - menuHeight - height - 4.0
        } else {
            // Pinned flush to top edge inside the menu bar
            y = screen.frame.origin.y + screen.frame.height - height
        }
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
