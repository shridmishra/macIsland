import SwiftUI

// MARK: - IslandContainerView
// The root SwiftUI view of the Island.
// Renders the pure pitch-black Dynamic Island container with outward top curves.
// All size, position, shape, and element animations occur fluidly on the GPU:
// - MatchedGeometryEffect for seamless element morphing (artwork and waveform)
// - Synchronized spring physics between collapsed wings and the expanded card
// - Zero window-server clipping or frame cuts
@MainActor
public struct IslandContainerView: View {
    @ObservedObject var windowManager: WindowManager
    @ObservedObject var mediaManager: MediaManager
    
    @Namespace private var islandNamespace
    
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
        let width = isExpanded ? windowManager.expandedWidth : windowManager.collapsedWidth
        let height = isExpanded ? windowManager.expandedHeight : windowManager.collapsedHeight
        let flareRadius: CGFloat = isExpanded ? 10 : 6
        let bottomRadius: CGFloat = isExpanded ? 22 : 10
        let islandShape = NotchedIslandShape(flareRadius: flareRadius, bottomRadius: bottomRadius)
        
        ZStack(alignment: .top) {
            // Background black shape container
            ZStack(alignment: .top) {
                if isExpanded {
                    ExpandedIslandView(
                        mediaManager: mediaManager,
                        namespace: islandNamespace
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .top)),
                            removal: .opacity
                        )
                    )
                } else {
                    CollapsedIslandView(
                        item: mediaManager.currentItem,
                        isPlaying: mediaManager.playbackState.isPlaying,
                        namespace: islandNamespace
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        )
                    )
                }
            }
            .frame(width: width, height: height)
            .background(
                islandShape
                    .fill(Color.black)
            )
            .clipShape(islandShape)
            .contentShape(islandShape)
            .onHover { hovering in
                windowManager.setHovered(hovering)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.38, dampingFraction: 0.80), value: isExpanded)
    }
}
