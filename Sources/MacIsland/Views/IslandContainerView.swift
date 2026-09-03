import SwiftUI

// MARK: - IslandContainerView
// The root SwiftUI view of the Island.
// Renders the pure pitch-black Dynamic Island container with outward top curves:
// - Flat top touching the screen edge.
// - Smooth outward curves (fillets/flares) at top-left and top-right flaring into the bezel.
// - Continuous rounded corners on the bottom.
// - Zero borders, zero shadows.
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
        let flareRadius: CGFloat = isExpanded ? 10 : 8
        let bottomRadius: CGFloat = isExpanded ? 20 : 10
        let islandShape = NotchedIslandShape(flareRadius: flareRadius, bottomRadius: bottomRadius)
        
        ZStack {
            if isExpanded {
                ExpandedIslandView(mediaManager: mediaManager)
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
        // Pure solid pitch-black background with outward top curves and rounded bottom corners
        .background(
            islandShape
                .fill(Color.black)
        )
        .clipShape(islandShape)
        .onHover { hovering in
            windowManager.setHovered(hovering)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: windowManager.islandState)
    }
}
