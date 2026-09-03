import AppKit
import SwiftUI
import Combine

// MARK: - WindowManager
// Manages window geometry, screen metrics, notch adaptation, and hover transitions.
// Pinned to the top edge of the display with pure pitch-black background (#000000)
// with pixel-perfect symmetrical padding and optical centering around the camera notch.
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
    
    // MARK: - Cutout-Merged Precision Dimensions
    
    /// Dynamic collapsed width:
    /// Left wing (44pt) + Notch (156pt) + Right wing (44pt) = 244pt
    public var collapsedWidth: CGFloat {
        let hasMedia = MediaManager.shared.currentItem != nil
        if let screen = targetScreen, screen.hasNotch {
            return hasMedia ? (screen.notchWidth + 88) : (screen.notchWidth + 28)
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
    
    /// Expanded width: compact, sleek, non-intrusive (decreased from 384 to 340)
    public let expandedWidth: CGFloat = 340
    
    /// Expanded height: compact card fitting snugly below the notch (decreased from 154 to 130)
    public var expandedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight + 102
        }
        return 128
    }
    
    /// Top padding for expanded content so everything sits cleanly below the camera notch
    public var expandedTopPadding: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight + 4
        }
        return 10
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
        
        // Center horizontally on display
        let x = screen.frame.origin.x + (screen.frame.width - width) / 2.0
        
        // Pinned to the very top edge of the display
        let y = screen.frame.origin.y + screen.frame.height - height
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
