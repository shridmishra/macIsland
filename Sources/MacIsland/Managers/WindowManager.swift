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
    
    /// Transparent canvas width matching display width to allow lyrics to expand freely without clipping
    public var maxCanvasWidth: CGFloat {
        targetScreen?.frame.width ?? 1440.0
    }
    
    /// Current right wing width based on whether lyrics are enabled, loading, instrumental, or singing
    public var currentRightWingWidth: CGFloat {
        if SystemHUDManager.shared.isHUDActive {
            if SystemHUDManager.shared.hudType == .battery {
                // Dynamically size right wing to fit battery text (e.g., "Charging", "Charged", "Disconnected")
                let text = SystemHUDManager.shared.batteryText
                let nsFont = NSFont.systemFont(ofSize: 11.5, weight: .semibold)
                let textWidth = ceil((text as NSString).size(withAttributes: [.font: nsFont]).width)
                return max(70.0, textWidth + 24.0)
            }
            return 84.0
        }
        guard LyricsManager.shared.isLyricsEnabled else {
            return 44.0
        }
        
        // When lyrics are loading, ensure generous space so "Loading..." never gets clipped or broken
        if LyricsManager.shared.isLoading {
            return 110.0
        }
        
        // When track has no lyrics and 5-second "No lyrics" notice is active:
        if LyricsManager.shared.showNoLyricsNotice {
            return 86.0
        }
        
        // When lyrics are actively being sung:
        if let line = LyricsManager.shared.currentLine, !line.text.isEmpty {
            let text = line.text
            let nsFont = NSFont.systemFont(ofSize: 12.5, weight: .semibold)
            let textWidth = ceil((text as NSString).size(withAttributes: [.font: nsFont]).width)
            // Symmetrical, comfortable padding: [14pt leading clearance] + [textWidth] + [14pt trailing clearance] + [12pt corner & flare curve]
            let neededWidth = textWidth + 40.0
            
            // Allow the island to expand as much as it wants, bounded only by the physical display bounds
            let screenWidth = targetScreen?.frame.width ?? 1440.0
            let currentNotchW = targetScreen?.notchWidth ?? notchWidth
            let maxAvailable = max(200.0, (screenWidth - currentNotchW) / 2.0 - 20.0)
            
            return max(44.0, min(maxAvailable, neededWidth))
        }
        
        // When instrumental, intro, or after 5s when pulse is active:
        return 44.0
    }
    
    /// Dynamic collapsed width:
    /// Left wing (44pt) + Notch (156pt) + Right wing (currentRightWingWidth)
    public var collapsedWidth: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchWidth + 44 + currentRightWingWidth
        }
        if SystemHUDManager.shared.isHUDActive {
            if SystemHUDManager.shared.hudType == .battery {
                return currentRightWingWidth + 60.0
            }
            return 170.0
        }
        let isLyricsActive = LyricsManager.shared.isLyricsEnabled && (LyricsManager.shared.hasLyrics || LyricsManager.shared.isLoading)
        return isLyricsActive ? max(180, currentRightWingWidth + 30) : 180
    }
    
    /// Height of the collapsed pill:
    /// Precision-matched to the physical hardware cutout height (28pt) so it merges flush.
    public var collapsedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight
        }
        return 28.0
    }
    
    /// Expanded width: calibrated for optimal breathing room in both media and productivity states
    public var expandedWidth: CGFloat {
        if MediaManager.shared.currentItem == nil {
            return 450.0
        }
        return 374.0
    }
    
    /// Expanded height: calibrated with reduced top padding and increased bottom clearance
    public var expandedHeight: CGFloat {
        let isNothingState = MediaManager.shared.currentItem == nil
        if let screen = targetScreen, screen.hasNotch {
            let baseHeight: CGFloat = isNothingState ? 178.0 : 124.0
            return screen.notchHeight + baseHeight
        }
        return isNothingState ? 204.0 : 150.0
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
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        SystemHUDManager.shared.$isHUDActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        LyricsManager.shared.$currentLine
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        LyricsManager.shared.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        LyricsManager.shared.$showNoLyricsNotice
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        LyricsManager.shared.$isLyricsEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        MediaManager.shared.$currentItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        PomodoroManager.shared.$timerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
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
        let width = screenFrame.width
        let height = max(expandedHeight, 230.0)
        
        let x = screenFrame.origin.x
        let y = screenFrame.origin.y + screenFrame.height - height
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
