import SwiftUI

// MARK: - IslandContainerView
// The root SwiftUI view of the Island.
// Renders the pure pitch-black Dynamic Island container merging flush with the display bezel.
// Features signature outward curves (concave flares) at the top corners in both collapsed and expanded states,
// with smooth rounded bottom corners (zero borders, zero drop shadows).
// All size, position, shape, and element animations occur fluidly on the GPU:
// - MatchedGeometryEffect for seamless element morphing (artwork and waveform)
// - Synchronized spring physics between collapsed wings and the expanded card
// - Zero window-server clipping or frame cuts
@MainActor
public struct IslandContainerView: View {
    @ObservedObject var windowManager: WindowManager
    @ObservedObject var mediaManager: MediaManager
    @ObservedObject private var lyricsManager = LyricsManager.shared
    
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
        let bottomRadius: CGFloat = isExpanded ? 20 : 10
        let islandShape = NotchedIslandShape(flareRadius: flareRadius, bottomRadius: bottomRadius)
        
        // Pinned Notch & Artwork Alignment:
        // When collapsed on a notched display, the right wing expands to fit the full lyrics line.
        // Offsetting by +(rightWingWidth - 44)/2 mathematically guarantees that the left wing (artwork)
        // and the notch cutout remain 100% stationary and pinned flush against the physical camera cutout!
        let xOffset: CGFloat = (windowManager.hasNotch && !isExpanded) ? (windowManager.currentRightWingWidth - 44.0) / 2.0 : 0.0
        
        ZStack(alignment: .top) {
            // Background black shape container (pure pitch black, seamless cutout blend, outward top curves)
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
            .offset(x: xOffset)
            .onHover { hovering in
                windowManager.setHovered(hovering)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(IslandAnimation.notchSpring, value: isExpanded)
        .animation(IslandAnimation.notchSpring, value: width)
        .animation(IslandAnimation.notchSpring, value: height)
        .animation(IslandAnimation.notchSpring, value: xOffset)
    }
}
