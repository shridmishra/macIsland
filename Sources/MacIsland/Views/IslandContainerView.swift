import SwiftUI

// MARK: - IslandContainerView
// The root SwiftUI view of the Island.
// Renders authentic transparent liquid glass surfaces and manages
// the spring morphing between collapsed and expanded states.
@MainActor
public struct IslandContainerView: View {
    @ObservedObject var windowManager: WindowManager
    @ObservedObject var mediaManager: MediaManager
    
    @MainActor
    public init() {
        self.windowManager = WindowManager.shared
        self.mediaManager = MediaManager.shared
    }
    
    @MainActor
    public init(windowManager: WindowManager, mediaManager: MediaManager) {
        self.windowManager = windowManager
        self.mediaManager = mediaManager
    }
    
    public var body: some View {
        let isExpanded = windowManager.islandState.isExpanded
        
        ZStack {
            if isExpanded {
                ExpandedIslandView(mediaManager: mediaManager)
                    .transparentGlass(cornerRadius: 18)
                    .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                CollapsedIslandView(
                    item: mediaManager.currentItem,
                    isPlaying: mediaManager.playbackState.isPlaying
                )
                .transition(.opacity)
            }
        }
        .frame(
            width: isExpanded ? windowManager.expandedWidth : windowManager.collapsedWidth,
            height: isExpanded ? windowManager.expandedHeight : windowManager.collapsedHeight
        )
        .onHover { hovering in
            windowManager.setHovered(hovering)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: windowManager.islandState)
    }
}
