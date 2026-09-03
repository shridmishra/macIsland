import AppKit
import SwiftUI
import Combine

// MARK: - IslandWindowController
// Manages the lifecycle, positioning, screen adaptation, and frame animations of IslandPanel.
// Dynamically resizes and centers the window when:
// 1. Media starts/stops playing (wings sprout from the notch)
// 2. The user hovers/collapses the island (smooth spring expansion/collapse)
// 3. Display geometry changes (external monitors connected/disconnected)
@MainActor
public final class IslandWindowController: NSObject, ObservableObject {
    public static let shared = IslandWindowController()
    
    public private(set) var panel: IslandPanel?
    private var windowManager = WindowManager.shared
    private var mediaManager = MediaManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    override private init() {
        super.init()
    }
    
    public func showIsland() {
        if panel == nil {
            setupPanel()
        }
        panel?.orderFrontRegardless()
    }
    
    public func hideIsland() {
        panel?.orderOut(nil)
    }
    
    private func setupPanel() {
        guard let screen = windowManager.targetScreen else { return }
        
        let initialFrame = windowManager.windowFrame(for: windowManager.islandState, on: screen)
        let newPanel = IslandPanel(contentRect: initialFrame)
        
        // Host the SwiftUI IslandContainerView inside AppKit
        let rootView = IslandContainerView(
            windowManager: windowManager,
            mediaManager: mediaManager
        )
        let hostingView = IslandHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: initialFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        
        newPanel.contentView = hostingView
        newPanel.setFrame(initialFrame, display: true)
        self.panel = newPanel
        
        // 1. Listen to island state changes (collapsed <-> expanded)
        windowManager.onStateChanged = { [weak self] newState in
            self?.updateWindowFrame(for: newState)
        }
        
        // 2. Listen to media changes (dynamically adapt collapsed wing width)
        mediaManager.$currentItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.windowManager.islandState == .collapsed else { return }
                self.updateWindowFrame(for: .collapsed)
            }
            .store(in: &cancellables)
        
        // 3. Listen for screen resolution and display configuration changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.recenterOnScreen()
            }
            .store(in: &cancellables)
    }
    
    private func updateWindowFrame(for state: IslandState) {
        guard let panel = panel, let screen = windowManager.targetScreen else { return }
        let targetFrame = windowManager.windowFrame(for: state, on: screen)
        
        // Use AppKit animation context for smooth window frame transition
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.32
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(targetFrame, display: true)
        }
    }
    
    private func recenterOnScreen() {
        guard let panel = panel, let screen = windowManager.targetScreen else { return }
        let targetFrame = windowManager.windowFrame(for: windowManager.islandState, on: screen)
        panel.setFrame(targetFrame, display: true)
    }
}
