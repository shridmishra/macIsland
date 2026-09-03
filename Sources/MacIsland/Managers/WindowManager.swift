import AppKit
import SwiftUI
import Combine

// MARK: - WindowManager
// Manages window geometry, screen metrics, notch adaptation, and hover transitions.
// Pinned to the top edge of the display with pure pitch-black background (#000000)
// so the island merges seamlessly with the physical camera cutout.
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
    
    // MARK: - Cutout-Merged Dimensions
    
    /// Dynamic collapsed width:
    /// Seamlessly hugs the hardware notch with compact wings on both sides.
    public var collapsedWidth: CGFloat {
        let hasMedia = MediaManager.shared.currentItem != nil
        if let screen = targetScreen, screen.hasNotch {
            // Left wing (38pt) + notchWidth (156pt) + Right wing (38pt) = 232pt
            return hasMedia ? (screen.notchWidth + 76) : (screen.notchWidth + 24)
        }
        return hasMedia ? 180 : 130
    }
    
    /// Height of the collapsed pill:
    /// Precision-matched to the physical hardware cutout height (28pt) so it merges flush.
    public var collapsedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight
        }
        return 28.0
    }
    
    /// Expanded width for generous horizontal layout
    public let expandedWidth: CGFloat = 390
    
    /// Expanded height:
    /// Encompasses the notch area at the top and provides balanced space for media controls below.
    public var expandedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight + 140
        }
        return 144
    }
    
    /// Top padding for expanded content so everything sits cleanly below the camera notch
    public var expandedTopPadding: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight + 6
        }
        return 12
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
    /// Both collapsed and expanded are pinned directly to the top edge (Y = top - height)
    /// so the black background merges seamlessly with the physical notch.
    public func windowFrame(for state: IslandState, on screen: NSScreen) -> NSRect {
        let width = state.isExpanded ? expandedWidth : collapsedWidth
        let height = state.isExpanded ? expandedHeight : collapsedHeight
        
        // Center horizontally
        let x = screen.frame.origin.x + (screen.frame.width - width) / 2.0
        
        // Pinned to the very top edge of the display
        let y = screen.frame.origin.y + screen.frame.height - height
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
