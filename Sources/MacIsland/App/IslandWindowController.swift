import AppKit
import SwiftUI
import Combine

// MARK: - IslandWindowController
// Manages the lifecycle, positioning, screen adaptation, and frame animations of IslandPanel.
@MainActor
public final class IslandWindowController: NSObject, ObservableObject {
    public static let shared = IslandWindowController()
    
    public private(set) var panel: IslandPanel?
    private var windowManager = WindowManager.shared
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
            mediaManager: MediaManager.shared
        )
        let hostingView = IslandHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: initialFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        
        newPanel.contentView = hostingView
        newPanel.setFrame(initialFrame, display: true)
        self.panel = newPanel
        
        // Listen to island state changes (collapsed <-> expanded)
        windowManager.onStateChanged = { [weak self] newState in
            self?.updateWindowFrame(for: newState)
        }
        
        // Listen for screen resolution and display configuration changes
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
            context.duration = 0.28
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
