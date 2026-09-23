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
        
        let isVisible = isExpanded || windowManager.hasActiveWings
        let flareRadius: CGFloat = isExpanded ? 10 : 6
        let bottomRadius: CGFloat = isExpanded ? 20 : 10
        let islandShape = NotchedIslandShape(flareRadius: flareRadius, bottomRadius: bottomRadius)
        
        // Pinned Notch Alignment:
        // When collapsed on a notched display, the leading edge of the left wing is mathematically pinned
        // immediately to the left of the physical camera notch (screenWidth - notchWidth)/2 - leftWingWidth.
        // As lyrics expand or contract the right wing, leadingX remains 100% stationary so the left wing
        // and artwork NEVER move, flip, or translate.
        let leadingX = windowManager.currentIslandLeadingX
        
        ZStack(alignment: .topLeading) {
            // Background black shape container (pure pitch black, seamless cutout blend, outward top curves)
            ZStack(alignment: .topLeading) {
                if isExpanded {
                    ExpandedIslandView(
                        mediaManager: mediaManager,
                        namespace: islandNamespace
                    )
                    .frame(width: width, height: height)
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
                    .frame(width: width, height: height, alignment: .leading)
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .opacity
                        )
                    )
                }
            }
            .frame(width: width, height: height, alignment: .topLeading)
            .background(
                islandShape
                    .fill(Color.black)
            )
            .clipShape(islandShape)
            .contentShape(islandShape)
            .offset(x: leadingX)
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(IslandAnimation.notchSpring, value: isExpanded)
        .animation(IslandAnimation.notchSpring, value: width)
        .animation(IslandAnimation.notchSpring, value: height)
        .animation(IslandAnimation.notchSpring, value: leadingX)
        .animation(IslandAnimation.notchSpring, value: isVisible)
    }
}
