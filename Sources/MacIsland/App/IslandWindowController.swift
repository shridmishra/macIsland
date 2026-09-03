import AppKit
import SwiftUI
import Combine

// MARK: - IslandWindowController
// Manages the lifecycle, positioning, and screen adaptation of IslandPanel.
//
// Fluid Architecture:
// The window maintains a stable transparent canvas pinned to the top of the display.
// All expansion, collapse, and element morphing animations execute 100% natively
// in SwiftUI with GPU-accelerated spring physics, eliminating WindowServer resize lag,
// clipping, and visual frame cuts.
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
        
        // The panel is anchored at the top with a permanent transparent canvas
        // sized to the maximum expanded bounds.
        let targetFrame = windowManager.windowFrame(for: .expanded, on: screen)
        let newPanel = IslandPanel(contentRect: targetFrame)
        
        // Host the SwiftUI IslandContainerView inside AppKit
        let rootView = IslandContainerView(
            windowManager: windowManager,
            mediaManager: mediaManager
        )
        let hostingView = IslandHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: targetFrame.size)
        hostingView.autoresizingMask = [.width, .height]
        
        newPanel.contentView = hostingView
        newPanel.setFrame(targetFrame, display: true)
        self.panel = newPanel
        
        // Listen for screen resolution and display configuration changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.recenterOnScreen()
            }
            .store(in: &cancellables)
    }
    
    private func recenterOnScreen() {
        guard let panel = panel, let screen = windowManager.targetScreen else { return }
        let targetFrame = windowManager.windowFrame(for: .expanded, on: screen)
        panel.setFrame(targetFrame, display: true)
    }
}
