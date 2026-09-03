import Foundation
import AppKit
import Combine

// MARK: - WindowManager
// Central manager for the Island's screen placement, notch geometry, and expanded dimensions.
// Provides precise notch-flush positioning and generous, comfortable padding around content:
// - Reduced top padding: pulls content comfortably closer below the notch cutout
// - Added left, right, and bottom padding for spacious, premium breathing room
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
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchWidth + 88
        }
        return 180
    }
    
    /// Height of the collapsed pill:
    /// Precision-matched to the physical hardware cutout height (28pt) so it merges flush.
    public var collapsedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight
        }
        return 28.0
    }
    
    /// Expanded width: generous 25pt side margins for spacious, comfortable layout (374pt)
    public let expandedWidth: CGFloat = 374
    
    /// Expanded height: calibrated with reduced top padding and increased bottom clearance (152pt)
    public var expandedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight + 124
        }
        return 150
    }
    
    /// Reduced top padding: content sits 6pt cleanly below the camera notch without excessive empty space
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
        islandState = .expanded
        onStateChanged?(.expanded)
    }
    
    public func collapse() {
        islandState = .collapsed
        onStateChanged?(.collapsed)
    }
    
    public func toggle() {
        if islandState.isExpanded {
            collapse()
        } else {
            expand()
        }
    }
    
    /// Calculates the origin and dimensions of the panel anchored to the top of the display
    public func windowFrame(for state: IslandState, on screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let width = expandedWidth
        let height = expandedHeight
        
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2.0
        let y = screenFrame.origin.y + screenFrame.height - height
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
