import AppKit
import SwiftUI
import Combine

// MARK: - WindowManager
// Manages the state, dimensions, animations, and hover transitions for the Island window.
// Ensures that hovering triggers instant smooth expansion while mouse exit uses a short
// debounce (hysteresis) to prevent accidental collapse when reaching for playback controls.
@MainActor
public final class WindowManager: ObservableObject {
    public static let shared = WindowManager()
    
    @Published public private(set) var islandState: IslandState = .collapsed
    @Published public private(set) var isHovered: Bool = false
    
    // MARK: - Dimensions tuned for Apple Dynamic Island aesthetics
    
    /// Dynamic collapsed width adapting to whether media is playing and screen notch geometry
    public var collapsedWidth: CGFloat {
        let hasMedia = MediaManager.shared.currentItem != nil
        if let screen = targetScreen, screen.hasNotch {
            return hasMedia ? max(screen.notchWidth + 64, 256) : max(screen.notchWidth + 24, 210)
        }
        return hasMedia ? 240 : 180
    }
    
    /// Height of the collapsed pill (matches MacBook notch height)
    public var collapsedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return max(screen.notchHeight + 2, 34)
        }
        return 34
    }
    
    /// Generous width for expanded card so titles and controls breathe comfortably
    public let expandedWidth: CGFloat = 416
    
    /// Height for expanded card giving balanced optical rhythm between artwork, slider & controls
    public let expandedHeight: CGFloat = 152
    
    /// Target screen where Mac Island is currently docked
    public var targetScreen: NSScreen? {
        NSScreen.main ?? NSScreen.screens.first
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
