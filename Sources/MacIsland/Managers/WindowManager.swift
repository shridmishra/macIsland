import Foundation
import AppKit
import Combine
import SwiftUI

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
    @Published public private(set) var isBriefMediaGlanceActive: Bool = false
    @Published public var currentPage: IslandPage = .media
    @Published public var isAudioRoutePickerActive: Bool = false
    
    private var mediaGlanceTimer: Timer?
    private var lastObservedTrackTitle: String = ""
    private var lastObservedPlaybackState: PlaybackState = .stopped
    
    /// Returns true when frontmost application or active space is in full screen mode
    public var isFullScreen: Bool {
        FullScreenDetector.shared.isFullScreen
    }
    
    /// Returns true if song lyrics are currently active and being displayed (or loading) in the Island.
    public var isLyricsActiveAndOn: Bool {
        guard LyricsManager.shared.isLyricsEnabled else { return false }
        guard let item = MediaManager.shared.currentItem, !item.service.isVideoService else { return false }
        guard MediaManager.shared.playbackState.isPlaying else { return false }
        return LyricsManager.shared.isLoading || LyricsManager.shared.hasLyrics || LyricsManager.shared.currentLine != nil || LyricsManager.shared.showNoLyricsNotice
    }
    
    /// Determines whether the circular timer countdown should be visible in collapsed mode.
    /// When enabled by user, stays visible continuously for the full duration of the timer, even in fullscreen!
    public var shouldShowTimerInCollapsed: Bool {
        PomodoroManager.shared.isTimerInNotchEnabled && PomodoroManager.shared.isTimerActive
    }
    
    /// Determines whether media player wings (artwork, waveform/lyrics) should be visible in collapsed mode.
    /// - If lyrics are on, NEVER hide them (even in full screen or any screen).
    /// - If just music/video is playing without lyrics in fullscreen, show for 5 seconds on track change, then hide.
    /// - On normal screen, always show while playing.
    public var shouldShowMediaInCollapsed: Bool {
        let isMediaActive = MediaManager.shared.currentItem != nil && MediaManager.shared.playbackState != .stopped
        guard isMediaActive else { return false }
        if isFullScreen {
            if isLyricsActiveAndOn || isHovered || isBriefMediaGlanceActive {
                return true
            }
            return false
        }
        return true
    }
    
    /// True when either a system HUD (volume, brightness, battery), active media wings, or timer ring should be displayed.
    public var hasActiveWings: Bool {
        SystemHUDManager.shared.isHUDActive || shouldShowMediaInCollapsed || shouldShowTimerInCollapsed
    }
    
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
    
    /// Current left wing width based on whether a HUD (e.g. Battery) or media artwork is active
    public var currentLeftWingWidth: CGFloat {
        if SystemHUDManager.shared.isHUDActive {
            if SystemHUDManager.shared.hudType == .battery {
                // Dynamically size left wing to comfortably fit battery percentage (e.g., "80%", "100%") + battery SF Symbol bolt icon
                let text = "\(SystemHUDManager.shared.batteryPercentage)%"
                let nsFont = NSFont.systemFont(ofSize: 11.0, weight: .bold)
                let textWidth = ceil((text as NSString).size(withAttributes: [.font: nsFont]).width)
                // Left wing: [6pt flare] + [11pt gap] + [textWidth] + [4pt spacing] + [battery icon ~22pt] + [11pt notch clearance]
                return max(78.0, textWidth + 52.0)
            }
            return 44.0
        }
        if shouldShowTimerInCollapsed {
            let text = PomodoroManager.shared.formattedTime
            let nsFont = NSFont.monospacedDigitSystemFont(ofSize: 11.5, weight: .semibold)
            let textWidth = ceil((text as NSString).size(withAttributes: [.font: nsFont]).width)
            // Left wing: [6pt flare] + [8pt leading gap] + [textWidth] + [8pt notch clearance]
            return max(54.0, textWidth + 22.0)
        }
        guard shouldShowMediaInCollapsed else {
            return 0.0
        }
        return 44.0
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
        guard shouldShowMediaInCollapsed else {
            return 0.0
        }
        guard LyricsManager.shared.isLyricsEnabled,
              MediaManager.shared.playbackState.isPlaying else {
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
    
    /// Pinned leading origin for the island within the full-width window canvas.
    /// When collapsed on a notched screen, mathematically pinned to the left of the physical notch:
    /// screenCenterX - (notchWidth / 2) - currentLeftWingWidth.
    /// This ensures that changes in the right wing (e.g. lyrics length) NEVER cause the left wing
    /// or album artwork to drift, oscillate, or translate.
    public var currentIslandLeadingX: CGFloat {
        let screenWidth = maxCanvasWidth
        if islandState.isExpanded {
            return (screenWidth - expandedWidth) / 2.0
        } else if hasNotch && hasActiveWings {
            return (screenWidth - notchWidth) / 2.0 - currentLeftWingWidth
        } else {
            return (screenWidth - collapsedWidth) / 2.0
        }
    }
    
    /// Dynamic collapsed width:
    /// Left wing (currentLeftWingWidth) + Notch (notchWidth) + Right wing (currentRightWingWidth)
    public var collapsedWidth: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            if !hasActiveWings {
                // When idle or hidden in fullscreen, the collapsed pill matches the hardware notch width exactly!
                // Zero wings extend outward beyond the notch.
                return screen.notchWidth
            }
            return screen.notchWidth + currentLeftWingWidth + currentRightWingWidth
        }
        if SystemHUDManager.shared.isHUDActive {
            if SystemHUDManager.shared.hudType == .battery {
                return currentLeftWingWidth + currentRightWingWidth + 24.0
            }
            return 170.0
        }
        if !shouldShowMediaInCollapsed {
            if shouldShowTimerInCollapsed {
                return 64.0
            }
            return 0.0
        }
        let isLyricsActive = LyricsManager.shared.isLyricsEnabled && MediaManager.shared.playbackState.isPlaying && (LyricsManager.shared.hasLyrics || LyricsManager.shared.isLoading)
        let baseWidth: CGFloat = shouldShowTimerInCollapsed ? 210.0 : 180.0
        return isLyricsActive ? max(baseWidth, currentRightWingWidth + 30) : baseWidth
    }
    
    /// Height of the collapsed pill:
    /// Precision-matched to the physical hardware cutout height (28pt) so it merges flush.
    public var collapsedHeight: CGFloat {
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight
        }
        return 28.0
    }
    
    /// Expanded width: 336pt in timer state, 374pt in media state
    public var expandedWidth: CGFloat {
        if islandState.isExpanded {
            switch currentPage {
            case .timer:
                return 336.0
            case .media:
                return 374.0
            }
        }
        let isNothing = MediaManager.shared.currentItem == nil
        return isNothing ? 336.0 : 374.0
    }
    
    /// Expanded height: precision-calibrated for optimal breathing room
    public var expandedHeight: CGFloat {
        if isAudioRoutePickerActive {
            let hasModes = AudioRouteManager.shared.hasAirPodsActive
            let devCount = AudioRouteManager.shared.availableDevices.count
            let btCount = min(AudioRouteManager.shared.pairedBluetoothDevices.count, 2)
            
            let effectiveDevCount = max(1, devCount)
            // Top padding (6.0) + Header bar (22.0) + Spacing (16.0)
            var contentHeight: CGFloat = 6.0 + 22.0 + 16.0
            // Output device rows (each ~40pt + 2pt inter-row spacing)
            contentHeight += CGFloat(effectiveDevCount) * 40.0 + CGFloat(max(0, effectiveDevCount - 1)) * 2.0
            
            // AirPods noise control section (16pt outer spacing + 56pt bar)
            if hasModes {
                contentHeight += 16.0 + 56.0
            }
            
            // Bluetooth audio devices section
            if btCount > 0 {
                // 16pt outer spacing + 16pt header + 6pt spacing + rows (each ~44pt + 2pt inter-row spacing)
                contentHeight += 16.0 + 22.0 + CGFloat(btCount) * 44.0 + CGFloat(max(0, btCount - 1)) * 2.0
            }
            
            // Bottom padding & corner radius breathing room (matches currentBottomPadding 26.0 + optical clearance)
            contentHeight += 30.0
            
            let clampedContentHeight = min(380.0, max(140.0, contentHeight))
            
            if let screen = targetScreen, screen.hasNotch {
                return screen.notchHeight + clampedContentHeight
            }
            return clampedContentHeight + 16.0
        }
        let isTimer = (currentPage == .timer)
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight + (isTimer ? 126.0 : 124.0)
        }
        return isTimer ? 144.0 : 150.0
    }
    
    /// Top padding: content sits cleanly below the camera notch without excessive empty space
    public var expandedTopPadding: CGFloat {
        if isAudioRoutePickerActive {
            if let screen = targetScreen, screen.hasNotch {
                return screen.notchHeight + 6.0
            }
            return 12.0
        }
        let isTimer = (currentPage == .timer)
        if let screen = targetScreen, screen.hasNotch {
            return screen.notchHeight + (isTimer ? 4.0 : 6.0)
        }
        return isTimer ? 8.0 : 12.0
    }
    
    private var expandDebounceTimer: Timer?
    private var collapseDebounceTimer: Timer?
    public var onStateChanged: ((IslandState) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        FullScreenDetector.shared.$isFullScreen
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFS in
                guard let self = self else { return }
                if isFS && MediaManager.shared.playbackState.isPlaying && !self.isLyricsActiveAndOn {
                    self.triggerMediaGlance()
                }
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        SystemHUDManager.shared.$isHUDActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        SystemHUDManager.shared.$hudType
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        SystemHUDManager.shared.$batteryPercentage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        MediaManager.shared.$currentItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                guard let self = self else { return }
                let cleanNew = (item?.displayTitle ?? item?.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let cleanLast = self.lastObservedTrackTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                let isTrackChange: Bool
                if cleanNew.isEmpty {
                    isTrackChange = false
                } else if cleanLast.isEmpty {
                    isTrackChange = true
                    self.lastObservedTrackTitle = cleanNew
                } else if cleanNew == cleanLast || cleanNew.contains(cleanLast) || cleanLast.contains(cleanNew) {
                    isTrackChange = false
                } else {
                    isTrackChange = true
                    self.lastObservedTrackTitle = cleanNew
                }
                
                // When track changes and is actively playing in full screen without lyrics, trigger brief 5.0s glance
                if isTrackChange && (item?.isPlaying ?? false) && self.isFullScreen && !self.isLyricsActiveAndOn {
                    self.triggerMediaGlance()
                }
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        MediaManager.shared.$isTransitioning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        MediaManager.shared.$playbackState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                let wasPlaying = self.lastObservedPlaybackState.isPlaying
                let isNowPlaying = state.isPlaying
                self.lastObservedPlaybackState = state
                
                // If playback resumes / starts in full screen without lyrics, trigger brief 5.0s glance
                if !wasPlaying && isNowPlaying && self.isFullScreen && !self.isLyricsActiveAndOn {
                    self.triggerMediaGlance()
                }
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        // Observe all lyrics state changes so views update immediately when lyrics arrive, load, or toggle
        LyricsManager.shared.$isLyricsEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        LyricsManager.shared.$hasLyrics
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
            
        LyricsManager.shared.$currentLine
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
            
        PomodoroManager.shared.$timerState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        PomodoroManager.shared.$isTimerInNotchEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        AudioRouteManager.shared.$activeRouteIcon
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        AudioRouteManager.shared.$availableDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        AudioRouteManager.shared.$pairedBluetoothDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// Triggers a brief 5-second glance for media when a track changes or starts playing in fullscreen without lyrics.
    public func triggerMediaGlance(duration: TimeInterval = 5.0) {
        guard isFullScreen else { return }
        // If lyrics are on, no need to schedule auto-hide since lyrics remain continuously visible
        if isLyricsActiveAndOn { return }
        
        mediaGlanceTimer?.invalidate()
        mediaGlanceTimer = nil
        
        withAnimation(IslandAnimation.notchSpring) {
            self.isBriefMediaGlanceActive = true
            self.objectWillChange.send()
        }
        
        mediaGlanceTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                withAnimation(IslandAnimation.notchSpring) {
                    self.isBriefMediaGlanceActive = false
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    public func setHovered(_ hovered: Bool) {
        isHovered = hovered
        
        if hovered {
            collapseDebounceTimer?.invalidate()
            collapseDebounceTimer = nil
            
            if islandState != .expanded {
                // To prevent accidental expansions when fast-moving the cursor towards tabs/buttons
                // directly below the notch, require a brief intentional dwell time (140ms)
                // before expanding the island.
                if expandDebounceTimer == nil {
                    expandDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.14, repeats: false) { [weak self] _ in
                        Task { @MainActor [weak self] in
                            guard let self = self else { return }
                            self.expandDebounceTimer = nil
                            if self.isHovered && self.islandState != .expanded {
                                self.expand()
                            }
                        }
                    }
                }
            }
        } else {
            // Cursor exited the island area
            // Immediately cancel any pending expansion timer so fast swipes/overshoots never trigger expansion!
            expandDebounceTimer?.invalidate()
            expandDebounceTimer = nil
            
            if islandState == .expanded {
                // 450ms debounce timer prevents accidental collapse when moving cursor between controls
                collapseDebounceTimer?.invalidate()
                collapseDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self = self, !self.isHovered else { return }
                        self.collapse()
                    }
                }
            }
        }
    }
    
    public func expand() {
        expandDebounceTimer?.invalidate()
        expandDebounceTimer = nil
        
        // When timer is active, default directly to Timer; when playing or idle, default to Media
        if PomodoroManager.shared.isTimerActive {
            currentPage = .timer
        } else {
            currentPage = .media
        }
        
        islandState = .expanded
        onStateChanged?(.expanded)
    }
    
    public func collapse() {
        expandDebounceTimer?.invalidate()
        expandDebounceTimer = nil
        collapseDebounceTimer?.invalidate()
        collapseDebounceTimer = nil
        isAudioRoutePickerActive = false
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
    
    // MARK: - Audio Route Picker Navigation
    
    public func openAudioRoutePicker() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        AudioRouteManager.shared.updateRoute()
        AudioRouteManager.shared.scanBluetoothDevices()
        if islandState != .expanded {
            expand()
        }
        withAnimation(IslandAnimation.notchSpring) {
            self.isAudioRoutePickerActive = true
            self.objectWillChange.send()
        }
    }
    
    public func closeAudioRoutePicker() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        withAnimation(IslandAnimation.notchSpring) {
            self.isAudioRoutePickerActive = false
            self.objectWillChange.send()
        }
    }
    
    public func toggleAudioRoutePicker() {
        if isAudioRoutePickerActive {
            closeAudioRoutePicker()
        } else {
            openAudioRoutePicker()
        }
    }
    
    // MARK: - Multi-Page Navigation
    
    public func nextPage() {
        guard currentPage.canGoNext, let next = currentPage.next else { return }
        setPage(next)
    }
    
    public func previousPage() {
        guard currentPage.canGoPrevious, let prev = currentPage.previous else { return }
        setPage(prev)
    }
    
    public func setPage(_ page: IslandPage) {
        guard currentPage != page else { return }
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        withAnimation(IslandAnimation.notchSpring) {
            self.currentPage = page
            self.objectWillChange.send()
        }
    }
    
    /// Calculates the origin and dimensions of the panel anchored to the top of the display
    public func windowFrame(for state: IslandState, on screen: NSScreen) -> NSRect {
        let screenFrame = screen.frame
        let width = screenFrame.width
        let height = max(expandedHeight, 280.0)
        
        let x = screenFrame.origin.x
        let y = screenFrame.origin.y + screenFrame.height - height
        
        return NSRect(x: x, y: y, width: width, height: height)
    }
}
